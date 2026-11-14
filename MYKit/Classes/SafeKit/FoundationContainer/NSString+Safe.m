#import "NSString+Safe.h"
#import "MYSafeContainerInternal.h"

@implementation NSString (Safe)
+ (void)registerClassPairMethodsInString {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
    for (id sample in MYStringSamples()) {
    Class cls = object_getClass(sample);
    { SEL sel = NSSelectorFromString(@"characterAtIndex:");
      MYGuard(cls, sel, "S@:" MY_UINT "", ^id(IMP original) {
          return ^unichar(id obj, NSUInteger index) {
              if (!(index < [obj length])) { MYContainerReport(sel); return 0; }
              return ((unichar (*)(id, SEL, NSUInteger))original)(obj, sel, index);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"substringFromIndex:");
      MYGuard(cls, sel, "@@:" MY_UINT "", ^id(IMP original) {
          return ^id(id obj, NSUInteger index) {
              if (!(index <= [obj length])) { MYContainerReport(sel); return nil; }
              return ((id (*)(id, SEL, NSUInteger))original)(obj, sel, index);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"substringToIndex:");
      MYGuard(cls, sel, "@@:" MY_UINT "", ^id(IMP original) {
          return ^id(id obj, NSUInteger index) {
              if (!(index <= [obj length])) { MYContainerReport(sel); return nil; }
              return ((id (*)(id, SEL, NSUInteger))original)(obj, sel, index);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"substringWithRange:");
      MYGuard(cls, sel, "@@:" MY_RANGE "", ^id(IMP original) {
          return ^id(id obj, NSRange range) {
              if (!(MYValidRange(range, [obj length]))) { MYContainerReport(sel); return nil; }
              return ((id (*)(id, SEL, NSRange))original)(obj, sel, range);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"stringByReplacingCharactersInRange:withString:");
      MYGuard(cls, sel, "@@:" MY_RANGE "@", ^id(IMP original) {
          return ^id(id obj, NSRange range, NSString * value) {
              if (!(value && MYValidRange(range, [obj length]))) { MYContainerReport(sel); return nil; }
              return ((id (*)(id, SEL, NSRange, NSString *))original)(obj, sel, range, value);
          };
      });
    }
    }
    });
}
@end
