//
//  RedpacketDemoViewController.m
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-5.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "RedpacketDemoViewController.h"

#pragma mark - 红包相关头文件
#import "RedpacketViewControl.h"
#import "YZHRedpacketBridge.h"
#pragma mark -

#pragma mark - 红包相关的宏定义
#define REDPACKET_BUNDLE(name) @"RedpacketCellResource.bundle/" name
#define REDPACKET_TAG 2016
#pragma mark -

@implementation RedpacketDemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    NSMutableArray *array = [self.shareMenuItems mutableCopy];
    
    // 设置红包插件界面
    UIImage *icon = [UIImage imageNamed:REDPACKET_BUNDLE(@"redpacket_redpacket")];
    assert(icon);
    
    XHShareMenuItem *shareMenuItem = [[XHShareMenuItem alloc] initWithNormalIconImage:icon title:@"红包"];
    [array insertObject:shareMenuItem atIndex:0];
    
    self.shareMenuItems = [array copy];
    
    self.shareMenuView.shareMenuItems = self.shareMenuItems;
    [self.shareMenuView reloadData];
}

@end
