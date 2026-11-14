#import "MYUnrecognizedSelectorViewController.h"
#import "MYSafeKit.h"
#import <objc/message.h>
#import <objc/runtime.h>

// A dedicated class keeps fallback registration away from UIKit classes.
@interface MYFallbackDemo : NSObject
@end
@implementation MYFallbackDemo
@end

@implementation MYUnrecognizedSelectorViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    SEL selector = NSSelectorFromString(@"demoValue:");
    BOOL instanceRegistered = [MYSafeKit registerFallbackForClass:MYFallbackDemo.class selector:selector typeEncoding:"@@:@"];
    BOOL classRegistered = [MYSafeKit registerFallbackForClass:object_getClass(MYFallbackDemo.class) selector:selector typeEncoding:"@@:@"];
    id instanceResult = nil;
    id classResult = nil;
    if (instanceRegistered && classRegistered) {
        id (*send)(id, SEL, id) = (id (*)(id, SEL, id))objc_msgSend;
        instanceResult = send([MYFallbackDemo new], selector, @"instance");
        classResult = send(MYFallbackDemo.class, selector, @"class");
    }
    UILabel *label = [UILabel new];
    label.numberOfLines = 0;
    label.accessibilityIdentifier = @"fallback.result";
    label.text = (instanceRegistered && classRegistered && !instanceResult && !classResult)
        ? @"实例方法与类方法均已登记精确签名，兜底返回 nil。未登记的方法仍会抛出异常。"
        : @"签名登记或调用失败，请查看控制台。";
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:24],
        [label.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-24],
        [label.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24]]];
}
@end
