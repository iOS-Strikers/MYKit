#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#if __LP64__
#define MY_UINT "Q"
#define MY_RANGE "{_NSRange=QQ}"
#else
#define MY_UINT "I"
#define MY_RANGE "{_NSRange=II}"
#endif
#import "NSObject+Swizzle.h"
#import "MYSafeKitRecord.h"
static inline BOOL MYValidRange(NSRange range, NSUInteger count) {
    return range.location <= count && range.length <= count - range.location;
}
static inline void MYContainerReport(SEL selector) {
    [MYSafeKitRecord recordFatalWithReason:[NSString stringWithFormat:@"Invalid arguments for %s", sel_getName(selector)] errorType:MYSafeKitShieldTypeContainer];
}
static inline void MYGuard(Class cls, SEL sel, const char *encoding, id (^factory)(IMP)) {
    if (!MYInstallSafeMethod(cls, sel, encoding, factory)) {
        [MYSafeKitRecord recordFatalWithReason:[NSString stringWithFormat:@"Unavailable guard: %s / %s", class_getName(cls), sel_getName(sel)] errorType:MYSafeKitShieldTypeContainer];
    }
}
static inline NSArray *MYArraySamples(void) {
    return @[@[], @[@1], @[@1,@2], [NSMutableArray new], [@[@1,@2] mutableCopy], CFBridgingRelease(CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks))];
}
static inline NSArray *MYStringSamples(void) {
    return @[@"", @"x", @"constant string longer than tagged storage", [NSString stringWithFormat:@"%d", 123], [NSString stringWithFormat:@"dynamic %@ %d", @"long string content", 123], [NSMutableString new], [@"mutable content" mutableCopy], CFBridgingRelease(CFStringCreateMutable(NULL, 0))];
}
