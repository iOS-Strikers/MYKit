#import "NSMutableString+Safe.h"
#import "MYSafeContainerInternal.h"

@implementation NSMutableString (Safe)
+ (void)registerClassPairMethodsInMutableString {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
    for (id sample in @[[NSMutableString new], [@"mutable" mutableCopy], CFBridgingRelease(CFStringCreateMutable(NULL, 0))]) {
    Class cls = object_getClass(sample);
    { SEL sel = NSSelectorFromString(@"replaceCharactersInRange:withString:");
      MYGuard(cls, sel, "v@:" MY_RANGE "@", ^id(IMP original) {
          return ^void(id obj, NSRange range, NSString * value) {
              if (!(value && MYValidRange(range, [obj length]))) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, NSRange, NSString *))original)(obj, sel, range, value);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"insertString:atIndex:");
      MYGuard(cls, sel, "v@:@" MY_UINT "", ^id(IMP original) {
          return ^void(id obj, NSString * value, NSUInteger index) {
              if (!(value && index <= [obj length])) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, NSString *, NSUInteger))original)(obj, sel, value, index);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"deleteCharactersInRange:");
      MYGuard(cls, sel, "v@:" MY_RANGE "", ^id(IMP original) {
          return ^void(id obj, NSRange range) {
              if (!(MYValidRange(range, [obj length]))) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, NSRange))original)(obj, sel, range);
          };
      });
    }
    }
    });
}
@end
