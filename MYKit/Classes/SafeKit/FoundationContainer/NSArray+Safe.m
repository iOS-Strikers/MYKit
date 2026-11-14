#import "NSArray+Safe.h"
#import "MYSafeContainerInternal.h"

@interface NSArray (MYConstructor)
- (instancetype)my_safe_initWithObjects:(const id [])objects count:(NSUInteger)count __attribute__((objc_method_family(init)));
@end
@implementation NSArray (Safe)
+ (void)registerClassPairMethodsInArray {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
    for (id sample in @[[NSArray alloc], [NSMutableArray alloc]]) {
        [NSObject instanceSwizzleMethodWithClass:object_getClass(sample) orginalMethod:@selector(initWithObjects:count:) replaceMethod:@selector(my_safe_initWithObjects:count:)];
    }
    for (id sample in MYArraySamples()) {
    Class cls = object_getClass(sample);
    { SEL sel = NSSelectorFromString(@"objectAtIndex:");
      MYGuard(cls, sel, "@@:" MY_UINT "", ^id(IMP original) {
          return ^id(id obj, NSUInteger index) {
              if (!(index < [obj count])) { MYContainerReport(sel); return nil; }
              return ((id (*)(id, SEL, NSUInteger))original)(obj, sel, index);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"objectAtIndexedSubscript:");
      MYGuard(cls, sel, "@@:" MY_UINT "", ^id(IMP original) {
          return ^id(id obj, NSUInteger index) {
              if (!(index < [obj count])) { MYContainerReport(sel); return nil; }
              return ((id (*)(id, SEL, NSUInteger))original)(obj, sel, index);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"arrayByAddingObject:");
      MYGuard(cls, sel, "@@:@", ^id(IMP original) {
          return ^id(id obj, id value) {
              if (!(value != nil)) { MYContainerReport(sel); return nil; }
              return ((id (*)(id, SEL, id))original)(obj, sel, value);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"indexOfObject:inRange:");
      MYGuard(cls, sel, "" MY_UINT "@:@" MY_RANGE "", ^id(IMP original) {
          return ^NSUInteger(id obj, id value, NSRange range) {
              if (!(MYValidRange(range, [obj count]))) { MYContainerReport(sel); return NSNotFound; }
              return ((NSUInteger (*)(id, SEL, id, NSRange))original)(obj, sel, value, range);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"indexOfObjectIdenticalTo:inRange:");
      MYGuard(cls, sel, "" MY_UINT "@:@" MY_RANGE "", ^id(IMP original) {
          return ^NSUInteger(id obj, id value, NSRange range) {
              if (!(MYValidRange(range, [obj count]))) { MYContainerReport(sel); return NSNotFound; }
              return ((NSUInteger (*)(id, SEL, id, NSRange))original)(obj, sel, value, range);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"subarrayWithRange:");
      MYGuard(cls, sel, "@@:" MY_RANGE "", ^id(IMP original) {
          return ^id(id obj, NSRange range) {
              if (!(MYValidRange(range, [obj count]))) { MYContainerReport(sel); return nil; }
              return ((id (*)(id, SEL, NSRange))original)(obj, sel, range);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"objectsAtIndexes:");
      MYGuard(cls, sel, "@@:@", ^id(IMP original) {
          return ^id(id obj, NSIndexSet * indexes) {
              if (!(indexes && (indexes.count == 0 || indexes.lastIndex < [obj count]))) { MYContainerReport(sel); return nil; }
              return ((id (*)(id, SEL, NSIndexSet *))original)(obj, sel, indexes);
          };
      });
    }
    }
    });
}
- (instancetype)my_safe_initWithObjects:(const id [])objects count:(NSUInteger)count {
    if (count && !objects) { MYContainerReport(_cmd); return nil; }
    NSUInteger valid = 0;
    for (NSUInteger i = 0; i < count; i++) if (objects[i]) valid++;
    if (valid == count) return [self my_safe_initWithObjects:objects count:count];
    MYContainerReport(@selector(initWithObjects:count:));
    if (valid > SIZE_MAX / sizeof(id)) return nil;
    id __unsafe_unretained *filtered = valid ? (id __unsafe_unretained *)malloc(valid * sizeof(id)) : NULL;
    if (valid && !filtered) return nil;
    NSUInteger j = 0;
    for (NSUInteger i = 0; i < count; i++) if (objects[i]) filtered[j++] = objects[i];
    @try { return [self my_safe_initWithObjects:filtered count:valid]; }
    @finally { free(filtered); }
}
@end
