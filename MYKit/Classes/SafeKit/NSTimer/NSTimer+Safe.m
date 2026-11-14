#import "NSTimer+Safe.h"
#import "NSObject+Swizzle.h"
#import "MYSafeKitRecord.h"
#import <objc/message.h>

@interface MYTimerProxy : NSObject
@property (nonatomic, weak) id target;
@property (nonatomic) SEL selector;
- (void)trigger:(NSTimer *)timer;
@end
@implementation MYTimerProxy
- (void)trigger:(NSTimer *)timer {
    id target = self.target;
    if (target) {
        // Normal Objective-C dispatch preserves resolution and both forwarding stages.
        ((void (*)(id, SEL, NSTimer *))objc_msgSend)(target, self.selector, timer);
    } else {
        [timer invalidate];
        [MYSafeKitRecord recordFatalWithReason:@"Repeating timer target was released" errorType:MYSafeKitShieldTypeTimer];
    }
}
@end
@implementation NSTimer (Safe)
+ (void)registerClassPairMethodsInTimer {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        for (NSString *name in @[@"scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:", @"timerWithTimeInterval:target:selector:userInfo:repeats:"]) {
            SEL selector = NSSelectorFromString(name);
            Class cls = object_getClass(self);
            MYInstallSafeMethod(cls, selector, method_getTypeEncoding(class_getInstanceMethod(cls, selector)), ^id(IMP original) {
                return ^NSTimer *(id object, NSTimeInterval interval, id target, SEL callback, id userInfo, BOOL repeats) {
                    id effectiveTarget = target;
                    SEL effectiveSelector = callback;
                    // The scheduled factory may call the other factory internally.
                    if (repeats && target && callback && ![target isKindOfClass:[MYTimerProxy class]]) {
                        MYTimerProxy *proxy = [MYTimerProxy new]; proxy.target = target; proxy.selector = callback;
                        effectiveTarget = proxy; effectiveSelector = @selector(trigger:);
                    }
                    return ((id (*)(id, SEL, NSTimeInterval, id, SEL, id, BOOL))original)(object, selector, interval, effectiveTarget, effectiveSelector, userInfo, repeats);
                };
            });
        }
    });
}
@end
