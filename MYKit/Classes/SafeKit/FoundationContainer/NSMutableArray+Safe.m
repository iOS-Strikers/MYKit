#import "NSMutableArray+Safe.h"
#import "MYSafeContainerInternal.h"

static BOOL MYValidInsertion(NSIndexSet *indexes, NSArray *values, NSUInteger count) {
    if (!indexes || !values || indexes.count != values.count) return NO;
    __block NSUInteger offset = 0;
    __block BOOL valid = YES;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        if (index < offset || index - offset > count) { valid = NO; *stop = YES; }
        offset++;
    }];
    return valid;
}
@implementation NSMutableArray (Safe)
+ (void)registerClassPairMethodsInMutableArray {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
    for (id sample in @[[NSMutableArray new], [@[@1,@2] mutableCopy], CFBridgingRelease(CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks))]) {
    Class cls = object_getClass(sample);
    { SEL sel = NSSelectorFromString(@"removeObjectAtIndex:");
      MYGuard(cls, sel, "v@:" MY_UINT "", ^id(IMP original) {
          return ^void(id obj, NSUInteger index) {
              if (!(index < [obj count])) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, NSUInteger))original)(obj, sel, index);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"removeObjectsInRange:");
      MYGuard(cls, sel, "v@:" MY_RANGE "", ^id(IMP original) {
          return ^void(id obj, NSRange range) {
              if (!(MYValidRange(range, [obj count]))) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, NSRange))original)(obj, sel, range);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"insertObject:atIndex:");
      MYGuard(cls, sel, "v@:@" MY_UINT "", ^id(IMP original) {
          return ^void(id obj, id value, NSUInteger index) {
              if (!(value && index <= [obj count])) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, id, NSUInteger))original)(obj, sel, value, index);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"replaceObjectAtIndex:withObject:");
      MYGuard(cls, sel, "v@:" MY_UINT "@", ^id(IMP original) {
          return ^void(id obj, NSUInteger index, id value) {
              if (!(value && index < [obj count])) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, NSUInteger, id))original)(obj, sel, index, value);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"setObject:atIndexedSubscript:");
      MYGuard(cls, sel, "v@:@" MY_UINT "", ^id(IMP original) {
          return ^void(id obj, id value, NSUInteger index) {
              if (!(value && index <= [obj count])) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, id, NSUInteger))original)(obj, sel, value, index);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"removeObjectsAtIndexes:");
      MYGuard(cls, sel, "v@:@", ^id(IMP original) {
          return ^void(id obj, NSIndexSet * indexes) {
              if (!(indexes && (indexes.count == 0 || indexes.lastIndex < [obj count]))) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, NSIndexSet *))original)(obj, sel, indexes);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"replaceObjectsAtIndexes:withObjects:");
      MYGuard(cls, sel, "v@:@@", ^id(IMP original) {
          return ^void(id obj, NSIndexSet * indexes, NSArray * values) {
              if (!(indexes && values && indexes.count == values.count && (indexes.count == 0 || indexes.lastIndex < [obj count]))) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, NSIndexSet *, NSArray *))original)(obj, sel, indexes, values);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"insertObjects:atIndexes:");
      MYGuard(cls, sel, "v@:@@", ^id(IMP original) {
          return ^void(id obj, NSArray * values, NSIndexSet * indexes) {
              if (!(MYValidInsertion(indexes, values, [obj count]))) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, NSArray *, NSIndexSet *))original)(obj, sel, values, indexes);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"exchangeObjectAtIndex:withObjectAtIndex:");
      MYGuard(cls, sel, "v@:" MY_UINT "" MY_UINT "", ^id(IMP original) {
          return ^void(id obj, NSUInteger a, NSUInteger b) {
              if (!(a < [obj count] && b < [obj count])) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, NSUInteger, NSUInteger))original)(obj, sel, a, b);
          };
      });
    }
    { SEL sel = NSSelectorFromString(@"replaceObjectsInRange:withObjectsFromArray:");
      MYGuard(cls, sel, "v@:" MY_RANGE "@", ^id(IMP original) {
          return ^void(id obj, NSRange range, NSArray * values) {
              if (!(values && MYValidRange(range, [obj count]))) { MYContainerReport(sel); return; }
              ((void (*)(id, SEL, NSRange, NSArray *))original)(obj, sel, range, values);
          };
      });
    }
    }
    });
}
@end
