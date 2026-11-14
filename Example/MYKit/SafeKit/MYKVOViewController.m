#import "MYKVOViewController.h"
#import "NSObject+SafeKVO.h"

static void *MYDemoKVOContext = &MYDemoKVOContext;
@interface MYKVOViewController ()
@property (nonatomic) NSInteger demoValue;
@property (nonatomic) NSUInteger observationCount;
@property (nonatomic, strong) UIButton *demoButton;
@end

@implementation MYKVOViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.demoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.demoButton.frame = CGRectMake(24, 120, 320, 60);
    self.demoButton.accessibilityIdentifier = @"kvo.run";
    [self.demoButton setTitle:@"执行重复添加与移除" forState:UIControlStateNormal];
    [self.demoButton addTarget:self action:@selector(testKVO2) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.demoButton];
}
- (void)testKVO2 {
    [self addObserver:self forKeyPath:@"demoValue" options:NSKeyValueObservingOptionNew context:MYDemoKVOContext];
    [self addObserver:self forKeyPath:@"demoValue" options:NSKeyValueObservingOptionNew context:MYDemoKVOContext];
    self.demoValue += 1;
    [self removeObserver:self forKeyPath:@"demoValue" context:MYDemoKVOContext];
    [self removeObserver:self forKeyPath:@"demoValue" context:MYDemoKVOContext];
    // Two registrations preserve native delivery counts; the third removal is guarded.
    [self removeObserver:self forKeyPath:@"demoValue" context:MYDemoKVOContext];
    self.demoValue += 1;
    [self.demoButton setTitle:[NSString stringWithFormat:@"已收到 %lu 次通知，多余移除已防护", (unsigned long)self.observationCount] forState:UIControlStateNormal];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == MYDemoKVOContext) {
        self.observationCount += 1;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end
