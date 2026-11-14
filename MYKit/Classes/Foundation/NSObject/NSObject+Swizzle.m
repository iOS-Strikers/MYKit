#import "NSObject+Swizzle.h"

static BOOL MYTypesMatch(Method method, const char *encoding) {
    if (!method || !encoding) return NO;
    NSMethodSignature *a = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    NSMethodSignature *b = [NSMethodSignature signatureWithObjCTypes:encoding];
    if (!a || !b || a.numberOfArguments != b.numberOfArguments || strcmp(a.methodReturnType, b.methodReturnType)) return NO;
    for (NSUInteger i = 0; i < a.numberOfArguments; i++) {
        if (strcmp([a getArgumentTypeAtIndex:i], [b getArgumentTypeAtIndex:i])) return NO;
    }
    return YES;
}

BOOL MYInstallSafeMethod(Class cls, SEL selector, const char *encoding, id (^factory)(IMP)) {
    if (!cls || !selector || !factory) return NO;
    @synchronized ([NSObject class]) {
        static NSMutableSet *installed;
        if (!installed) installed = [NSMutableSet new];
        NSString *key = [NSString stringWithFormat:@"%p:%s", cls, sel_getName(selector)];
        if ([installed containsObject:key]) return YES;
        Method method = class_getInstanceMethod(cls, selector);
        if (!MYTypesMatch(method, encoding)) return NO;
        IMP original = method_getImplementation(method);
        IMP replacement = imp_implementationWithBlock(factory(original));
        if (!replacement) return NO;
        class_replaceMethod(cls, selector, replacement, method_getTypeEncoding(method));
        [installed addObject:key];
        return YES;
    }
}

static void MYExchange(Class cls, SEL original, SEL replacement) {
    if (!cls || !original || !replacement || original == replacement) return;
    @synchronized ([NSObject class]) {
        static NSMutableSet *installed;
        if (!installed) installed = [NSMutableSet new];
        NSString *key = [NSString stringWithFormat:@"%p:%s:%s", cls, sel_getName(original), sel_getName(replacement)];
        if ([installed containsObject:key]) return;
        Method a = class_getInstanceMethod(cls, original);
        Method b = class_getInstanceMethod(cls, replacement);
        if (!a || !b || !MYTypesMatch(a, method_getTypeEncoding(b))) return;
        IMP ai = method_getImplementation(a), bi = method_getImplementation(b);
        const char *at = method_getTypeEncoding(a), *bt = method_getTypeEncoding(b);
        class_replaceMethod(cls, original, bi, at);
        class_replaceMethod(cls, replacement, ai, bt);
        [installed addObject:key];
    }
}

@implementation NSObject (Swizzle)
+ (void)swizzleClassMethod:(SEL)original replaceMethod:(SEL)replacement { MYExchange(object_getClass(self), original, replacement); }
- (void)instanceSwizzleMethod:(SEL)original replaceMethod:(SEL)replacement { MYExchange([self class], original, replacement); }
+ (void)classSwizzleMethodWithClass:(Class)cls orginalMethod:(SEL)original replaceMethod:(SEL)replacement { MYExchange(object_getClass(cls), original, replacement); }
+ (void)instanceSwizzleMethodWithClass:(Class)cls orginalMethod:(SEL)original replaceMethod:(SEL)replacement { MYExchange(cls, original, replacement); }
@end
