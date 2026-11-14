#import "NSNull+Safe.h"
#import "NSObject+Swizzle.h"
#import "MYSafeKitRecord.h"

@implementation NSNull (Safe)
+ (void)safeGuardNSNull {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableDictionary *signatures = [NSMutableDictionary new];
        NSDictionary *sources = @{@"length":@"", @"count":@[], @"intValue":@0, @"integerValue":@0, @"longLongValue":@0, @"unsignedLongLongValue":@0, @"doubleValue":@0, @"floatValue":@0, @"boolValue":@0, @"objectForKey:":@{}, @"objectForKeyedSubscript:":@{}, @"objectAtIndex:":@[], @"objectAtIndexedSubscript:":@[], @"characterAtIndex:":@"", @"substringFromIndex:":@"", @"substringToIndex:":@"", @"substringWithRange:":@""};
        for (NSString *name in sources) signatures[name] = [sources[name] methodSignatureForSelector:NSSelectorFromString(name)];
        NSDictionary *allowed = [signatures copy];
        SEL signatureSelector = @selector(methodSignatureForSelector:);
        MYInstallSafeMethod(self, signatureSelector, "@@::", ^id(IMP original) {
            return ^id(id object, SEL selector) {
                return allowed[NSStringFromSelector(selector)] ?: ((id (*)(id, SEL, SEL))original)(object, signatureSelector, selector);
            };
        });
        SEL forwardSelector = @selector(forwardInvocation:);
        MYInstallSafeMethod(self, forwardSelector, "v@:@", ^id(IMP original) {
            return ^(id object, NSInvocation *invocation) {
                NSMethodSignature *signature = allowed[NSStringFromSelector(invocation.selector)];
                if (!signature) { ((void (*)(id, SEL, id))original)(object, forwardSelector, invocation); return; }
                unsigned char zero[32] = {0};
                if (signature.methodReturnLength > sizeof(zero)) { ((void (*)(id, SEL, id))original)(object, forwardSelector, invocation); return; }
                [invocation setReturnValue:zero];
                [MYSafeKitRecord recordFatalWithReason:[NSString stringWithFormat:@"NSNull fallback for %s", sel_getName(invocation.selector)] errorType:MYSafeKitShieldTypeNull];
            };
        });
    });
}
@end
