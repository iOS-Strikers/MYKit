//
//  MYTextFieldViewController.m
//  MYKitDemo
//
//  Created by sunjinshuai on 2018/7/17.
//  Copyright © 2018年 com.51fanxing. All rights reserved.
//

#import "MYTextFieldViewController.h"
#import "MYKitMacroHeader.h"
#import "UITextField+Shake.h"
#import "UITextField+InputLimit.h"

@interface MYTextFieldViewController ()<UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;

@end

@implementation MYTextFieldViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITextField *textField = [[UITextField alloc] init];
    textField.frame = CGRectMake((MYScreenWidth - 100)/2, 150, 100, 50);
    textField.delegate = self;
    textField.maxLength = 10;
    [textField.layer setBorderWidth:2];
    [textField.layer setBorderColor:[UIColor grayColor].CGColor];
    [self.view addSubview:textField];
    _textField = textField;
    
    UIButton *shakeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    shakeButton.frame = CGRectMake((MYScreenWidth - 150)/2, CGRectGetMaxY(textField.frame) + 50, 150, 50);
    [shakeButton setTitle:@"showShakeTextField" forState:UIControlStateNormal];
    [shakeButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [shakeButton addTarget:self action:@selector(actionShake:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shakeButton];
}

- (IBAction)actionShake:(id)sender {
    
    [self.textField shake];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger length = textField.text.length + string.length;
    
    if (length > 10 && !(length == 1 && [string isEqualToString:@""])) {
        [self.textField shake];
        return NO;
    } else {
        return YES;
    }
    
    return YES;
}

@end
