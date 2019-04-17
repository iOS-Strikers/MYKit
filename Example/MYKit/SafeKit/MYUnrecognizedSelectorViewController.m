//
//  MYUnrecognizedSelectorViewController.m
//  MYKitDemo
//
//  Created by QMMac on 2018/8/3.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import "MYUnrecognizedSelectorViewController.h"

@interface MYUnrecognizedSelectorViewController ()

@end

@implementation MYUnrecognizedSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton * testObj = [[UIButton alloc] init];
    [testObj performSelector:@selector(someMethod:)];

    [UIButton performSelector:@selector(someMethod:)];
    
    [testObj performSelector:@selector(someMethod:)];
    
    [UIButton performSelector:@selector(someMethod:)];
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
