//
//  CBPullTableView.m
//  PullTable
//
//  Created by xychen on 14-3-3.
//  Copyright (c) 2014年 CB. All rights reserved.
//

#import "CBPullTableView.h"

#define kPULL_DOWN_REFRESH   @"下拉刷新"
#define kRELEASE_REFRESH     @"释放刷新"
#define kREFRESHING          @"正在刷新"

#define kPULL_UP_LOADMORE    @"上拉加载更多"
#define kRELEASE_LOADMORE    @"释放加载更多"
#define kLOADING             @"正在加载"

#define kIsIOS7 [[[UIDevice currentDevice] systemVersion]floatValue]>=7.0

#define kLoad_OFFSET_Y       64
#define kArrowGap            5// 箭头到列表间距

//#define kOFFSET_AnimateDuration .18f
#define kOFFSET_AnimateDuration 0.2

@interface CBPullTableView ()
{
    
}

@property (nonatomic) CGFloat refreshOffsetY;// 根据实际情况修改该值，用于调整下拉刷新的偏移量
@property (nonatomic) CGFloat offsetY;// 记录tableView.contentOffset的起始位置，用于刷新/加载后还原
@property (nonatomic) BOOL isHaveOffsetY;

@property (strong, nonatomic) UILabel *lblRefresh;// 刷新
@property (strong, nonatomic) CALayer *layerRefresh;

@property (strong, nonatomic) UILabel *lblLoad;// 加载
@property (strong, nonatomic) CALayer *layerLoad;

@property (strong, nonatomic) UIActivityIndicatorView *activityView;

@end

@implementation CBPullTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        if (kIsIOS7)
        {
            _refreshOffsetY = -124;
        }
        else
        {
            _refreshOffsetY = -64;
        }
        
        _isHaveOffsetY = NO;
        _pullState = PullStateNormal;
        _isRefreshing = NO;
        _isHitTheEnd = NO;
        _isAutoLoading = NO;// 自动加载更多。YES:自动加载；NO:拖动加载。默认为拖动加载
        
        //        NSLog(@"常规减速率：%f, 快速减速率：%f", UIScrollViewDecelerationRateNormal, UIScrollViewDecelerationRateFast);
        //        self.decelerationRate = UIScrollViewDecelerationRateFast;
        
        [self initUI];
        [self setUIFrame];
    }
    return self;
}

- (void)initUI
{
    // 刷新Label
    _lblRefresh = [[UILabel alloc] init];
    _lblRefresh.text = kPULL_DOWN_REFRESH;
    _lblRefresh.textAlignment = UITextAlignmentCenter;
    _lblRefresh.textColor = [UIColor darkGrayColor];
    _lblRefresh.font = [UIFont systemFontOfSize:20];
    _lblRefresh.backgroundColor = [UIColor clearColor];
    [self addSubview:_lblRefresh];
    
    // 刷新箭头
    _layerRefresh = [CALayer layer];
    _layerRefresh.contentsGravity = kCAGravityResizeAspect;
    _layerRefresh.transform = CATransform3DIdentity;
    UIImage *arrowDown = [UIImage imageNamed:@"blueArrowDown.png"];
    _layerRefresh.contents = (id)arrowDown.CGImage;
    [self.layer addSublayer:_layerRefresh];
    
    // 进度条指示器
    _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self addSubview:_activityView];
    
    // 加载Label
    _lblLoad = [[UILabel alloc] init];
    _lblLoad.text = kPULL_UP_LOADMORE;
    _lblLoad.textAlignment = UITextAlignmentCenter;
    _lblLoad.textColor = [UIColor darkGrayColor];
    _lblLoad.font = [UIFont systemFontOfSize:20];
    _lblLoad.backgroundColor = [UIColor clearColor];
    [self addSubview:_lblLoad];
    
    // 加载箭头
    _layerLoad = [CALayer layer];
    _layerLoad.contentsGravity = kCAGravityResizeAspect;
    _layerLoad.transform = CATransform3DIdentity;
    UIImage *arrowUp = [UIImage imageNamed:@"blueArrowUp.png"];
    _layerLoad.contents = (id)arrowUp.CGImage;
    [self.layer addSublayer:_layerLoad];
}

- (void)setUIFrame
{
    CGFloat layerWidth = 23;
    CGFloat layerHeight = 60;
    CGFloat layerOriginX = 40;
    
    // 刷新箭头的frame
    CGRect layerRect = CGRectMake(layerOriginX, -(layerHeight+kArrowGap), layerWidth, layerHeight);
    _layerRefresh.frame = layerRect;
    
    // 进度条指示器的frame
    _activityView.center = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
    
    // 加载箭头的frame
    _layerLoad.frame = CGRectMake(layerOriginX, 0, layerWidth, layerHeight);// 坐标随意设置，在reloadData时调整坐标
    
    [self isHiddenHeadView:YES];
    
    CGFloat lblHeight = 40;
    
    // 刷新Label的frame
    _lblRefresh.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), lblHeight);
    _lblRefresh.center = CGPointMake(_lblRefresh.center.x, CGRectGetMidY(_layerRefresh.frame));
    
    // 加载Label的frame
    _lblLoad.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), lblHeight);// 坐标随意设置，在reloadData时调整坐标
    
    [self isHiddenFootView:YES];
    
}

#pragma mark - Scroll Method
- (void)tableViewDidScroll:(UIScrollView *)scrollView
{
    if (!_isHaveOffsetY)// 没有记录TableView的起始坐标
    {
        _offsetY = scrollView.contentOffset.y;
        _isHaveOffsetY = YES;
    }
    
    CGPoint offset = scrollView.contentOffset;
    
    if (offset.y < _offsetY)
    {// 超出第一行的顶部
        if (offset.y < _refreshOffsetY-kArrowGap*2)// 下拉刷新
        {
            _lblRefresh.text = kRELEASE_REFRESH;
            _pullState = PullStateRefresh;
            
            _layerRefresh.hidden = NO;
            
            scrollView.decelerationRate = 0.5;
            
            [CATransaction begin];
            [CATransaction setAnimationDuration:kOFFSET_AnimateDuration];
            _layerRefresh.transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
            [CATransaction commit];
        }
        else
        {
            [self tableViewNormalStatusWithContentOffset:offset scrollView:scrollView];
        }
    }
    else if (scrollView.contentSize.height > 0 && offset.y > scrollView.contentSize.height-CGRectGetHeight(scrollView.frame))
    {// 超出最后一行的底部
        if (PullStateHitTheEnd == _pullState)
        {
            [self tableViewDidHitTheEnd];
            return;
        }
        
        if (_isAutoLoading)// 自动加载
        {
            if (!_isRefreshing)
            {
                _isRefreshing = YES;
                if (self.cbPullTableViewDelegate && [self.cbPullTableViewDelegate respondsToSelector:@selector(cbPullTableDidStartLoad:)])
                {
                    [self.cbPullTableViewDelegate cbPullTableDidStartLoad:self];
                }
            }
        }
        else
        {
            CGFloat loadOffsetY = scrollView.contentSize.height + kLoad_OFFSET_Y + kArrowGap*2 - CGRectGetHeight(scrollView.frame);
            
            if (offset.y > loadOffsetY)// 上拉加载更多
            {
                _lblLoad.text = kRELEASE_LOADMORE;
                _pullState = PullStateLoading;
                
                [self isHiddenFootView:NO];
                
                scrollView.decelerationRate = 0.5;
                
                [CATransaction begin];
                [CATransaction setAnimationDuration:kOFFSET_AnimateDuration];
                _layerLoad.transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
                [CATransaction commit];
            }
            else
            {
                [self tableViewNormalStatusWithContentOffset:offset scrollView:scrollView];
            }
        }
    }
    else
    {// 没有超出Cell的范围
        [self tableViewNormalStatusWithContentOffset:offset scrollView:scrollView];
    }
}

- (void)tableViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (PullStateRefresh == _pullState)
    {
        [UIView animateWithDuration:kOFFSET_AnimateDuration animations:^{
            
            _isRefreshing = YES;
            _layerRefresh.hidden = YES;
            
            _activityView.center = CGPointMake(CGRectGetMidX(_layerRefresh.frame), CGRectGetMidY(_layerRefresh.frame));
            [_activityView startAnimating];
            _activityView.hidden = NO;
            
            _lblRefresh.text = kREFRESHING;
            
            scrollView.contentInset = UIEdgeInsetsMake(-_refreshOffsetY+1+kArrowGap*2, 0, 0, 0);
            
        } completion:^(BOOL finished) {
            
            if (self.cbPullTableViewDelegate && [self.cbPullTableViewDelegate respondsToSelector:@selector(cbPullTableDidStartRefresh:)])
            {
                [self.cbPullTableViewDelegate cbPullTableDidStartRefresh:self];
            }
        }];
    }
    else if (PullStateLoading == _pullState)
    {
        [UIView animateWithDuration:kOFFSET_AnimateDuration animations:^{
            
            _isRefreshing = YES;
            _layerLoad.hidden = YES;
            
            _activityView.center = CGPointMake(CGRectGetMidX(_layerLoad.frame), CGRectGetMidY(_layerLoad.frame));
            [_activityView startAnimating];
            _activityView.hidden = NO;
            
            _lblLoad.text = kLOADING;
            
            scrollView.contentInset = UIEdgeInsetsMake(0, 0, kLoad_OFFSET_Y+1+kArrowGap*2, 0);
            
        } completion:^(BOOL finished) {
            if (self.cbPullTableViewDelegate && [self.cbPullTableViewDelegate respondsToSelector:@selector(cbPullTableDidStartLoad:)])
            {
                [self.cbPullTableViewDelegate cbPullTableDidStartLoad:self];
            }
        }];
    }
    else
    {
        
    }
    
}

#pragma mark - Overwrite
- (void)reloadData
{
    if (PullStateHitTheEnd != _pullState)
    {
        [super reloadData];
        
        // 设置箭头的 y坐标
        CGRect layerRect = _layerLoad.frame;
        if (self.contentSize.height < 1)
        {
            layerRect.origin.y = self.frame.size.height+kArrowGap;
        }
        else
        {
            layerRect.origin.y = self.contentSize.height+kArrowGap;
        }
        _layerLoad.frame = layerRect;
        
        // 设置Label的 y坐标
        _lblLoad.center = CGPointMake(_lblLoad.center.x, CGRectGetMidY(_layerLoad.frame));
    }
}

#pragma mark - Custom Method
// 显示/隐藏头部
- (void)isHiddenHeadView:(BOOL)isShow
{
    self.layerRefresh.hidden = isShow;
    self.lblRefresh.hidden = isShow;
}

// 隐藏底部
- (void)isHiddenFootView:(BOOL)isShow
{
    self.layerLoad.hidden = isShow;
    self.lblLoad.hidden = isShow;
}

// tableView处于常规状态时
- (void)tableViewNormalStatusWithContentOffset:(CGPoint)offset scrollView:(UIScrollView *)scrollView
{
    _lblRefresh.text = kPULL_DOWN_REFRESH;
    _lblLoad.text = kPULL_UP_LOADMORE;
    
    if (PullStateHitTheEnd == _pullState)
    {
        _isHitTheEnd = YES;
    }
    else
    {
        _pullState = PullStateNormal;
    }
    
    
    if (offset.y < _offsetY || offset.y > scrollView.contentSize.height-CGRectGetHeight(scrollView.frame))
    {// 处于contentSize范围外
        [self isHiddenHeadView:NO];
        
        if (_isHitTheEnd)
        {
            [self isHiddenFootView:YES];
        }
        else
        {
            [self isHiddenFootView:NO];
        }
        
    }
    else
    {// 处于contentSize范围内
        [self isHiddenHeadView:YES];
        [self isHiddenFootView:YES];
    }
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:kOFFSET_AnimateDuration];
    _layerRefresh.transform = CATransform3DIdentity;
    _layerLoad.transform = CATransform3DIdentity;
    [CATransaction commit];
    
    scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
}

#pragma mark - CBPullTableViewDelegate
// 完成刷新，还原tableView的位置
- (void)tableViewDidFinishedRefreshing
{
    [UIView animateWithDuration:kOFFSET_AnimateDuration animations:^{
        self.contentInset = UIEdgeInsetsMake(-_offsetY, 0, 0, 0);
        _pullState = PullStateNormal;
        
    } completion:^(BOOL finished) {
        _isRefreshing = NO;
        
        _isHitTheEnd = NO;
        [self isHiddenFootView:NO];
        
        _activityView.hidden = YES;
        [_activityView stopAnimating];
        
        _layerRefresh.hidden = NO;
    }];
}

// 完成加载
- (void)tableViewDidFinishedLoading
{
    [UIView animateWithDuration:kOFFSET_AnimateDuration animations:^{
        self.contentInset = UIEdgeInsetsMake(-_offsetY, 0, 0, 0);
        _pullState = PullStateNormal;
        
    } completion:^(BOOL finished) {
        _isRefreshing = NO;
        
        _isHitTheEnd = NO;
        [self isHiddenFootView:NO];
        
        _activityView.hidden = YES;
        [_activityView stopAnimating];
        
        _layerLoad.hidden = NO;
    }];
}

// 已经是最后一页
- (void)tableViewDidHitTheEnd
{
    [UIView animateWithDuration:kOFFSET_AnimateDuration animations:^{
        self.contentInset = UIEdgeInsetsMake(-_offsetY, 0, 0, 0);
        
        
    } completion:^(BOOL finished) {
        _isRefreshing = NO;
        
        _isHitTheEnd = YES;
        [self isHiddenFootView:YES];
        
        _activityView.hidden = YES;
        [_activityView stopAnimating];
        
        if (self.cbPullTableViewDelegate && [self.cbPullTableViewDelegate respondsToSelector:@selector(cbPullTableDidHitTheEnd:)])
        {
            [self.cbPullTableViewDelegate cbPullTableDidHitTheEnd:self];
        }
    }];
}

@end
