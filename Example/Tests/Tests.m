@import XCTest;
#import "../MYKit/SafeKitViewController.h"
#import "../MYKit/SafeKit/MYKVOViewController.h"
#import "../MYKit/SafeKit/MYTimerViewController.h"
#import "../MYKit/SafeKit/MYNotificationViewController.h"
#import "../MYKit/SafeKit/MYUnrecognizedSelectorViewController.h"
#import "../MYKit/SafeKit/MYUncaughtExceptionViewController.h"
#import <objc/message.h>

@interface MYKVOViewController (TestActions)
- (void)testKVO2;
@end
@interface MYNotificationViewController (TestActions)
- (void)sendNotification;
@end
@interface Tests : XCTestCase
@end
@implementation Tests
- (void)testApplicationLaunches {
    UIWindow *window = [UIApplication.sharedApplication.delegate window];
    XCTAssertNotNil(window.rootViewController);
    XCTAssertFalse(window.hidden);
}
- (void)testSafeKitMenuRoutesResolve {
    SafeKitViewController *controller = [SafeKitViewController new];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    [navigation loadViewIfNeeded];
    [controller loadViewIfNeeded];
    UITableView *table = [controller valueForKey:@"tableView"];
    XCTAssertNotNil(table);
    NSInteger count = [table.dataSource tableView:table numberOfRowsInSection:0];
    XCTAssertEqual(count, 6);
    for (NSInteger row=0; row<count; row++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
        UITableViewCell *cell = [table.dataSource tableView:table cellForRowAtIndexPath:path];
        NSString *className = [[cell.textLabel.text componentsSeparatedByString:@"-"] lastObject];
        XCTAssertTrue([NSClassFromString(className) isSubclassOfClass:UIViewController.class], @"Missing demo destination: %@", className);
        [table.delegate tableView:table didSelectRowAtIndexPath:path];
        XCTAssertTrue([navigation.topViewController isKindOfClass:NSClassFromString(className)]);
        [navigation.topViewController loadViewIfNeeded];
        [navigation popViewControllerAnimated:NO];
    }
}
- (void)testRegisteredFallbackAndUnregisteredFailure {
    MYUnrecognizedSelectorViewController *controller = [MYUnrecognizedSelectorViewController new];
    [controller loadViewIfNeeded];
    Class demo = NSClassFromString(@"MYFallbackDemo");
    XCTAssertNotNil(demo);
    id (*send)(id, SEL, id) = (id (*)(id, SEL, id))objc_msgSend;
    XCTAssertNil(send([demo new], NSSelectorFromString(@"demoValue:"), @"instance"));
    XCTAssertNil(send(demo, NSSelectorFromString(@"demoValue:"), @"class"));
    XCTAssertThrowsSpecificNamed(send([demo new], NSSelectorFromString(@"unregistered:"), nil), NSException, NSInvalidArgumentException);
}
- (void)testKVORepeatAndRelease {
    __weak MYKVOViewController *weakController;
    @autoreleasepool {
        MYKVOViewController *controller = [MYKVOViewController new];
        weakController = controller;
        [controller loadViewIfNeeded];
        [controller testKVO2];
        XCTAssertEqualObjects([controller valueForKey:@"observationCount"], @2);
        [controller testKVO2];
        XCTAssertEqualObjects([controller valueForKey:@"observationCount"], @4);
    }
    XCTAssertNil(weakController);
}
- (void)testTimerFiresAndReleasesTarget {
    __weak MYTimerViewController *weakController;
    NSTimer *timer;
    @autoreleasepool {
        MYTimerViewController *controller = [MYTimerViewController new];
        weakController = controller;
        [controller loadViewIfNeeded];
        timer = [controller valueForKey:@"timer"];
        XCTAssertTrue(timer.valid);
        [timer fire];
        XCTAssertEqualObjects([controller valueForKey:@"tickCount"], @1);
    }
    XCTAssertNil(weakController);
    [timer fire];
    XCTAssertFalse(timer.valid);
}
- (void)testNotificationDeliveryAndRelease {
    __weak MYNotificationViewController *weakController;
    @autoreleasepool {
        MYNotificationViewController *controller = [MYNotificationViewController new];
        weakController = controller;
        [controller loadViewIfNeeded];
        [controller sendNotification];
        XCTAssertEqualObjects([controller valueForKey:@"notificationCount"], @1);
    }
    XCTAssertNil(weakController);
    XCTAssertNoThrow([[NSNotificationCenter defaultCenter] postNotificationName:@"TestNotification" object:nil]);
}
- (void)testCoveragePageContainsExplanationWithoutCrashButton {
    MYUncaughtExceptionViewController *controller = [MYUncaughtExceptionViewController new];
    [controller loadViewIfNeeded];
    UILabel *explanation;
    for (UIView *view in controller.view.subviews) {
        XCTAssertFalse([view isKindOfClass:UIButton.class]);
        if ([view.accessibilityIdentifier isEqual:@"coverage.explanation"]) explanation = (id)view;
    }
    XCTAssertTrue([explanation.text containsString:@"非法指针"]);
}
- (void)testRenderKeyPages {
    UIWindow *window = [UIApplication.sharedApplication.delegate window];
    UIViewController *original = window.rootViewController;
    NSArray *classes = @[SafeKitViewController.class, MYUnrecognizedSelectorViewController.class, MYKVOViewController.class, MYTimerViewController.class, MYNotificationViewController.class, MYUncaughtExceptionViewController.class];
    BOOL animationsEnabled = UIView.areAnimationsEnabled;
    [UIView setAnimationsEnabled:NO];
    @try {
        for (Class cls in classes) {
            UIViewController *controller = [cls new];
            controller.title = NSStringFromClass(cls);
            window.rootViewController = [[UINavigationController alloc] initWithRootViewController:controller];
            [window layoutIfNeeded];
            [controller loadViewIfNeeded];
            if ([controller isKindOfClass:MYKVOViewController.class]) [(MYKVOViewController *)controller testKVO2];
            if ([controller isKindOfClass:MYNotificationViewController.class]) [(MYNotificationViewController *)controller sendNotification];
            [window layoutIfNeeded];
            UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithBounds:window.bounds];
            UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
                [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
            }];
            XCTAssertGreaterThan(image.size.width, 0);
            XCTAttachment *attachment = [XCTAttachment attachmentWithImage:image];
            attachment.name = NSStringFromClass(cls);
            attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
            [self addAttachment:attachment];
        }
    } @finally {
        window.rootViewController = original;
        [UIView setAnimationsEnabled:animationsEnabled];
    }
}
@end
