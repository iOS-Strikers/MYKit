@import XCTest;
// Invalid-input fixtures intentionally exercise annotated Foundation preconditions.
#pragma clang diagnostic ignored "-Wnonnull"
#import "MYSafeKit.h"
#import "NSObject+Swizzle.h"
#import "MYSafeKitRecord.h"
#import <objc/message.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SafeKitFixture/SafeKitFixture.h>

static NSString *mode;
static BOOL Has(NSString *name) { return [mode isEqual:name] || [mode isEqual:@"All"] || [mode isEqual:@"Reverse"] || [mode isEqual:@"Concurrent"]; }
@interface TestReporter : NSObject <MYSafeKitRecordProtocol>
@property (nonatomic, strong) NSMutableArray<NSError *> *errors;
@property (nonatomic, copy) void (^callback)(void);
@end
@implementation TestReporter
- (instancetype)init { if ((self=[super init])) _errors=[NSMutableArray new]; return self; }
- (void)recordWithReason:(NSError *)error { @synchronized(self) { [self.errors addObject:error]; } if(self.callback) self.callback(); }
@end
static TestReporter *reporter;
@interface Model : NSObject
@property (nonatomic, strong) NSString *value;
@property (nonatomic) NSInteger number;
@end
@implementation Model
@end
@interface Observer : NSObject
@property (nonatomic) NSUInteger count;
@property (nonatomic, strong) NSMutableArray *changes;
@property (nonatomic, strong) NSMutableArray *contexts;
@property (nonatomic, copy) void (^callback)(NSString *, id, NSDictionary *, void *);
@end
@implementation Observer
- (instancetype)init { if((self=[super init])) { _changes=[NSMutableArray new]; _contexts=[NSMutableArray new]; } return self; }
- (void)observeValueForKeyPath:(NSString *)path ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    self.count++; [self.changes addObject:change]; [self.contexts addObject:[NSValue valueWithPointer:context]];
    if(self.callback) self.callback(path,object,change,context);
}
@end
static void (^registrationReentry)(void);
@interface ReentrantModel : Model
@end
@implementation ReentrantModel
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    void (^callback)(void) = registrationReentry; registrationReentry=nil;
    if(callback) callback();
    return [super automaticallyNotifiesObserversForKey:key];
}
@end
static BOOL failRegistration;
@interface FailingRegistrationModel : Model
@end
@implementation FailingRegistrationModel
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if (failRegistration) [NSException raise:@"RegistrationError" format:@"fixture registration failed"];
    return [super automaticallyNotifiesObserversForKey:key];
}
@end
static Model *preexistingModel;
static Observer *preexistingObserver;
static NSArray *startupErrors;
@interface OverrideModel : Model
@end
@implementation OverrideModel
- (id)valueForUndefinedKey:(NSString *)key { return @42; }
- (NSString *)danger { [NSException raise:@"BusinessError" format:@"getter"]; return nil; }
@end
@interface Sentinel : NSObject
@property (nonatomic, copy) void (^onDealloc)(void);
@end
@implementation Sentinel
- (void)dealloc { if(_onDealloc) _onDealloc(); }
@end
@interface Target : NSObject
@property (nonatomic) NSUInteger count;
@property (nonatomic, weak) NSTimer *lastTimer;
@property (nonatomic, strong) id lastInfo;
- (void)tick:(NSTimer *)timer;
- (void)note:(NSNotification *)note;
@end
@implementation Target
- (void)tick:(NSTimer *)timer { self.count++; self.lastTimer=timer; self.lastInfo=timer.userInfo; }
- (void)note:(NSNotification *)note { self.count++; }
@end
@interface ForwardTarget : NSObject
@property (nonatomic, strong) Target *target;
@end
@implementation ForwardTarget
- (id)forwardingTargetForSelector:(SEL)sel { return self.target; }
@end
@interface InvocationTarget : NSObject
@property (nonatomic, strong) Target *target;
@end
@implementation InvocationTarget
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector { return [self.target methodSignatureForSelector:selector] ?: [super methodSignatureForSelector:selector]; }
- (void)forwardInvocation:(NSInvocation *)invocation { [invocation invokeWithTarget:self.target]; }
@end
@interface ThrowForward : NSObject
@end
@implementation ThrowForward
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector { return [NSMethodSignature signatureWithObjCTypes:"v@:"]; }
- (void)forwardInvocation:(NSInvocation *)invocation { [NSException raise:@"ForwardError" format:@"custom forwarding"]; }
@end
@interface Missing : NSObject
@end
@implementation Missing
@end
@interface ResolveTarget : NSObject
@end
static NSInteger Resolved(id self,SEL cmd) { return 91; }
@implementation ResolveTarget
+ (BOOL)resolveInstanceMethod:(SEL)selector {
    if(selector==NSSelectorFromString(@"resolvedValue")) { class_addMethod(self,selector,(IMP)Resolved,@encode(NSInteger)[0]=='q'?"q@:":"i@:"); return YES; }
    return [super resolveInstanceMethod:selector];
}
@end
@interface HookParent : NSObject
- (NSInteger)value;
- (NSInteger)replacement;
@end
@implementation HookParent
- (NSInteger)value {return 1;}
- (NSInteger)replacement {return 9;}
@end
@interface HookChild : HookParent
@end
@implementation HookChild
- (NSInteger)value {return 2;}
@end

typedef struct { double x; double y; double z; } TestTriple;
@protocol MissingStructCall
- (TestTriple)missingTriple;
@end
@interface SafeKitTests : XCTestCase
@end
@implementation SafeKitTests
+ (void)setUp {
    [super setUp];
    mode = NSProcessInfo.processInfo.environment[@"MYKIT_TEST_MODE"];
    NSLog(@"MYKIT_TEST_MODE=%@", mode);
    reporter=[TestReporter new]; [MYSafeKit registerRecordHandler:reporter];
    preexistingModel=[Model new]; preexistingObserver=[Observer new];
    [preexistingModel addObserver:preexistingObserver forKeyPath:@"value" options:0 context:NULL];
    NSDictionary *bits=@{@"Container":@(MYSafeKitShieldTypeContainer), @"KVO":@(MYSafeKitShieldTypeKVO), @"Unknown":@(MYSafeKitShieldTypeUnrecognizedSelector), @"Null":@(MYSafeKitShieldTypeNull), @"Notification":@(MYSafeKitShieldTypeNotification), @"Timer":@(MYSafeKitShieldTypeTimer)};
    if([mode isEqual:@"Concurrent"]) dispatch_apply(20,dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^(size_t i){[MYSafeKit registerSafeKitShield];});
    else if([mode isEqual:@"All"]) [MYSafeKit registerSafeKitShield];
    else if([mode isEqual:@"Reverse"]) for(NSString *name in @[@"Null",@"Timer",@"Notification",@"KVO",@"Container",@"Unknown"]) [MYSafeKit registerSafeKitShieldWithAbility:[bits[name] unsignedIntegerValue]];
    else [MYSafeKit registerSafeKitShieldWithAbility:[bits[mode] unsignedIntegerValue]];
    startupErrors=[reporter.errors copy];
}
- (void)setUp { [super setUp]; reporter.callback=nil; [reporter.errors removeAllObjects]; [MYSafeKit registerRecordHandler:reporter]; }
- (void)tearDown { reporter.callback=nil; [MYSafeKit registerRecordHandler:reporter]; [super tearDown]; }
- (void)testNativeSemanticsAndIsolation {
    XCTAssertNotNil(mode, @"Missing test mode must never silently become Native");
    Model *model=[Model new]; model.value=@"old"; [model setValue:nil forKey:@"value"]; XCTAssertNil(model.value);
    NSMutableDictionary *dictionary=[@{@"k":@1} mutableCopy]; dictionary[@"k"]=nil; XCTAssertEqual(dictionary.count,0u);
    XCTAssertEqualObjects([@"abc" substringFromIndex:3],@""); XCTAssertEqualObjects([@"abc" substringToIndex:3],@"abc"); XCTAssertEqualObjects([@"" substringToIndex:0],@"");
    if(!Has(@"Container")) { XCTAssertThrows([[NSObject new] valueForKey:@"missing"]); XCTAssertThrows([@[] objectAtIndex:0]); }
    XCTAssertEqualObjects([NSDictionary dictionaryWithObjects:nil forKeys:nil],@{});
    XCTAssertEqualObjects([NSDictionary dictionaryWithObjects:nil forKeys:@[]],@{});
    XCTAssertEqual(reporter.errors.count,0u);
}
- (void)testSwizzleInheritanceMissingMethodsAndIdempotence {
    [NSObject instanceSwizzleMethodWithClass:[HookChild class] orginalMethod:@selector(value) replaceMethod:@selector(replacement)];
    [NSObject instanceSwizzleMethodWithClass:[HookChild class] orginalMethod:@selector(value) replaceMethod:@selector(replacement)];
    XCTAssertEqual([HookParent new].value,1); XCTAssertEqual([HookParent new].replacement,9);
    XCTAssertEqual([HookChild new].value,9); XCTAssertEqual([HookChild new].replacement,2);
    XCTAssertFalse(MYInstallSafeMethod(Nil,@selector(value),"q@:",^id(IMP p){return ^NSInteger(id o){return 0;};}));
    XCTAssertFalse(MYInstallSafeMethod([HookChild class],NSSelectorFromString(@"absent"),"q@:",^id(IMP p){return ^NSInteger(id o){return 0;};}));
    XCTAssertFalse(MYInstallSafeMethod([HookChild class],@selector(value),"v@:",^id(IMP p){return ^(id o){};}));
}
- (void)testRepeatAndConcurrentRegistration {
    XCTSkipUnless(Has(@"Container"),@"Container mode");
    dispatch_apply(30, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0), ^(size_t i){[MYSafeKit registerSafeKitShieldWithAbility:MYSafeKitShieldTypeContainer];});
    XCTAssertNil([@[] objectAtIndex:3]);
}
- (void)testArrayReadsAndRangeOverflow {
    XCTSkipUnless(Has(@"Container"),@"Container mode");
    NSArray *samples=@[@[],@[@1],@[@1,@2],[@[@1,@2] mutableCopy],CFBridgingRelease(CFArrayCreateMutable(NULL,0,&kCFTypeArrayCallBacks))];
    for(NSArray *a in samples) {
        XCTAssertNil([a objectAtIndex:a.count]); XCTAssertNil([a objectAtIndexedSubscript:a.count]);
        XCTAssertNil([a subarrayWithRange:NSMakeRange(NSUIntegerMax,2)]);
        XCTAssertEqual([a indexOfObject:@1 inRange:NSMakeRange(NSUIntegerMax,2)],NSNotFound);
        XCTAssertEqual([a indexOfObjectIdenticalTo:@1 inRange:NSMakeRange(NSUIntegerMax,2)],NSNotFound);
        XCTAssertEqualObjects([a subarrayWithRange:NSMakeRange(a.count,0)],@[]);
        XCTAssertNil([a arrayByAddingObject:nil]); XCTAssertNil([a objectsAtIndexes:[NSIndexSet indexSetWithIndex:a.count]]);
        XCTAssertEqualObjects([a objectsAtIndexes:[NSIndexSet indexSet]],@[]);
        if(a.count) { XCTAssertEqualObjects([a objectAtIndex:0],@1); XCTAssertEqual([a indexOfObject:@1 inRange:NSMakeRange(0,a.count)],0u); XCTAssertEqual([a indexOfObjectIdenticalTo:a[0] inRange:NSMakeRange(0,a.count)],0u); XCTAssertEqualObjects([a objectsAtIndexes:[NSIndexSet indexSetWithIndex:0]],@[@1]); }
        XCTAssertEqual([a arrayByAddingObject:@5].count,a.count+1);
    }
}
- (void)testArrayMutationsAtomicAndValid {
    XCTSkipUnless(Has(@"Container"),@"Container mode");
    NSMutableArray *a=[NSMutableArray new]; [a insertObjects:@[@1,@2] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,2)]];
    XCTAssertEqualObjects(a,(@[@1,@2]));
    [a insertObject:@3 atIndex:a.count]; [a setObject:@4 atIndexedSubscript:a.count]; [a replaceObjectAtIndex:0 withObject:@5]; [a exchangeObjectAtIndex:0 withObjectAtIndex:1];
    [a replaceObjectsAtIndexes:[NSIndexSet indexSetWithIndex:0] withObjects:@[@6]];
    [a replaceObjectsInRange:NSMakeRange(a.count,0) withObjectsFromArray:@[@7]];
    NSArray *before=[a copy];
    [a replaceObjectAtIndex:a.count withObject:@9]; [a insertObject:nil atIndex:0]; [a insertObject:@1 atIndex:NSUIntegerMax]; [a setObject:nil atIndexedSubscript:0];
    [a removeObjectAtIndex:a.count]; [a removeObjectsInRange:NSMakeRange(NSUIntegerMax,2)];
    [a replaceObjectsAtIndexes:[NSIndexSet indexSetWithIndex:0] withObjects:@[]];
    [a insertObjects:@[@1] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,2)]];
    [a exchangeObjectAtIndex:0 withObjectAtIndex:a.count]; [a removeObjectsAtIndexes:[NSIndexSet indexSetWithIndex:a.count]];
    [a replaceObjectsInRange:NSMakeRange(NSUIntegerMax,2) withObjectsFromArray:@[]];
    XCTAssertEqualObjects(a,before);
    [a removeObjectsAtIndexes:[NSIndexSet indexSetWithIndex:0]]; [a removeObjectsInRange:NSMakeRange(0,a.count)]; XCTAssertEqual(a.count,0u);
}
- (void)testConstructorsAndLargeInput {
    XCTSkipUnless(Has(@"Container"),@"Container mode");
    id objects[]={@1,nil,@3}; id keys[]={@"a",@"b",nil};
    XCTAssertEqualObjects([NSArray arrayWithObjects:objects count:3],(@[@1,@3]));
    XCTAssertEqualObjects([[NSArray alloc] initWithObjects:objects count:3],(@[@1,@3]));
    XCTAssertEqualObjects([[NSMutableArray alloc] initWithObjects:objects count:3],(@[@1,@3]));
    XCTAssertEqualObjects([NSDictionary dictionaryWithObjects:objects forKeys:keys count:3],(@{@"a":@1}));
    XCTAssertEqualObjects([[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys count:3],(@{@"a":@1}));
    XCTAssertNil([NSDictionary dictionaryWithObjects:@[@1] forKeys:@[]]);
    XCTAssertEqualObjects([NSDictionary dictionaryWithObjects:@[] forKeys:@[]],@{});
    NSUInteger n=200000; id __unsafe_unretained *buffer=(id __unsafe_unretained *)calloc(n,sizeof(id));
    for(NSUInteger i=0;i<n;i++) buffer[i]=@1;
    NSArray *large=[NSArray arrayWithObjects:buffer count:n]; free(buffer); XCTAssertEqual(large.count,n); XCTAssertEqualObjects(large.lastObject,@1);
}
- (void)testDictionaryMutationAndBridging {
    XCTSkipUnless(Has(@"Container"),@"Container mode");
    NSArray *samples=@[[NSMutableDictionary new],CFBridgingRelease(CFDictionaryCreateMutable(NULL,0,&kCFTypeDictionaryKeyCallBacks,&kCFTypeDictionaryValueCallBacks))];
    for(NSMutableDictionary *d in samples) {
        [d setObject:@1 forKey:@"a"]; d[@"a"]=nil; XCTAssertEqual(d.count,0u);
        [d setObject:nil forKey:@"b"]; [d setObject:@1 forKey:nil]; [d setObject:@1 forKeyedSubscript:nil]; [d removeObjectForKey:nil]; XCTAssertEqual(d.count,0u);
        d[@"b"]=@2; [d removeObjectForKey:@"b"]; XCTAssertEqual(d.count,0u);
    }
}
- (void)testStringsAllBoundariesAndBridging {
    XCTSkipUnless(Has(@"Container"),@"Container mode");
    NSArray *strings=@[@"",@"a",@"long constant content for testing",[NSString stringWithFormat:@"%d",123],[NSString stringWithFormat:@"dynamic long content %@",@"test"],[@"mutable" mutableCopy],CFBridgingRelease(CFStringCreateMutable(NULL,0))];
    for(NSString *s in strings) {
        XCTAssertEqualObjects([s substringFromIndex:s.length],@""); XCTAssertEqualObjects([s substringToIndex:s.length],s);
        XCTAssertEqualObjects([s substringWithRange:NSMakeRange(s.length,0)],@"");
        XCTAssertNil([s substringWithRange:NSMakeRange(NSUIntegerMax,2)]); XCTAssertNil([s substringFromIndex:NSUIntegerMax]); XCTAssertNil([s substringToIndex:NSUIntegerMax]);
        XCTAssertEqual([s characterAtIndex:s.length],0); if(s.length) XCTAssertNotEqual([s characterAtIndex:0],0);
        XCTAssertNil([s stringByReplacingCharactersInRange:NSMakeRange(0,0) withString:nil]);
        XCTAssertEqualObjects([s stringByReplacingCharactersInRange:NSMakeRange(s.length,0) withString:@"x"],[s stringByAppendingString:@"x"]);
    }
    NSMutableString *s=[@"abc" mutableCopy];
    [s replaceCharactersInRange:NSMakeRange(1,99) withString:@"x"]; [s replaceCharactersInRange:NSMakeRange(0,1) withString:nil];
    [s deleteCharactersInRange:NSMakeRange(NSUIntegerMax,2)]; [s insertString:nil atIndex:0]; [s insertString:@"x" atIndex:99]; XCTAssertEqualObjects(s,@"abc");
    [s insertString:@"d" atIndex:3]; [s replaceCharactersInRange:NSMakeRange(0,1) withString:@"A"]; [s deleteCharactersInRange:NSMakeRange(1,2)]; XCTAssertEqualObjects(s,@"Ad");
}
- (void)testKVCDefaultsAndOverrides {
    XCTSkipUnless(Has(@"Container"),@"Container mode");
    Model *m=[Model new]; m.value=@"old"; [m setValue:nil forKeyPath:@"value"]; XCTAssertNil(m.value);
    [m setValue:@3 forKey:@"number"]; [m setValue:nil forKey:@"number"]; XCTAssertEqual(m.number,3);
    XCTAssertNil([m valueForKey:@"undefined"]); [m setValue:@1 forKey:@"undefined"]; XCTAssertNil([m valueForKey:nil]); [m setValue:@1 forKey:nil];
    OverrideModel *custom=[OverrideModel new]; XCTAssertEqualObjects([custom valueForKey:@"undefined"],@42);
    XCTAssertThrowsSpecificNamed([custom valueForKey:@"danger"],NSException,@"BusinessError");
}
- (void)testKVOIdentityOptionsAndRemoval {
    XCTSkipUnless(Has(@"KVO") || [mode isEqual:@"Native"],@"KVO/native mode");
    Model *m=[Model new]; m.value=@"old"; Observer *a=[Observer new],*b=[Observer new]; int x,y;
    [m addObserver:a forKeyPath:@"value" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&x];
    [m addObserver:a forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:&y];
    [m addObserver:b forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:NULL];
    m.value=@"new"; XCTAssertEqual(a.count,2u); XCTAssertEqual(b.count,1u);
    XCTAssertEqualObjects(a.changes[0][NSKeyValueChangeNewKey],@"new");
    [m removeObserver:a forKeyPath:@"value" context:&y]; m.value=@"next"; XCTAssertEqual(a.count,3u); XCTAssertEqual([a.contexts.lastObject pointerValue],&x);
    if(Has(@"KVO")) { [m removeObserver:[Observer new] forKeyPath:@"value"]; [m removeObserver:a forKeyPath:@"value" context:&y]; }
    m.value=@"last"; XCTAssertEqual(a.count,4u); XCTAssertEqual(b.count,3u);
    [m removeObserver:a forKeyPath:@"value"]; [m removeObserver:b forKeyPath:@"value"]; m.value=@"silent"; XCTAssertEqual(a.count,4u);
}
- (void)testKVODuplicateAndContextlessNativeParity {
    XCTSkipUnless(Has(@"KVO") || [mode isEqual:@"Native"],@"KVO/native mode");
    Model *m=[Model new]; Observer *a=[Observer new]; int x,y;
    [m addObserver:a forKeyPath:@"value" options:0 context:&x]; [m addObserver:a forKeyPath:@"value" options:0 context:&x];
    m.value=@"1"; XCTAssertEqual(a.count,2u); [m removeObserver:a forKeyPath:@"value" context:&x]; m.value=@"2"; XCTAssertEqual(a.count,3u);
    [m addObserver:a forKeyPath:@"value" options:0 context:&y]; [m removeObserver:a forKeyPath:@"value"]; m.value=@"3"; XCTAssertEqual(a.count,4u); XCTAssertEqual([a.contexts.lastObject pointerValue],&x);
    [m removeObserver:a forKeyPath:@"value"];
}
- (void)testKVOInitialReentryAndPrior {
    XCTSkipUnless(Has(@"KVO") || [mode isEqual:@"Native"],@"KVO/native mode");
    Model *m=[Model new]; m.value=@"initial"; Observer *a=[Observer new]; int x;
    [m addObserver:a forKeyPath:@"value" options:0 context:&x];
    a.callback=^(NSString *path,id object,NSDictionary *change,void *ctx){
        [object removeObserver:a forKeyPath:path context:ctx]; a.callback=nil;
        [object addObserver:a forKeyPath:path options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionPrior context:ctx];
    };
    [m addObserver:a forKeyPath:@"value" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:&x];
    XCTAssertEqual(a.count,1u); XCTAssertEqualObjects(a.changes[0][NSKeyValueChangeNewKey],@"initial");
    m.value=@"next"; XCTAssertEqual(a.count,4u); XCTAssertEqualObjects(a.changes[1][NSKeyValueChangeNotificationIsPriorKey],@YES);
    XCTAssertTrue([[a.changes valueForKey:NSKeyValueChangeOldKey] containsObject:@"initial"]); [m removeObserver:a forKeyPath:@"value"]; [m removeObserver:a forKeyPath:@"value"];
}
- (void)testKVOInitialExceptionLeavesNoRegistration {
    XCTSkipUnless(Has(@"KVO") || [mode isEqual:@"Native"],@"KVO/native mode");
    Model *m=[Model new]; Observer *a=[Observer new];
    a.callback=^(NSString *path,id obj,NSDictionary *change,void *ctx){[NSException raise:@"ObserverError" format:@"initial"];};
    XCTAssertThrowsSpecificNamed([m addObserver:a forKeyPath:@"value" options:NSKeyValueObservingOptionInitial context:NULL],NSException,@"ObserverError");
    a.callback=nil; m.value=@"after"; XCTAssertEqual(a.count,1u);
    if(Has(@"KVO")) { XCTAssertNoThrow([m removeObserver:a forKeyPath:@"value"]); } else { XCTAssertThrows([m removeObserver:a forKeyPath:@"value"]); }
}
- (void)testKVOLifetimesAndUnobservedDestruction {
    XCTSkipUnless(Has(@"KVO"),@"KVO mode");
    __block NSUInteger destroyed=0; __weak Model *weakModel; __weak Observer *weakObserver;
    @autoreleasepool { Model *m=[Model new]; weakModel=m; Observer *a=[Observer new]; weakObserver=a;
        Sentinel *token=[Sentinel new]; token.onDealloc=^{destroyed++;}; objc_setAssociatedObject(m,@selector(testKVOLifetimesAndUnobservedDestruction),token,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [m addObserver:a forKeyPath:@"value" options:0 context:NULL];
    }
    XCTAssertNil(weakModel); XCTAssertNil(weakObserver); XCTAssertEqual(destroyed,1u);
    Model *m=[Model new]; @autoreleasepool { Observer *a=[Observer new]; weakObserver=a; [m addObserver:a forKeyPath:@"value" options:0 context:NULL]; }
    XCTAssertNil(weakObserver); XCTAssertNoThrow(m.value=@"safe");
    @autoreleasepool { Sentinel *token=[Sentinel new]; token.onDealloc=^{destroyed++;}; }
    XCTAssertEqual(destroyed,2u);
}
- (void)testKVORegistrationBeforeActivationCanBeRemoved {
    [preexistingModel removeObserver:preexistingObserver forKeyPath:@"value"];
    preexistingModel.value=@"after removal"; XCTAssertEqual(preexistingObserver.count,0u);
}
- (void)testKVONativeRegistrationReentryIsTracked {
    XCTSkipUnless(Has(@"KVO"),@"KVO mode");
    Model *nested=[Model new]; Observer *observer=[Observer new];
    registrationReentry=^{[nested addObserver:observer forKeyPath:@"value" options:0 context:NULL];};
    ReentrantModel *outer=[ReentrantModel new]; Observer *outerObserver=[Observer new];
    [outer addObserver:outerObserver forKeyPath:@"value" options:0 context:NULL];
    XCTAssertNil(registrationReentry);
    nested.value=@"before"; XCTAssertEqual(observer.count,1u); [nested removeObserver:observer forKeyPath:@"value"];
    nested.value=@"after"; XCTAssertEqual(observer.count,1u); [outer removeObserver:outerObserver forKeyPath:@"value"];
}
- (void)testKVOInitialSelfRemovalBeforeInstallation {
    XCTSkipUnless(Has(@"KVO") || [mode isEqual:@"Native"],@"KVO/native mode");
    Model *m=[Model new]; Observer *a=[Observer new];
    a.callback=^(NSString *path,id object,NSDictionary *change,void *context){[object removeObserver:a forKeyPath:path];};
    if(Has(@"KVO")) {
        XCTAssertNoThrow([m addObserver:a forKeyPath:@"value" options:NSKeyValueObservingOptionInitial context:NULL]);
        a.callback=nil; m.value=@"after"; XCTAssertEqual(a.count,2u); [m removeObserver:a forKeyPath:@"value"];
        XCTAssertEqual(reporter.errors.count,1u);
    } else {
        XCTAssertThrows([m addObserver:a forKeyPath:@"value" options:NSKeyValueObservingOptionInitial context:NULL]);
        a.callback=nil; m.value=@"after"; XCTAssertEqual(a.count,1u);
    }
}
- (void)testStartupHasNoUnavailableGuards {
    XCTAssertEqual(startupErrors.count,0u,@"%@",startupErrors);
}
- (void)testKVOFrameworkModelAndRegistrationRollback {
    XCTSkipUnless(Has(@"KVO"),@"KVO mode");
    FrameworkModel *frameworkModel=[FrameworkModel new]; Observer *a=[Observer new];
    [frameworkModel addObserver:a forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:NULL];
    frameworkModel.value=@"from framework"; XCTAssertEqual(a.count,1u); [frameworkModel removeObserver:a forKeyPath:@"value"];
    FailingRegistrationModel *model=[FailingRegistrationModel new]; failRegistration=YES;
    XCTAssertThrowsSpecificNamed([model addObserver:a forKeyPath:@"value" options:0 context:NULL],NSException,@"RegistrationError");
    failRegistration=NO;
    [model addObserver:a forKeyPath:@"value" options:0 context:NULL]; model.value=@"retry"; XCTAssertEqual(a.count,2u);
    [model removeObserver:a forKeyPath:@"value"]; model.value=@"removed"; XCTAssertEqual(a.count,2u);
}
- (void)testKVOObservedDiesBeforeLivingObserver {
    XCTSkipUnless(Has(@"KVO"),@"KVO mode");
    Observer *observer=[Observer new]; __weak Model *weakModel; __block NSUInteger destroyed=0;
    @autoreleasepool {
        Model *model=[Model new]; weakModel=model;
        Sentinel *sentinel=[Sentinel new]; sentinel.onDealloc=^{destroyed++;};
        objc_setAssociatedObject(model,@selector(testKVOObservedDiesBeforeLivingObserver),sentinel,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [model addObserver:observer forKeyPath:@"value" options:0 context:NULL]; model.value=@"once";
    }
    XCTAssertEqual(observer.count,1u); XCTAssertNil(weakModel); XCTAssertEqual(destroyed,1u);
}
- (void)testKVOInvalidArguments {
    XCTSkipUnless(Has(@"KVO"),@"KVO mode");
    Model *m=[Model new]; Observer *a=[Observer new];
    XCTAssertNoThrow([m addObserver:nil forKeyPath:@"value" options:0 context:NULL]);
    XCTAssertNoThrow([m addObserver:a forKeyPath:nil options:0 context:NULL]);
    XCTAssertNoThrow([m removeObserver:nil forKeyPath:@"value"]);
    XCTAssertNoThrow([m removeObserver:a forKeyPath:nil context:NULL]);
    XCTAssertEqual(reporter.errors.count,4u); m.value=@"no registration"; XCTAssertEqual(a.count,0u);
}
- (void)testKVOConcurrentRegistrations {
    XCTSkipUnless(Has(@"KVO"),@"KVO mode");
    Model *m=[Model new];
    dispatch_apply(50,dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^(size_t i){@autoreleasepool{Observer *a=[Observer new]; [m addObserver:a forKeyPath:@"value" options:0 context:NULL]; [m removeObserver:a forKeyPath:@"value"];}});
    XCTAssertNoThrow(m.value=@"done");
}
- (void)testUnknownTypedFallbackAndRejection {
    XCTSkipUnless(Has(@"Unknown"),@"Unknown mode");
    Missing *m=[Missing new];
    NSDictionary *types=@{@"missingObject":@"@@:",@"missingInteger":@"q@:",@"missingDouble":@"d@:",@"missingTriple":@"{TestTriple=ddd}@:"};
    for(NSString *name in types) XCTAssertTrue([MYSafeKit registerFallbackForClass:[Missing class] selector:NSSelectorFromString(name) typeEncoding:[types[name] UTF8String]]);
    XCTAssertNil(((id(*)(id,SEL))objc_msgSend)(m,NSSelectorFromString(@"missingObject")));
    XCTAssertEqual(((long long(*)(id,SEL))objc_msgSend)(m,NSSelectorFromString(@"missingInteger")),0);
    XCTAssertEqual(((double(*)(id,SEL))objc_msgSend)(m,NSSelectorFromString(@"missingDouble")),0.0);
    TestTriple value=[(id<MissingStructCall>)m missingTriple]; XCTAssertEqual(value.x,0.0); XCTAssertEqual(value.y,0.0); XCTAssertEqual(value.z,0.0);
    XCTAssertThrows(((void(*)(id,SEL))objc_msgSend)(m,NSSelectorFromString(@"notRegistered")));
    XCTAssertFalse([MYSafeKit registerFallbackForClass:[Missing class] selector:NSSelectorFromString(@"missingDouble") typeEncoding:"i@:"]);
    XCTAssertFalse([MYSafeKit registerFallbackForClass:[Missing class] selector:NSSelectorFromString(@"unionValue") typeEncoding:"(X=id)@:"]);
    XCTAssertFalse([MYSafeKit registerFallbackForClass:[Missing class] selector:NSSelectorFromString(@"bad") typeEncoding:"{bad"]);
    XCTAssertTrue([MYSafeKit registerFallbackForClass:object_getClass([Missing class]) selector:NSSelectorFromString(@"classDouble") typeEncoding:"d@:"]);
    XCTAssertEqual(((double(*)(id,SEL))objc_msgSend)([Missing class],NSSelectorFromString(@"classDouble")),0.0);
    XCTAssertThrows(((void(*)(id,SEL))objc_msgSend)(m,NSSelectorFromString(@"classDouble")));
}
- (void)testUnknownPreservesResolutionAndForwardingExceptions {
    XCTSkipUnless(Has(@"Unknown"),@"Unknown mode");
    XCTAssertEqual(((NSInteger(*)(id,SEL))objc_msgSend)([ResolveTarget new],NSSelectorFromString(@"resolvedValue")),91);
    Target *target=[Target new]; ForwardTarget *fast=[ForwardTarget new]; fast.target=target; InvocationTarget *full=[InvocationTarget new]; full.target=target;
    ((void(*)(id,SEL,id))objc_msgSend)(fast,@selector(tick:),nil); ((void(*)(id,SEL,id))objc_msgSend)(full,@selector(tick:),nil); XCTAssertEqual(target.count,2u);
    XCTAssertTrue([MYSafeKit registerFallbackForClass:[ThrowForward class] selector:NSSelectorFromString(@"throwing") typeEncoding:"v@:"]);
    XCTAssertThrowsSpecificNamed(((void(*)(id,SEL))objc_msgSend)([ThrowForward new],NSSelectorFromString(@"throwing")),NSException,@"ForwardError");
}
- (void)testNullEveryAllowedSelector {
    XCTSkipUnless(Has(@"Null"),@"Null mode");
    id null=[NSNull null];
    NSDictionary *sources=@{@"length":@"",@"count":@[],@"intValue":@0,@"integerValue":@0,@"longLongValue":@0,@"unsignedLongLongValue":@0,@"doubleValue":@0,@"floatValue":@0,@"boolValue":@0,@"objectForKey:":@{},@"objectForKeyedSubscript:":@{},@"objectAtIndex:":@[],@"objectAtIndexedSubscript:":@[],@"characterAtIndex:":@"",@"substringFromIndex:":@"",@"substringToIndex:":@"",@"substringWithRange:":@""};
    for(NSString *name in sources) {
        NSMethodSignature *signature=[sources[name] methodSignatureForSelector:NSSelectorFromString(name)];
        for (NSUInteger invalid = 0; invalid < 2; invalid++) {
        NSInvocation *invocation=[NSInvocation invocationWithMethodSignature:signature]; invocation.selector=NSSelectorFromString(name);
        if(signature.numberOfArguments>2) { NSRange argument=invalid ? NSMakeRange(NSUIntegerMax,2) : NSMakeRange(0,0); if ([signature getArgumentTypeAtIndex:2][0] == '@') { id key=invalid ? nil : @"key"; [invocation setArgument:&key atIndex:2]; } else [invocation setArgument:&argument atIndex:2]; }
        NSUInteger before=reporter.errors.count; XCTAssertNoThrow([invocation invokeWithTarget:null]);
        unsigned char result[32]; memset(result,0xff,sizeof(result)); [invocation getReturnValue:result];
        for(NSUInteger i=0;i<signature.methodReturnLength;i++) XCTAssertEqual(result[i],0);
        XCTAssertEqual(reporter.errors.count,before+1); XCTAssertEqual(reporter.errors.lastObject.code,-(NSInteger)MYSafeKitShieldTypeNull);
        }
    }
    XCTAssertThrows(((void(*)(id,SEL))objc_msgSend)(null,NSSelectorFromString(@"outsideWhitelist")));
}
- (void)testNotificationLifetimeAndConcurrentRegistration {
    XCTSkipUnless(Has(@"Notification"),@"Notification mode");
    Target *target=[Target new]; __weak NSNotificationCenter *weakCenter;
    @autoreleasepool { NSNotificationCenter *center=[NSNotificationCenter new]; weakCenter=center; [center addObserver:target selector:@selector(note:) name:@"event" object:nil]; [center postNotificationName:@"event" object:nil]; [center removeObserver:target]; }
    XCTAssertNil(weakCenter); XCTAssertEqual(target.count,1u);
    NSNotificationCenter *center=[NSNotificationCenter new];
    dispatch_apply(30,dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^(size_t i){ [center addObserver:target selector:@selector(note:) name:@"parallel" object:nil]; });
    [center postNotificationName:@"parallel" object:nil]; XCTAssertEqual(target.count,31u); [center removeObserver:target];
    __weak Target *weakTarget; @autoreleasepool {Target *shortLived=[Target new]; weakTarget=shortLived; [center addObserver:shortLived selector:@selector(note:) name:@"event" object:nil];} XCTAssertNil(weakTarget); XCTAssertNoThrow([center postNotificationName:@"event" object:nil]);
    __block NSUInteger calls=0; id token=[center addObserverForName:@"block" object:nil queue:nil usingBlock:^(NSNotification *n){calls++;}]; [center postNotificationName:@"block" object:nil]; [center removeObserver:token]; [center postNotificationName:@"block" object:nil]; XCTAssertEqual(calls,1u);
}
- (void)testTimerFactoriesAndTargetRelease {
    XCTSkipUnless(Has(@"Timer"),@"Timer mode");
    for(NSNumber *scheduled in @[@NO,@YES]) {
        Target *target=[Target new];
        NSTimer *timer=scheduled.boolValue ? [NSTimer scheduledTimerWithTimeInterval:100 target:target selector:@selector(tick:) userInfo:@"info" repeats:YES] : [NSTimer timerWithTimeInterval:100 target:target selector:@selector(tick:) userInfo:@"info" repeats:YES];
        [timer fire]; XCTAssertEqual(target.count,1u); XCTAssertEqual(target.lastTimer,timer); XCTAssertEqualObjects(target.lastInfo,@"info");
        __weak Target *weakTarget=target; target=nil; XCTAssertNil(weakTarget); [timer fire]; XCTAssertFalse(timer.valid);
    }
    __weak Target *weakSingle; NSTimer *single;
    @autoreleasepool { Target *target=[Target new]; weakSingle=target; single=[NSTimer timerWithTimeInterval:100 target:target selector:@selector(tick:) userInfo:nil repeats:NO]; }
    XCTAssertNotNil(weakSingle); [single invalidate]; single=nil;
}
- (void)testTimerDynamicForwarding {
    XCTSkipUnless(Has(@"Timer"),@"Timer mode");
    Target *target=[Target new]; ForwardTarget *fast=[ForwardTarget new]; fast.target=target; InvocationTarget *full=[InvocationTarget new]; full.target=target;
    for(id receiver in @[fast,full]) { NSTimer *timer=[NSTimer timerWithTimeInterval:100 target:receiver selector:@selector(tick:) userInfo:nil repeats:YES]; [timer fire]; [timer invalidate]; }
    XCTAssertEqual(target.count,2u);
}
- (void)testRecordReentryExceptionsAndConcurrency {
    XCTSkipUnless([mode isEqual:@"Record"] || [mode isEqual:@"All"] || [mode isEqual:@"Reverse"] || [mode isEqual:@"Concurrent"],@"Record mode");
    reporter.callback=^{[MYSafeKitRecord recordFatalWithReason:@"nested" errorType:MYSafeKitShieldTypeNull];};
    [MYSafeKitRecord recordFatalWithReason:@"outer" errorType:MYSafeKitShieldTypeContainer]; XCTAssertEqual(reporter.errors.count,1u);
    reporter.callback=^{[NSException raise:@"ReporterError" format:@"callback"];}; XCTAssertNoThrow([MYSafeKitRecord recordFatalWithReason:@"throw" errorType:MYSafeKitShieldTypeTimer]);
    reporter.callback=nil;
    dispatch_apply(100,dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^(size_t i){[MYSafeKit registerRecordHandler:reporter]; [MYSafeKitRecord recordFatalWithReason:nil errorType:MYSafeKitShieldTypeKVO];});
    XCTAssertEqual(reporter.errors.count,102u); XCTAssertTrue([reporter.errors.lastObject.userInfo[@"callStack"] count]<=32);
    [MYSafeKit registerRecordHandler:nil]; XCTAssertNoThrow([MYSafeKitRecord recordFatalWithReason:nil errorType:MYSafeKitShieldTypeNull]);
}
@end
