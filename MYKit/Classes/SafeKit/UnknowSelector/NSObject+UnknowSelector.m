#import "NSObject+UnknowSelector.h"
#import "NSObject+Swizzle.h"
#import "MYSafeKitRecord.h"
#include <ctype.h>

static NSMutableDictionary<NSString *, NSMethodSignature *> *fallbacks;
static IMP instanceForward, classForward;
static NSString *MYFallbackKey(Class cls, SEL selector) { return [NSString stringWithFormat:@"%p:%s", cls, sel_getName(selector)]; }
// Validate syntax before asking Foundation to parse it. Encoding cannot prove the caller's ABI.
static BOOL MYParseType(const char **cursor, NSUInteger depth) {
    if (depth > 16) return NO;
    const char *p = *cursor;
    while (*p && strchr("rnNoORV", *p)) p++;
    if (!*p) return NO;
    if (strchr("cislqCISLQfdBv#:*", *p)) p++;
    else if (*p == '@') {
        p++;
        if (*p == '?') p++;
        else if (*p == '"') { p++; while (*p && *p != '"') p++; if (*p++ != '"') return NO; }
    } else if (*p == '^') {
        p++; if (!MYParseType(&p, depth + 1)) return NO;
    } else if (*p == '{') {
        p++; while (*p && *p != '=' && *p != '}') p++;
        if (*p++ != '=') return NO;
        NSUInteger fields = 0;
        while (*p && *p != '}') {
            if (*p == '"') { p++; while (*p && *p != '"') p++; if (*p++ != '"') return NO; }
            if (++fields > 128 || !MYParseType(&p, depth + 1)) return NO;
        }
        if (!fields || *p++ != '}') return NO;
    } else return NO;
    *cursor = p;
    return YES;
}
static BOOL MYValidEncoding(const char *encoding, SEL selector) {
    if (!encoding || !*encoding || strlen(encoding) > 2048) return NO;
    const char *p = encoding;
    NSUInteger types = 0;
    while (*p) {
        if (!MYParseType(&p, 0)) return NO;
        types++;
        while (isdigit((unsigned char)*p)) p++;
    }
    NSUInteger arguments = 2;
    for (const char *s = sel_getName(selector); *s; s++) if (*s == ':') arguments++;
    return types == arguments + 1;
}
static BOOL MYDefaultForwarding(id object) {
    Class cls = object_getClass(object);
    IMP current = class_getMethodImplementation(cls, @selector(forwardInvocation:));
    return current == (class_isMetaClass(cls) ? classForward : instanceForward);
}
static NSMethodSignature *MYSignature(id object, SEL selector) {
    if (!MYDefaultForwarding(object)) return nil;
    @synchronized ([NSObject class]) { return fallbacks[MYFallbackKey(object_getClass(object), selector)]; }
}
static void MYInstallForwarding(Class cls, BOOL meta) {
    SEL sigSel = @selector(methodSignatureForSelector:);
    SEL forwardSel = @selector(forwardInvocation:);
    MYInstallSafeMethod(cls, forwardSel, "v@:@", ^id(IMP original) {
        return ^(id object, NSInvocation *invocation) {
            NSMethodSignature *signature = MYSignature(object, invocation.selector);
            if (!signature) { ((void (*)(id, SEL, id))original)(object, forwardSel, invocation); return; }
            NSUInteger size = signature.methodReturnLength;
            if (size) {
                void *zero = calloc(1, size);
                if (!zero) { ((void (*)(id, SEL, id))original)(object, forwardSel, invocation); return; }
                [invocation setReturnValue:zero]; free(zero);
            }
            [MYSafeKitRecord recordFatalWithReason:[NSString stringWithFormat:@"Explicit fallback for %s", sel_getName(invocation.selector)] errorType:MYSafeKitShieldTypeUnrecognizedSelector];
        };
    });
    if (meta) classForward = class_getMethodImplementation(cls, forwardSel);
    else instanceForward = class_getMethodImplementation(cls, forwardSel);
    MYInstallSafeMethod(cls, sigSel, "@@::", ^id(IMP original) {
        return ^NSMethodSignature *(id object, SEL selector) {
            NSMethodSignature *signature = ((id (*)(id, SEL, SEL))original)(object, sigSel, selector);
            return signature ?: MYSignature(object, selector);
        };
    });
}
@implementation NSObject (UnknowSelector)
+ (BOOL)my_registerFallbackForClass:(Class)cls selector:(SEL)selector typeEncoding:(const char *)encoding {
    if (!cls || !selector || !MYValidEncoding(encoding, selector) || class_getInstanceMethod(cls, selector)) return NO;
    NSMethodSignature *signature;
    @try { signature = [NSMethodSignature signatureWithObjCTypes:encoding]; } @catch (__unused NSException *exception) { return NO; }
    if (!signature || signature.methodReturnLength > 4096 || strcmp([signature getArgumentTypeAtIndex:0], "@") || strcmp([signature getArgumentTypeAtIndex:1], ":")) return NO;
    for (NSUInteger i = 2; i < signature.numberOfArguments; i++) if (!strcmp([signature getArgumentTypeAtIndex:i], "v")) return NO;
    @synchronized ([NSObject class]) {
        if (!fallbacks) fallbacks = [NSMutableDictionary new];
        NSString *key = MYFallbackKey(cls, selector);
        NSMethodSignature *old = fallbacks[key];
        if (old) {
            if (old.numberOfArguments != signature.numberOfArguments || strcmp(old.methodReturnType, signature.methodReturnType)) return NO;
            for (NSUInteger i = 0; i < old.numberOfArguments; i++) if (strcmp([old getArgumentTypeAtIndex:i], [signature getArgumentTypeAtIndex:i])) return NO;
        }
        fallbacks[key] = signature;
    }
    return YES;
}
+ (void)safeGuardUnrecognizedSelector {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        MYInstallForwarding([NSObject class], NO);
        MYInstallForwarding(object_getClass([NSObject class]), YES);
    });
}
@end
