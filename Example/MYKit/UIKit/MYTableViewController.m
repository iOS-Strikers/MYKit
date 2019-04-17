//
//  MYTableViewController.m
//  MYKitDemo
//
//  Created by QMMac on 2018/8/6.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import "MYTableViewController.h"
#import "MYPlaceHolderView.h"
#import "MYUIKit.h"
#import <MJRefresh.h>

@interface MYTableViewController ()<TableViewPlaceHolderDelegate, MYPlaceHolderViewDelegate>

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, assign, getter=isNoResult) BOOL noResult;

@end

@implementation MYTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"MYTableViewPlaceHolder";
    self.tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    __unsafe_unretained __typeof(self) weakSelf = self;
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf loadNewData];
    }];
    
    // 马上进入刷新状态
    [self.tableView.mj_header beginRefreshing];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * ID = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", @"Random Data", self.dataSource[indexPath.row]];
    return cell;
}

#pragma mark - 下拉刷新数据

- (void)loadNewData {
    if (!self.isNoResult) {
        self.dataSource = nil;
    } else {
        // 1.添加假数据
        for (int i = 0; i<5; i++) {
            
            [self.dataSource insertObject:[NSString stringWithFormat:@"随机数据---%d", arc4random_uniform(1000000)] atIndex:0];
        }
    }
    
    // 2.模拟1秒后刷新表格UI（真实开发中，可以移除这段gcd代码）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 刷新表格
        [self.tableView my_reloadData];
        [self.tableView.mj_header endRefreshing];
    });
}

#pragma mark - TableViewPlaceHolderDelegate

- (UIView *)makePlaceHolderView {
    return [self placeHolderView];
}

- (UIView *)placeHolderView {
    MYPlaceHolderView *placeHolder = [[MYPlaceHolderView alloc] initWithFrame:self.tableView.frame];
    placeHolder.delegate = self;
    return placeHolder;
}

#pragma mark - MYPlaceHolderViewDelegate

- (void)emptyOverlayClicked:(id)sender {
    [self.tableView.mj_header beginRefreshing];
}

#pragma mark - setter & getter

- (BOOL)isNoResult {
    _noResult = (self.dataSource.count == 0);
    return _noResult;
}

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NSMutableArray alloc] init];
    }
    return _dataSource;
}

@end
