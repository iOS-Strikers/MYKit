#import "NSDictionary+Safe.h"
#import "MYSafeContainerInternal.h"

@interface NSDictionary (MYConstructor)
- (instancetype)my_safe_initWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)count __attribute__((objc_method_family(init)));
@end
@implementation NSDictionary (Safe)
+ (void)registerClassPairMethodsInDictionary {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        for (id sample in @[[NSDictionary alloc], [NSMutableDictionary alloc]]) {
            [NSObject instanceSwizzleMethodWithClass:object_getClass(sample) orginalMethod:@selector(initWithObjects:forKeys:count:) replaceMethod:@selector(my_safe_initWithObjects:forKeys:count:)];
        }
        SEL sel = @selector(dictionaryWithObjects:forKeys:);
        MYGuard(object_getClass(self), sel, "@@:@@", ^id(IMP original) {
            return ^id(id obj, NSArray *objects, NSArray *keys) {
                if (objects.count != keys.count) { MYContainerReport(sel); return nil; }
                return ((id (*)(id, SEL, id, id))original)(obj, sel, objects, keys);
            };
        });
    });
}
- (instancetype)my_safe_initWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)count {
    if (count && (!objects || !keys)) { MYContainerReport(_cmd); return nil; }
    NSUInteger valid = 0;
    for (NSUInteger i = 0; i < count; i++) if (objects[i] && keys[i]) valid++;
    if (valid == count) return [self my_safe_initWithObjects:objects forKeys:keys count:count];
    MYContainerReport(@selector(initWithObjects:forKeys:count:));
    if (valid > SIZE_MAX / sizeof(id)) return nil;
    id __unsafe_unretained *filteredObjects = valid ? (id __unsafe_unretained *)malloc(valid * sizeof(id)) : NULL;
    id __unsafe_unretained *filteredKeys = valid ? (id __unsafe_unretained *)malloc(valid * sizeof(id)) : NULL;
    if (valid && (!filteredObjects || !filteredKeys)) { free(filteredObjects); free(filteredKeys); return nil; }
    NSUInteger j = 0;
    for (NSUInteger i = 0; i < count; i++) if (objects[i] && keys[i]) { filteredObjects[j] = objects[i]; filteredKeys[j++] = keys[i]; }
    @try { return [self my_safe_initWithObjects:filteredObjects forKeys:filteredKeys count:valid]; }
    @finally { free(filteredObjects); free(filteredKeys); }
}
@end
