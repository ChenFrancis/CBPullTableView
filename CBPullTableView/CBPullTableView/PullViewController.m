//
//  PullViewController.m
//  CBPullTableView
//
//  Created by xychen on 14-3-5.
//  Copyright (c) 2014年 CB. All rights reserved.
//

#import "PullViewController.h"

#import "CBPullTableView.h"
#import "AutoViewController.h"

@interface PullViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, CBPullTableViewDelegate>
{
    NSArray *_arrayData;
}

@property (strong, nonatomic) CBPullTableView *tbData;
@property (strong, nonatomic) AutoViewController *autoVC;

@end

@implementation PullViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"上拉下拉";
    
    self.view.backgroundColor = [UIColor colorWithRed:(246.0f / 255.0f) green:(246.0f / 255.0f) blue:(246.0f / 255.0f) alpha:1.0];
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:@"自动加载" style:UIBarButtonItemStylePlain target:self action:@selector(showAutoLoadTableAction:)];
    self.navigationItem.rightBarButtonItem = buttonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!_tbData)
    {
        CGRect tbRect = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
        _tbData = [[CBPullTableView alloc] initWithFrame:tbRect];
        [self.view addSubview:_tbData];
        
        _tbData.dataSource = self;
        _tbData.delegate = self;
        _tbData.cbPullTableViewDelegate = self;
        
        [self cbPullTableDidStartRefresh:_tbData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _arrayData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.backgroundColor = [UIColor lightGrayColor];
    cell.textLabel.text = [NSString stringWithFormat:@"第%@行", [_arrayData objectAtIndex:indexPath.row]];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!_tbData.isRefreshing)
    {
        [_tbData tableViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!_tbData.isRefreshing)
    {
        [_tbData tableViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

#pragma mark - CBPullTableViewDelegate
// 刷新
- (void)cbPullTableDidStartRefresh:(CBPullTableView *)tableView
{
    // 调用网络接口
    [self performSelector:@selector(getRefreshData) withObject:nil afterDelay:1.f];
}

// 加载更多
- (void)cbPullTableDidStartLoad:(CBPullTableView *)tableView
{
    // 调用网络接口
    [self performSelector:@selector(getLoadMoreData) withObject:nil afterDelay:1.f];
}

// 已经是最后一页
- (void)cbPullTableDidHitTheEnd:(CBPullTableView *)tableView
{
    [_tbData reloadData];
}

#pragma mark - Refresh/Load Data
- (void)getRefreshData
{
    NSMutableArray *newArr = [[NSMutableArray alloc] init];
    for (int i = 1; i < 11; i++)
    {
        NSString *str = [NSString stringWithFormat:@"%d", i];
        [newArr addObject:str];
    }
    
    _arrayData = [[NSArray alloc] initWithArray:newArr];
    [_tbData reloadData];
    
    [_tbData tableViewDidFinishedRefreshing];
}

- (void)getLoadMoreData
{
    int everyTimeCount = 10;
    
    if (_arrayData.count < everyTimeCount*3)// 大于3页，则不再加载
    {
        NSMutableArray *newArr = [[NSMutableArray alloc] initWithArray:_arrayData];
        for (int i = 1; i < (everyTimeCount+1); i++)
        {
            NSString *str = [NSString stringWithFormat:@"%d", _arrayData.count+i];
            [newArr addObject:str];
        }
        
        _arrayData = [[NSArray alloc] initWithArray:newArr];
        [_tbData reloadData];
        
        [_tbData tableViewDidFinishedLoading];
    }
    else
    {
        [_tbData tableViewDidHitTheEnd];
    }
}

#pragma mark - ButtonAction
- (IBAction)showAutoLoadTableAction:(id)sender
{
    UIBarButtonItem *buttonItem = (UIBarButtonItem *)sender;
    
    _autoVC = [[AutoViewController alloc] initWithNibName:@"AutoViewController" bundle:nil];
    _autoVC.title = buttonItem.title;
    _autoVC.navigationItem.backBarButtonItem.title = self.title;
    [self.navigationController pushViewController:_autoVC animated:YES];
}

@end
