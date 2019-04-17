//
//  MYTextViewController.m
//  MYKitDemo
//
//  Created by QMMac on 2018/8/1.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import "MYTextViewController.h"

@interface MYTextViewController ()

@end

@implementation MYTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITextView *textView = [[UITextView alloc] init];
    textView.frame = CGRectMake(50, 120, 200, 300);
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    textView.placeholder = @"Are you sure you don\'t want to reconsider? Could you tell us why you wish to leave StyleShare? Your opinion helps us improve StyleShare into a better place for fashionistas from all around the world. We are always listening to our users. Help us improve!";
//    NSDictionary *attrs = @ {
//    NSFontAttributeName: [UIFont boldSystemFontOfSize:20],
//    };
//    textView.attributedText = [[NSAttributedString alloc] initWithString:@"Hi" attributes:attrs];
//    textView.font = [UIFont systemFontOfSize:15];
//    textView.layer.borderColor = UIColor.redColor.CGColor;
//    textView.layer.borderWidth = 1.0;
//    textView.textContainerInset = UIEdgeInsetsMake(20, 20, 20, 20);
//    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 50, 50)];
//    textView.textContainer.exclusionPaths = @[path];
    [self.view addSubview:textView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
