#import "MYUncaughtExceptionViewController.h"

@implementation MYUncaughtExceptionViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    UILabel *label = [UILabel new];
    label.numberOfLines = 0;
    label.accessibilityIdentifier = @"coverage.explanation";
    label.text = @"防护边界\n\nSafeKit 不恢复任意信号、非法指针或内存破坏。未捕获异常记录仅用于诊断，不能保证进程继续运行。\n\n本页不执行破坏性内存操作。";
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:24],
        [label.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-24],
        [label.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24]]];
}
@end
