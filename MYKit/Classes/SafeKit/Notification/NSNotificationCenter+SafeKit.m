#import "NSNotificationCenter+SafeKit.h"
#import "NSObject+Swizzle.h"

@interface MYNotificationLifetime : NSObject
- (instancetype)initWithObserver:(id)observer;
- (void)addCenter:(NSNotificationCenter *)center;
@end
@implementation MYNotificationLifetime {
    NSHashTable<NSNotificationCenter *> *_centers;
    __unsafe_unretained id _observer;
}
- (instancetype)initWithObserver:(id)observer {
    if ((self = [super init])) { _observer = observer; _centers = [NSHashTable weakObjectsHashTable]; }
    return self;
}
- (void)addCenter:(NSNotificationCenter *)center { @synchronized (_centers) { [_centers addObject:center]; } }
- (void)dealloc {
    // Associated objects are released while the observer's storage still exists.
    @autoreleasepool { for (NSNotificationCenter *center in _centers.allObjects) [center removeObserver:_observer]; }
}
@end
@implementation NSNotificationCenter (SafeKit)
+ (void)safeGuardNotificationSelector {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        SEL selector = @selector(addObserver:selector:name:object:);
        MYInstallSafeMethod(self, selector, "v@:@:@@", ^id(IMP original) {
            return ^(NSNotificationCenter *center, id observer, SEL callback, NSString *name, id object) {
                ((void (*)(id, SEL, id, SEL, id, id))original)(center, selector, observer, callback, name, object);
                if (!observer) return;
                static char lifetimeKey;
                @synchronized (observer) {
                    MYNotificationLifetime *lifetime = objc_getAssociatedObject(observer, &lifetimeKey);
                    if (!lifetime) {
                        lifetime = [[MYNotificationLifetime alloc] initWithObserver:observer];
                        objc_setAssociatedObject(observer, &lifetimeKey, lifetime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    }
                    [lifetime addCenter:center];
                }
            };
        });
    });
}
@end
