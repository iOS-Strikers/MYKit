//
//  MYButtonViewController.m
//  MYKitDemo
//
//  Created by QMMac on 2018/7/20.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import "MYButtonViewController.h"
#import "MYKitMacroHeader.h"
#import "UIButton+CountDown.h"
#import "UIButton+Indicator.h"

@interface MYButtonViewController ()

@end

@implementation MYButtonViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 倒计时
    [self countDown];
}

- (void)countDown {
    UIButton *countDownButton = [UIButton buttonWithType:UIButtonTypeCustom];
    countDownButton.backgroundColor = [UIColor orangeColor];
    countDownButton.frame = CGRectMake((MYScreenWidth - 150)/2, 84, 150, 50);
    [countDownButton setTitle:@"automaticWriting" forState:UIControlStateNormal];
    [countDownButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [countDownButton addTarget:self action:@selector(countDown:) forControlEvents:UIControlEventTouchUpInside];
    [countDownButton showIndicator];
    [countDownButton scheduledTimerWithTimeInterval:10.0f countDownText:@"开始倒计时" completion:^(UIButton *countDownButton) {
        [countDownButton setTitle:@"倒计时完毕" forState:UIControlStateNormal];
        [countDownButton hideIndicator];
    }];
    [self.view addSubview:countDownButton];
}

- (void)countDown:(UIButton *)sender {
    
}

@end
