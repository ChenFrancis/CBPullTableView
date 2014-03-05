//
//  PullViewController.m
//  CBPullTableView
//
//  Created by xychen on 14-3-5.
//  Copyright (c) 2014年 CB. All rights reserved.
//

#import "PullViewController.h"

@interface PullViewController ()

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"上拉下拉列表";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
