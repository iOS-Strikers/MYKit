//
//  MYNavigationBarViewController.m
//  MYKitDemo
//
//  Created by QMMac on 2018/7/17.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import "MYNavigationBarViewController.h"
#import "UINavigationBar+Addition.h"
#import "UIScreen+Addition.h"
#import "UIViewController+PreviousController.h"
#import "UIViewController+PageViewLevel.h"

// offsetY > -64 的时候导航栏开始偏移
#define NAVBAR_TRANSLATION_POINT 0
#define NavBarHeight 44

@interface MYNavigationBarViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIImageView *imgView;

@end

@implementation MYNavigationBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor greenColor];
    self.title = @"浮动效果";
    [self.view addSubview:self.tableView];
    self.tableView.tableHeaderView = self.imgView;
    
    NSLog(@"navigationBarHeight%f",[UIScreen navigationBarHeight]);
    NSLog(@"%ld", (long)[self pageViewLevel]);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setNavigationBarTransformProgress:0];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    if (offsetY > NAVBAR_TRANSLATION_POINT) {
        [UIView animateWithDuration:0.3 animations:^{
            [self setNavigationBarTransformProgress:1];
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            [self setNavigationBarTransformProgress:0];
        }];
    }
}

- (void)setNavigationBarTransformProgress:(CGFloat)progress {
    [self.navigationController.navigationBar setTranslationY:(-NavBarHeight * progress)];
    // 有系统的返回按钮，所以 hasSystemBackIndicator = YES
    [self.navigationController.navigationBar setBarButtonItemsAlpha:(1 - progress) hasSystemBackIndicator:YES];
}

#pragma mark - tableview delegate / dataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:nil];
    NSString *str = [NSString stringWithFormat:@"NavigationBar %zd",indexPath.row];
    cell.textLabel.text = str;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor whiteColor];
    NSString *str = [NSString stringWithFormat:@"NavigationBar %zd",indexPath.row];
    vc.title = str;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - getter / setter
- (UITableView *)tableView {
    if (!_tableView) {
        CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        _tableView = [[UITableView alloc] initWithFrame:frame
                                                  style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (UIImageView *)imgView {
    if (!_imgView) {
        _imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"image2"]];
    }
    return _imgView;
}

@end
