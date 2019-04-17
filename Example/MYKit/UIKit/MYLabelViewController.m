//
//  MYLabelViewController.m
//  MYKitDemo
//
//  Created by QMMac on 2018/7/20.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import "MYLabelViewController.h"
#import "MYKitMacroHeader.h"
#import "UILabel+AutomaticWriting.h"
#import "UILabel+LineSpacing.h"
#import "UILabel+CountDown.h"

@interface MYLabelViewController ()

@property (nonatomic, strong) UILabel *limitLabel;
@property (nonatomic, strong) UILabel *testLabel;
@property (nonatomic, strong) UILabel *writingLabel;
@property (nonatomic, strong) UIButton *automaticWritingButton;

@end

@implementation MYLabelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [UILabel registerLineSpacingSelector];

    // 文本限制指定的行数
    [self limitText];
    
    // 设置行间距
    [self setupLineSpace];
  
    // 自动书写
    [self automaticWriting];
    
    // 倒计时
    [self countDown];
}

- (void)limitText {
    UILabel *limitLabel = [[UILabel alloc] init];
    limitLabel.frame = CGRectMake(10, 64, MYScreenWidth - 20, 100);
    limitLabel.font = [UIFont systemFontOfSize:14.0f];
    limitLabel.text = @"文本限制指定的行数文本限制指定的行数文本限制指定的行数文本限制指定的行数文本限制指定的行数文本限制指定的行数文本限制指定的行数文本限制指定的行数文本限制指定的行数";
    limitLabel.numberOfLines = 0.0f;
    limitLabel.lineSpace = 10.0f;
    limitLabel.numberOfLines = 2.0f;
    [self.view addSubview:limitLabel];
    _limitLabel = limitLabel;
}

- (void)setupLineSpace {
    UILabel *testLabel = [[UILabel alloc] init];
    testLabel.frame = CGRectMake(10, CGRectGetMaxY(self.limitLabel.frame) + 20, MYScreenWidth - 20, 100);
    testLabel.font = [UIFont systemFontOfSize:14.0f];
    testLabel.text = @"设置行间距设置行间距设置行间距设置行间距设置行间距设置行间距设置行间距设置行间距设置行间距设置行间距设置行间距设置行间距设置行间距设置行间距设置行间距设置行间距";
    testLabel.numberOfLines = 2.0f;
    testLabel.lineSpace = 15.0f;
    [self.view addSubview:testLabel];
    _testLabel = testLabel;
}

- (void)automaticWriting {
    
    UILabel *writingLabel = [[UILabel alloc] init];
    writingLabel.frame = CGRectMake(10, CGRectGetMaxY(self.testLabel.frame) + 20, MYScreenWidth - 20, 100);
    writingLabel.backgroundColor = [UIColor redColor];
    writingLabel.font = [UIFont systemFontOfSize:14.0f];
    writingLabel.textAlignment = NSTextAlignmentCenter;
    writingLabel.textColor = [UIColor blueColor];
    [self.view addSubview:writingLabel];
    _writingLabel = writingLabel;
    
    UIButton *automaticWritingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    automaticWritingButton.frame = CGRectMake((MYScreenWidth - 150)/2, CGRectGetMaxY(writingLabel.frame) + 20, 150, 50);
    [automaticWritingButton setTitle:@"automaticWriting" forState:UIControlStateNormal];
    [automaticWritingButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [automaticWritingButton addTarget:self action:@selector(automaticWriting:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:automaticWritingButton];
    _automaticWritingButton = automaticWritingButton;
}

- (void)automaticWriting:(UIButton *)sender {
    
    [self.writingLabel setText:@"测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试" automaticWritingAnimationWithBlinkingMode:UILabelAWBlinkingModeWhenFinishShowing];
}

/**
 倒计时
 */
- (void)countDown {
    
    UILabel *countDownLabel = [[UILabel alloc] init];
    countDownLabel.frame = CGRectMake((MYScreenWidth - 100)/2, CGRectGetMaxY(self.automaticWritingButton.frame) + 20, 100, 50);
    countDownLabel.backgroundColor = [UIColor orangeColor];
    countDownLabel.font = [UIFont systemFontOfSize:14.0f];
    countDownLabel.textAlignment = NSTextAlignmentCenter;
    [countDownLabel scheduledTimerWithTimeInterval:10 countDownText:@"开始倒计时" completion:^(UILabel *countDownLabel) {
        countDownLabel.text = @"倒计时结束";
    }];
    [self.view addSubview:countDownLabel];
}

@end
