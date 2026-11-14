#import <XCTest/XCTest.h>
#import <AVFoundation/AVFoundation.h>
#import <EventKit/EventKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Contacts/Contacts.h>
#import <objc/runtime.h>
#import "UIApplication+Authority.h"
#import "UIButton+Indicator.h"

#import "NSArray+Addition.h"
#import "NSDictionary+Addition.h"
#import "UIImage+Color.h"
#import "UIImage+Addition.h"
#import "UIApplication+NetworkActivityIndicator.h"
#import "UIButton+Submitting.h"
#import "UINavigationItem+Loading.h"
#import "UIScreen+Addition.h"
#import "UIViewController+TopViewController.h"
#import "UIViewController+ClassName.h"
#import "MYWindowContextInternal.h"

@interface FixtureWindow : UIWindow
@property BOOL fixtureKey;
@end
@implementation FixtureWindow
- (BOOL)isKeyWindow { return self.fixtureKey; }
@end
// Candidate fixtures exercise the selection policy, not actual scene lifecycle.
@interface FixtureScene : NSObject
@property UISceneActivationState activationState;
@property NSArray<UIWindow *> *windows;
@end
@implementation FixtureScene
- (BOOL)isKindOfClass:(Class)cls { return cls == UIWindowScene.class || [super isKindOfClass:cls]; }
@end
@interface FixtureDelegate : NSObject <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end
@implementation FixtureDelegate
@end

@interface UIViewController (ClassNameTesting)
+ (void)displayClassNameInWindow:(UIWindow *)window;
@end


@interface LegacyFixtureWindow : UIWindow
@end
@implementation LegacyFixtureWindow
- (UIWindowScene *)windowScene { return nil; }
@end

@interface UtilitiesTests : XCTestCase
@end
@implementation UtilitiesTests
- (void)testCameraPermissionUsesVideoAuthorization {
    Method camera = class_getClassMethod(AVCaptureDevice.class, @selector(authorizationStatusForMediaType:));
    Method calendar = class_getClassMethod(EKEventStore.class, @selector(authorizationStatusForEntityType:));
    __block NSUInteger cameraCalls = 0, calendarCalls = 0;
    IMP fakeCamera = imp_implementationWithBlock(^AVAuthorizationStatus(id cls, NSString *type) {
        cameraCalls++; XCTAssertEqualObjects(type, AVMediaTypeVideo); return AVAuthorizationStatusAuthorized;
    });
    IMP fakeCalendar = imp_implementationWithBlock(^EKAuthorizationStatus(id cls, EKEntityType type) {
        calendarCalls++; return EKAuthorizationStatusDenied;
    });
    IMP originalCamera = method_setImplementation(camera, fakeCamera);
    IMP originalCalendar = method_setImplementation(calendar, fakeCalendar);
    @try {
        XCTAssertTrue([UIApplication getApplicationCameraPermit]);
        XCTAssertEqual(cameraCalls, 1u); XCTAssertEqual(calendarCalls, 0u);
    } @finally {
        method_setImplementation(camera, originalCamera); method_setImplementation(calendar, originalCalendar);
        imp_removeBlock(fakeCamera); imp_removeBlock(fakeCalendar);
    }
}
- (void)testButtonIndicatorUsesModernStyleAndRestoresState {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 120, 44);
    [button setTitle:@"Send" forState:UIControlStateNormal];
    [button layoutIfNeeded]; [button showIndicator];
    UIActivityIndicatorView *indicator;
    for (UIView *view in button.subviews) if ([view isKindOfClass:UIActivityIndicatorView.class]) indicator = (id)view;
    XCTAssertNotNil(indicator); XCTAssertEqual(indicator.activityIndicatorViewStyle, UIActivityIndicatorViewStyleMedium);
    XCTAssertEqualObjects(indicator.color, UIColor.whiteColor); XCTAssertTrue(indicator.isAnimating);
    XCTAssertFalse(button.enabled); [button hideIndicator];
    XCTAssertTrue(button.enabled); XCTAssertEqualObjects([button titleForState:UIControlStateNormal], @"Send");
    XCTAssertNil(indicator.superview);
}

- (void)testPlistNilInvalidAndRoundTrips {
    XCTAssertNil([NSArray arrayWithPlistData:nil]); XCTAssertNil([NSArray arrayWithPlistString:nil]);
    XCTAssertNil([NSDictionary dictionaryWithPlistData:nil]); XCTAssertNil([NSDictionary dictionaryWithPlistString:nil]);
    XCTAssertNil([NSArray arrayWithPlistString:@"bad"]); XCTAssertNil([NSDictionary dictionaryWithPlistString:@"bad"]);
    NSArray *array = @[@"one", @2]; NSDictionary *dict = @{@"one": @2};
    XCTAssertEqualObjects([NSArray arrayWithPlistData:array.plistData], array);
    XCTAssertEqualObjects([NSArray arrayWithPlistString:array.plistString], array);
    XCTAssertEqualObjects([NSDictionary dictionaryWithPlistData:dict.plistData], dict);
    XCTAssertEqualObjects([NSDictionary dictionaryWithPlistString:dict.plistString], dict);
    XCTAssertNil([NSArray arrayWithPlistData:dict.plistData]); XCTAssertNil([NSDictionary dictionaryWithPlistData:array.plistData]);
    XCTAssertFalse([dict containsObjectForKey:nil]); XCTAssertEqualObjects([dict entriesForKeys:nil], @{});
    XCTAssertEqualObjects(([dict entriesForKeys:@[@"one", @"missing"]]), dict);
}
- (void)testBitmapColorAndGrayConversion {
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 1;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(4,4) format:format];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [UIColor.redColor setFill]; [ctx fillRect:CGRectMake(0,0,4,4)];
    }];
    XCTAssertNotNil(image); CGFloat r,g,b,a;
    XCTAssertTrue([[image colorAtPoint:CGPointZero] getRed:&r green:&g blue:&b alpha:&a]);
    XCTAssertEqualWithAccuracy(r, 1, 0.01); XCTAssertEqualWithAccuracy(g, 0, 0.01); XCTAssertEqualWithAccuracy(b, 0, 0.01);
    XCTAssertTrue([[image colorAtPixel:CGPointMake(1,1)] getRed:&r green:&g blue:&b alpha:&a]);
    XCTAssertEqualWithAccuracy(r, 1, 0.01); XCTAssertEqualWithAccuracy(a, 1, 0.01);
    UIImage *gray = [UIImage covertToGrayImageFromImage:image]; XCTAssertNotNil(gray);
    XCTAssertEqual(CGImageGetWidth(gray.CGImage), CGImageGetWidth(image.CGImage));
    XCTAssertEqual(CGImageGetColorSpace(gray.CGImage) ? CGColorSpaceGetModel(CGImageGetColorSpace(gray.CGImage)) : -1, kCGColorSpaceModelMonochrome);
}
- (void)testWindowSelectionPolicy {
    FixtureDelegate *delegate = [FixtureDelegate new];
    FixtureWindow *first = [[FixtureWindow alloc] initWithFrame:CGRectMake(0,0,320,480)];
    first.fixtureKey = YES; first.hidden = NO;
    delegate.window = first;
    XCTAssertEqual(MYWindowForApplication([NSSet set], delegate), first);
    XCTAssertNil(MYWindowForApplication([NSSet set], (id)[NSObject new]));
    FixtureScene *scene = [FixtureScene new]; scene.activationState = UISceneActivationStateForegroundActive; scene.windows = @[first];
    NSSet *scenes = [NSSet setWithObject:scene];
    XCTAssertEqual(MYWindowForApplication((id)scenes, delegate), first);
    first.hidden = YES; XCTAssertNil(MYWindowForApplication((id)scenes, delegate)); first.hidden = NO;
    first.alpha = 0; XCTAssertNil(MYWindowForApplication((id)scenes, delegate)); first.alpha = 1;
    first.windowLevel = UIWindowLevelAlert; XCTAssertNil(MYWindowForApplication((id)scenes, delegate)); first.windowLevel = UIWindowLevelNormal;
    first.fixtureKey = NO; XCTAssertNil(MYWindowForApplication((id)scenes, delegate)); first.fixtureKey = YES;
    scene.activationState = UISceneActivationStateBackground; XCTAssertNil(MYWindowForApplication((id)scenes, delegate));
    scene.activationState = UISceneActivationStateForegroundActive;
    FixtureWindow *second = [[FixtureWindow alloc] initWithFrame:first.frame]; second.fixtureKey = YES; second.hidden = NO;
    FixtureScene *other = [FixtureScene new]; other.activationState = UISceneActivationStateForegroundActive; other.windows = @[second];
    XCTAssertNil(MYWindowForApplication((id)[NSSet setWithArray:@[scene,other]], delegate));
    XCTAssertNil(MYWindowForApplication((id)[NSSet setWithArray:@[other,scene]], delegate));
    first.hidden = YES; second.hidden = YES;
}
- (void)testSceneWindowIntegrationAndClassLabelCleanup {
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    XCTAssertNotNil(window); XCTAssertNotNil(window.windowScene);
    XCTAssertEqual(MYCurrentApplicationWindow(), window);
    XCTAssertEqual([UIViewController topViewController], window.rootViewController);
    XCTAssertEqualWithAccuracy([UIScreen statusBarHeight], window.windowScene.statusBarManager.statusBarFrame.size.height, 0.01);
    UILabel *unrelated = [UILabel new]; unrelated.tag = 20000; [window addSubview:unrelated];
    [UIViewController displayClassName:YES]; [UIViewController displayClassName:NO];
    XCTAssertEqual(unrelated.superview, window); [unrelated removeFromSuperview];
}
- (void)testNetworkBalancedAndConcurrentState {
    UIApplication *application = UIApplication.sharedApplication;
    Method setter = class_getInstanceMethod(UIApplication.class, @selector(setNetworkActivityIndicatorVisible:));
    __block BOOL visible = NO;
    IMP replacement = imp_implementationWithBlock(^(id self, BOOL value) {
        // Force overlapping callers in an unsynchronized implementation.
        if (value) [NSThread sleepForTimeInterval:0.0001];
        @synchronized (application) { visible = value; }
    });
    IMP original = method_setImplementation(setter, replacement);
    @try {
        [application beganNetworkActivity]; XCTAssertTrue(visible);
        [application beganNetworkActivity]; [application endedNetworkActivity]; XCTAssertTrue(visible);
        [application endedNetworkActivity]; XCTAssertFalse(visible);
        dispatch_apply(100, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^(size_t i) {
            [application beganNetworkActivity]; [application endedNetworkActivity];
        });
        XCTAssertFalse(visible);
        [application beganNetworkActivity]; XCTAssertTrue(visible); [application endedNetworkActivity]; XCTAssertFalse(visible);
    } @finally { method_setImplementation(setter, original); imp_removeBlock(replacement); }
}
- (void)testLoadingViewsAndVisualEvidence {
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    UIView *canvas = [[UIView alloc] initWithFrame:window.bounds]; canvas.backgroundColor = UIColor.systemBackgroundColor;
    [window.rootViewController.view addSubview:canvas];
    UIButton *indicatorButton = [UIButton buttonWithType:UIButtonTypeCustom];
    indicatorButton.frame = CGRectMake(30,100,160,48); indicatorButton.backgroundColor = UIColor.systemBlueColor;
    [indicatorButton setTitle:@"Send" forState:UIControlStateNormal]; [canvas addSubview:indicatorButton];
    [indicatorButton layoutIfNeeded]; [indicatorButton showIndicator];
    UIButton *submitting = [UIButton buttonWithType:UIButtonTypeCustom];
    submitting.frame = CGRectMake(30,180,260,48); submitting.backgroundColor = UIColor.systemBlueColor;
    [submitting setTitle:@"Submit" forState:UIControlStateNormal]; [canvas addSubview:submitting];
    [submitting layoutIfNeeded]; [submitting beginSubmitting:@"Submitting"];
    XCTAssertTrue(submitting.hidden); XCTAssertTrue(submitting.isSubmitting);
    UINavigationBar *bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0,280,canvas.bounds.size.width,44)];
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@"Loading"];
    UILabel *saved = [UILabel new]; saved.text = @"Ready"; item.titleView = saved; [bar setItems:@[item]]; [canvas addSubview:bar];
    [item startAnimatingAt:ANNavBarLoaderPositionCenter];
    UIActivityIndicatorView *loader = (id)item.titleView;
    XCTAssertEqual(loader.activityIndicatorViewStyle, UIActivityIndicatorViewStyleMedium);
    XCTAssertEqualObjects(loader.color, UIColor.grayColor); XCTAssertTrue(loader.isAnimating);
    for (UIView *view in canvas.subviews) for (UIView *child in view.subviews) {
        if ([child isKindOfClass:UIActivityIndicatorView.class]) {
            XCTAssertEqual(((UIActivityIndicatorView *)child).activityIndicatorViewStyle, UIActivityIndicatorViewStyleMedium);
            XCTAssertEqualObjects(((UIActivityIndicatorView *)child).color, UIColor.whiteColor);
        }
    }
    for (NSNumber *style in @[@(UIUserInterfaceStyleLight), @(UIUserInterfaceStyleDark)]) {
        canvas.overrideUserInterfaceStyle = style.integerValue; [canvas layoutIfNeeded];
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithBounds:canvas.bounds];
        UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) { [canvas drawViewHierarchyInRect:canvas.bounds afterScreenUpdates:YES]; }];
        XCTAttachment *attachment = [XCTAttachment attachmentWithImage:image]; attachment.name = [@"loading-" stringByAppendingString:style.stringValue]; attachment.lifetime = XCTAttachmentLifetimeKeepAlways; [self addAttachment:attachment];
    }
    [item stopAnimating]; XCTAssertEqual(item.titleView, saved);
    [submitting endSubmitting]; XCTAssertFalse(submitting.hidden); XCTAssertFalse(submitting.isSubmitting);
    [indicatorButton hideIndicator]; [canvas removeFromSuperview];
}

- (void)testClassNameCleanupAfterSceneDisconnect {
    UIWindow *detached = [[UIWindow alloc] initWithFrame:CGRectMake(0,0,300,500)];
    Method scenes = class_getInstanceMethod(UIApplication.class, @selector(connectedScenes));
    IMP replacement = imp_implementationWithBlock(^NSSet *(id app) { return [NSSet set]; });
    IMP original = method_setImplementation(scenes, replacement);
    @try {
        [UIViewController displayClassNameInWindow:detached];
        XCTAssertNotNil([detached viewWithTag:20000]);
        [UIViewController displayClassName:NO];
        XCTAssertNil([detached viewWithTag:20000]);
    } @finally { method_setImplementation(scenes, original); imp_removeBlock(replacement); }
}

- (void)testLegacyStatusBarFallbackMatchesNative {
    UIApplication *application = UIApplication.sharedApplication;
    CGFloat nativeHeight = application.statusBarFrame.size.height;
    FixtureDelegate *delegate = [FixtureDelegate new]; delegate.window = [[LegacyFixtureWindow alloc] initWithFrame:CGRectZero];
    Method scenes = class_getInstanceMethod(UIApplication.class, @selector(connectedScenes));
    Method delegateGetter = class_getInstanceMethod(UIApplication.class, @selector(delegate));
    IMP noScenes = imp_implementationWithBlock(^NSSet *(id app) { return [NSSet set]; });
    IMP legacyDelegate = imp_implementationWithBlock(^id(id app) { return delegate; });
    IMP originalScenes = method_setImplementation(scenes, noScenes);
    IMP originalDelegate = method_setImplementation(delegateGetter, legacyDelegate);
    @try {
        XCTAssertEqual(MYCurrentApplicationWindow(), delegate.window);
        XCTAssertEqualWithAccuracy([UIScreen statusBarHeight], nativeHeight, 0.01);
    } @finally {
        method_setImplementation(scenes, originalScenes); method_setImplementation(delegateGetter, originalDelegate);
        imp_removeBlock(noScenes); imp_removeBlock(legacyDelegate);
    }
}
- (void)testNetworkNativeGetterParity {
    UIApplication *application = UIApplication.sharedApplication;
    BOOL saved = application.networkActivityIndicatorVisible;
    application.networkActivityIndicatorVisible = YES;
    BOOL nativeYes = application.networkActivityIndicatorVisible;
    application.networkActivityIndicatorVisible = NO;
    BOOL nativeNo = application.networkActivityIndicatorVisible;
    @try {
        [application beganNetworkActivity]; XCTAssertEqual(application.networkActivityIndicatorVisible, nativeYes);
        [application beganNetworkActivity]; [application endedNetworkActivity]; XCTAssertEqual(application.networkActivityIndicatorVisible, nativeYes);
        [application endedNetworkActivity]; XCTAssertEqual(application.networkActivityIndicatorVisible, nativeNo);
    } @finally { application.networkActivityIndicatorVisible = saved; }
}
- (void)testLocationAndContactsPermissionQueries {
    Method instance = class_getInstanceMethod(CLLocationManager.class, @selector(authorizationStatus));
    Method contacts = class_getClassMethod(CNContactStore.class, @selector(authorizationStatusForEntityType:));
    __block CLAuthorizationStatus locationStatus = kCLAuthorizationStatusDenied;
    __block CNAuthorizationStatus contactsStatus = CNAuthorizationStatusDenied;
    __block NSUInteger locationCalls = 0, contactCalls = 0;
    IMP locationIMP = imp_implementationWithBlock(^CLAuthorizationStatus(id manager) { locationCalls++; return locationStatus; });
    IMP contactsIMP = imp_implementationWithBlock(^CNAuthorizationStatus(id cls, CNEntityType type) { contactCalls++; XCTAssertEqual(type, CNEntityTypeContacts); return contactsStatus; });
    IMP originalLocation = method_setImplementation(instance, locationIMP);
    IMP originalContacts = method_setImplementation(contacts, contactsIMP);
    @try {
        XCTAssertFalse([UIApplication getApplicationLocationPermit]);
        locationStatus = kCLAuthorizationStatusAuthorizedWhenInUse; XCTAssertTrue([UIApplication getApplicationLocationPermit]);
        locationStatus = kCLAuthorizationStatusAuthorizedAlways; XCTAssertTrue([UIApplication getApplicationLocationPermit]);
        locationStatus = kCLAuthorizationStatusNotDetermined; XCTAssertFalse([UIApplication getApplicationLocationPermit]);
        XCTAssertEqual(locationCalls, 4u);
        XCTAssertFalse([UIApplication getApplicationAddressBookPermit]);
        contactsStatus = CNAuthorizationStatusAuthorized; XCTAssertTrue([UIApplication getApplicationAddressBookPermit]);
        XCTAssertEqual(contactCalls, 2u);
    } @finally {
        method_setImplementation(instance, originalLocation); method_setImplementation(contacts, originalContacts);
        imp_removeBlock(locationIMP); imp_removeBlock(contactsIMP);
    }
}
@end
