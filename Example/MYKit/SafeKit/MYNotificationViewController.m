#import "MYNotificationViewController.h"

@interface MYNotificationViewController ()
@property (nonatomic) NSUInteger notificationCount;
@property (nonatomic, strong) UIButton *demoButton;
@end
@implementation MYNotificationViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(testNotification:) name:@"TestNotification" object:nil];
    self.demoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.demoButton.frame = CGRectMake(24, 120, 320, 60);
    self.demoButton.accessibilityIdentifier = @"notification.send";
    [self.demoButton setTitle:@"发送通知" forState:UIControlStateNormal];
    [self.demoButton addTarget:self action:@selector(sendNotification) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.demoButton];
}
- (void)sendNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TestNotification" object:self];
}
- (void)testNotification:(NSNotification *)notification {
    self.notificationCount += 1;
    [self.demoButton setTitle:[NSString stringWithFormat:@"已收到 %lu 次通知", (unsigned long)self.notificationCount] forState:UIControlStateNormal];
}
// Selector observers are removed by SafeKit when the target is deallocated.
@end
