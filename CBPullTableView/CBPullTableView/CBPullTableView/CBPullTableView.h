//
//  CBPullTableView.h
//  PullTable
//
//  Created by xychen on 14-3-3.
//  Copyright (c) 2014年 CB. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CBPullTableViewDelegate;

@interface CBPullTableView : UITableView

@property (strong,nonatomic) id <CBPullTableViewDelegate> cbPullTableViewDelegate;
@property (nonatomic) BOOL isAutoLoading;
@property (nonatomic) BOOL isRefreshing;

- (void)tableViewDidScroll:(UIScrollView *)scrollView;

- (void)tableViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;

// 完成刷新，还原tableView的位置
- (void)tableViewDidFinishedRefreshing;
// 完成加载
- (void)tableViewDidFinishedLoading;


@end

@protocol CBPullTableViewDelegate <NSObject>

@required
// 已经开始刷新
- (void)cbPullTableDidStartRefresh:(CBPullTableView *)tableView;

@optional
// 已经开始加载
- (void)cbPullTableDidStartLoad:(CBPullTableView *)tableView;

@end