#import "NSObject+Safe.h"
#import "MYSafeContainerInternal.h"

@implementation NSObject (Safe)
+ (void)registerClassPairMethodsInObject {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
    for (id sample in @[[NSObject new]]) {
    Class cls = object_getClass(sample);
    { SEL sel = NSSelectorFromString(@"setValue:forKey:");
      MYGuard(cls, sel, "v@:@@", ^id(IMP original) {
          return ^void(id obj, id value, NSString * key) {
              if (!(key != nil)) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, id, NSString *))original)(obj, sel, value, key);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"setValue:forKeyPath:");
      MYGuard(cls, sel, "v@:@@", ^id(IMP original) {
          return ^void(id obj, id value, NSString * key) {
              if (!(key != nil)) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, id, NSString *))original)(obj, sel, value, key);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"valueForKey:");
      MYGuard(cls, sel, "@@:@", ^id(IMP original) {
          return ^id(id obj, NSString * key) {
              if (!(key != nil)) { MYContainerReport(sel); return nil; }
              return ((id (*)(id, SEL, NSString *))original)(obj, sel, key);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"valueForKeyPath:");
      MYGuard(cls, sel, "@@:@", ^id(IMP original) {
          return ^id(id obj, NSString * key) {
              if (!(key != nil)) { MYContainerReport(sel); return nil; }
              return ((id (*)(id, SEL, NSString *))original)(obj, sel, key);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"valueForUndefinedKey:");
      MYGuard(cls, sel, "@@:@", ^id(IMP original) {
          return ^id(id obj, NSString * key) {
              if (!(NO)) { MYContainerReport(sel); return nil; }
              return ((id (*)(id, SEL, NSString *))original)(obj, sel, key);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"setValue:forUndefinedKey:");
      MYGuard(cls, sel, "v@:@@", ^id(IMP original) {
          return ^void(id obj, id value, NSString * key) {
              if (!(NO)) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, id, NSString *))original)(obj, sel, value, key);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"setNilValueForKey:");
      MYGuard(cls, sel, "v@:@", ^id(IMP original) {
          return ^void(id obj, NSString * key) {
              if (!(NO)) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, NSString *))original)(obj, sel, key);
          };
      });
    }
    }
    });
}
@end
