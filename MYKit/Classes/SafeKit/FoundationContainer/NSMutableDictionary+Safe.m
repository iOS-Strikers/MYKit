#import "NSMutableDictionary+Safe.h"
#import "MYSafeContainerInternal.h"

@implementation NSMutableDictionary (Safe)
+ (void)registerClassPairMethodsInMutableDictionary {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
    for (id sample in @[[NSMutableDictionary new], [@{@"key": @1} mutableCopy], CFBridgingRelease(CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks))]) {
    Class cls = object_getClass(sample);
    { SEL sel = NSSelectorFromString(@"setObject:forKey:");
      MYGuard(cls, sel, "v@:@@", ^id(IMP original) {
          return ^void(id obj, id value, id key) {
              if (!(key && value)) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, id, id))original)(obj, sel, value, key);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"setObject:forKeyedSubscript:");
      MYGuard(cls, sel, "v@:@@", ^id(IMP original) {
          return ^void(id obj, id value, id key) {
              if (!(key != nil)) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, id, id))original)(obj, sel, value, key);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"removeObjectForKey:");
      MYGuard(cls, sel, "v@:@", ^id(IMP original) {
          return ^void(id obj, id key) {
              if (!(key != nil)) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, id))original)(obj, sel, key);
          };
      });
    }
    }
    });
}
@end
