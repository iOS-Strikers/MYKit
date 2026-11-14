#import "NSObject+SafeKVO.h"
#import "NSObject+Swizzle.h"
#import "MYSafeKitRecord.h"

@interface MYKVORegistration : NSObject
@property (nonatomic, weak) NSObject *observed;
@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic) void *context;
@property (nonatomic) BOOL active;
@end
@interface MYKVOState : NSObject
@property (nonatomic, strong) NSMutableArray<MYKVORegistration *> *registrations;
@property (nonatomic, strong) NSHashTable<MYKVORegistration *> *observing;
@end
@implementation MYKVOState
- (instancetype)init {
    if ((self = [super init])) { _registrations = [NSMutableArray new]; _observing = [NSHashTable weakObjectsHashTable]; }
    return self;
}
@end

static char stateKey;
static NSRecursiveLock *stateLock;
static IMP originalAdd, originalRemove, originalRemoveContext, originalDealloc;
// Foundation's context removal may dispatch through its contextless overload.
typedef struct MYNativeRemovalFrame {
    __unsafe_unretained id object;
    __unsafe_unretained id observer;
    __unsafe_unretained NSString *keyPath;
    struct MYNativeRemovalFrame *previous;
} MYNativeRemovalFrame;
static _Thread_local MYNativeRemovalFrame *nativeRemoval;
static BOOL MYInternalRemoval(id object, id observer, NSString *keyPath) {
    if (object_getClass(observer) == [MYKVORegistration class]) return YES;
    return nativeRemoval && nativeRemoval->object == object && nativeRemoval->observer == observer && [nativeRemoval->keyPath isEqualToString:keyPath];
}
static MYKVOState *MYState(__unsafe_unretained id object, BOOL create) {
    MYKVOState *state = objc_getAssociatedObject(object, &stateKey);
    if (!state && create) { state = [MYKVOState new]; objc_setAssociatedObject(object, &stateKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    return state;
}
static void MYNativeRemove(__unsafe_unretained id observed, MYKVORegistration *registration) {
    ((void (*)(id, SEL, id, NSString *, void *))originalRemoveContext)(observed, @selector(removeObserver:forKeyPath:context:), registration, registration.keyPath, (__bridge void *)registration);
}
static void MYRemoveRegistration(__unsafe_unretained id observed, MYKVORegistration *registration) {
    if (!registration.active) return;
    MYNativeRemove(observed, registration);
    registration.active = NO;
    [MYState(observed, NO).registrations removeObjectIdenticalTo:registration];
    NSObject *observer = registration.observer;
    if (observer) [MYState(observer, NO).observing removeObject:registration];
}
@implementation MYKVORegistration
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [stateLock lock];
    NSObject *observer = self.active ? self.observer : nil;
    void *userContext = self.context;
    [stateLock unlock];
    // Client exceptions deliberately propagate, exactly as with native KVO.
    [observer observeValueForKeyPath:keyPath ofObject:object change:change context:userContext];
}
@end

static void MYKVODealloc(__unsafe_unretained id object, SEL selector) {
    // No state is allocated and no client reporter is invoked during destruction.
    MYKVOState *state = objc_getAssociatedObject(object, &stateKey);
    if (state) {
        [stateLock lock];
        @try {
            for (MYKVORegistration *registration in [state.registrations copy]) {
                MYRemoveRegistration(object, registration);
            }
            for (MYKVORegistration *registration in state.observing.allObjects) {
                NSObject *observed = registration.observed;
                if (observed) MYRemoveRegistration(observed, registration);
            }
        } @finally {
            [stateLock unlock];
            ((void (*)(__unsafe_unretained id, SEL))originalDealloc)(object, selector);
        }
    } else {
        ((void (*)(__unsafe_unretained id, SEL))originalDealloc)(object, selector);
    }
}
static void MYKVOReport(NSString *reason) {
    [MYSafeKitRecord recordFatalWithReason:reason errorType:MYSafeKitShieldTypeKVO];
}
static void MYAdd(id object, NSObject *observer, NSString *keyPath, NSKeyValueObservingOptions options, void *context) {
    if (!observer || !keyPath.length) { MYKVOReport(@"KVO requires an observer and nonempty keyPath"); return; }
    // Native KVO delivers Initial BEFORE installing the new registration. If the
    // callback throws, there is no new observation to roll back. Reentrant remove
    // may only remove an earlier registration, never this not-yet-installed one.
    if (options & NSKeyValueObservingOptionInitial) {
        NSMutableDictionary *change = [@{NSKeyValueChangeKindKey:@(NSKeyValueChangeSetting)} mutableCopy];
        if (options & NSKeyValueObservingOptionNew) change[NSKeyValueChangeNewKey] = [object valueForKeyPath:keyPath] ?: [NSNull null];
        [observer observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    MYKVORegistration *registration = [MYKVORegistration new];
    registration.observer = observer; registration.observed = object; registration.keyPath = keyPath; registration.context = context;
    [stateLock lock];
    @try {
        registration.active = YES;
        [MYState(object, YES).registrations addObject:registration];
        [MYState(observer, YES).observing addObject:registration];
        @try {
            // Initial was already delivered outside the state lock, as in native KVO.
            ((void (*)(id, SEL, id, NSString *, NSKeyValueObservingOptions, void *))originalAdd)(object, @selector(addObserver:forKeyPath:options:context:), registration, keyPath, options & ~NSKeyValueObservingOptionInitial, (__bridge void *)registration);
        } @catch (NSException *exception) {
            registration.active = NO;
            [MYState(object, NO).registrations removeObjectIdenticalTo:registration];
            [MYState(observer, NO).observing removeObject:registration];
            @throw;
        }
    } @finally { [stateLock unlock]; }

}
static void MYRemove(id object, NSObject *observer, NSString *keyPath, void *context, BOOL matchContext) {
    if (!observer || !keyPath.length) { MYKVOReport(@"KVO removal requires an observer and nonempty keyPath"); return; }
    BOOL found = NO;
    [stateLock lock];
    @try {
        for (MYKVORegistration *registration in [MYState(object, NO).registrations reverseObjectEnumerator]) {
            if (registration.observer == observer && [registration.keyPath isEqualToString:keyPath] && (!matchContext || registration.context == context)) {
                MYRemoveRegistration(object, registration); found = YES; break;
            }
        }
    } @finally { [stateLock unlock]; }
    if (!found) {
        // Registrations made before activation are owned by Foundation, not our ledger.
        @try {
            MYNativeRemovalFrame frame = { object, observer, keyPath, nativeRemoval };
            nativeRemoval = &frame;
            @try {
                if (matchContext) ((void (*)(id, SEL, id, NSString *, void *))originalRemoveContext)(object, @selector(removeObserver:forKeyPath:context:), observer, keyPath, context);
                else ((void (*)(id, SEL, id, NSString *))originalRemove)(object, @selector(removeObserver:forKeyPath:), observer, keyPath);
            } @finally { nativeRemoval = frame.previous; }
        } @catch (NSException *exception) {
            if (![exception.name isEqualToString:NSRangeException]) @throw;
            MYKVOReport(@"KVO removal does not match a registered observer/keyPath/context");
        }
    }
}
@implementation NSObject (SafeKVO)
+ (void)registerClassPairMethodsInKVO {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        stateLock = [NSRecursiveLock new];
        SEL add = @selector(addObserver:forKeyPath:options:context:);
        SEL remove = @selector(removeObserver:forKeyPath:);
        SEL removeContext = @selector(removeObserver:forKeyPath:context:);
        Class cls = [NSObject class];
        originalAdd = method_getImplementation(class_getInstanceMethod(cls, add));
        originalRemove = method_getImplementation(class_getInstanceMethod(cls, remove));
        originalRemoveContext = method_getImplementation(class_getInstanceMethod(cls, removeContext));
        MYInstallSafeMethod(cls, add, method_getTypeEncoding(class_getInstanceMethod(cls, add)), ^id(IMP original) {
            return ^(id object, NSObject *observer, NSString *keyPath, NSKeyValueObservingOptions options, void *context) {
                if (object_getClass(observer) == [MYKVORegistration class]) ((void (*)(id, SEL, id, NSString *, NSKeyValueObservingOptions, void *))original)(object, add, observer, keyPath, options, context);
                else MYAdd(object, observer, keyPath, options, context);
            };
        });
        MYInstallSafeMethod(cls, remove, "v@:@@", ^id(IMP original) {
            return ^(id object, NSObject *observer, NSString *keyPath) {
                if (MYInternalRemoval(object, observer, keyPath)) ((void (*)(id, SEL, id, NSString *))original)(object, remove, observer, keyPath);
                else MYRemove(object, observer, keyPath, NULL, NO);
            };
        });
        MYInstallSafeMethod(cls, removeContext, "v@:@@^v", ^id(IMP original) {
            return ^(id object, NSObject *observer, NSString *keyPath, void *context) {
                if (MYInternalRemoval(object, observer, keyPath)) ((void (*)(id, SEL, id, NSString *, void *))original)(object, removeContext, observer, keyPath, context);
                else MYRemove(object, observer, keyPath, context, YES);
            };
        });
        SEL deallocSelector = sel_registerName("dealloc");
        Method method = class_getInstanceMethod(cls, deallocSelector);
        originalDealloc = method_getImplementation(method);
        class_replaceMethod(cls, deallocSelector, (IMP)MYKVODealloc, method_getTypeEncoding(method));
    });
}
@end
