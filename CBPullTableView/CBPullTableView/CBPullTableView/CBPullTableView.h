//
//  CBPullTableView.h
//  PullTable
//
//  Created by xychen on 14-3-3.
//  Copyright (c) 2014年 CB. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CBPullTableViewDelegate;

typedef enum {
    PullStateNormal = 0,
    PullStateRefresh = 1,
    PullStateLoading = 2,
    PullStateHitTheEnd = 3
} PullState;

@interface CBPullTableView : UITableView

@property (strong,nonatomic) id <CBPullTableViewDelegate> cbPullTableViewDelegate;
@property (nonatomic) BOOL isAutoLoading;
@property (nonatomic) BOOL isRefreshing;
@property (nonatomic) BOOL isHitTheEnd;// 标记是否已经是最后一页
@property (nonatomic) PullState pullState;

- (void)tableViewDidScroll:(UIScrollView *)scrollView;

- (void)tableViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;

// 完成刷新，还原tableView的位置
- (void)tableViewDidFinishedRefreshing;
// 完成加载
- (void)tableViewDidFinishedLoading;
// 已经是最后一页
- (void)tableViewDidHitTheEnd;


@end

@protocol CBPullTableViewDelegate <NSObject>

@required
// 已经开始刷新
- (void)cbPullTableDidStartRefresh:(CBPullTableView *)tableView;

@optional
// 已经开始加载
- (void)cbPullTableDidStartLoad:(CBPullTableView *)tableView;
// 已经是最后一页
- (void)cbPullTableDidHitTheEnd:(CBPullTableView *)tableView;

@end