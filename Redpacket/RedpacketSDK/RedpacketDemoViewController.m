//
//  RedpacketDemoViewController.m
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-5.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "RedpacketDemoViewController.h"

#import <AVOSCloud/AVOSCloud.h>

#pragma mark - 红包相关头文件
#import "RedpacketViewControl.h"
#import "YZHRedpacketBridge.h"
#import "RedpacketMessage.h"
#pragma mark -

#pragma mark - 红包相关的宏定义
#define REDPACKET_BUNDLE(name) @"RedpacketCellResource.bundle/" name
#pragma mark -

@interface RedpacketDemoViewController ()

@property (nonatomic, strong, readwrite) RedpacketViewControl *redpacketControl;

@end

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
    
    
    // 设置红包功能
    
    // 设置红包功能相关的参数
    self.redpacketControl = [[RedpacketViewControl alloc] init];
    self.redpacketControl.conversationController = self;
    
    // 设置的是接收者的 id ，
    RedpacketUserInfo *user = [[RedpacketUserInfo alloc] init];
    NSArray *members = self.conversation.members;
    if (1 == members.count) {
        user.userId = members[0];
        id<CDUserModelDelegate> u = [[CDChatManager manager].userDelegate getUserById:user.userId];
        user.userAvatar = [u avatarUrl];
        user.userNickname = [u username];
    }
    else if(members.count > 1) {
        user.userId = self.conversation.conversationId;
        user.isGroup = YES;
    }

    self.redpacketControl.converstationInfo = user;
    
    __weak typeof(self) SELF = self;
    // 设置红包 SDK 功能回调
    [self.redpacketControl setRedpacketGrabBlock:^(RedpacketMessageModel *redpacket) {
        // 用户发出的红包收到被抢的通知
        [SELF onRedpacketTakenMessage:redpacket];
    } andRedpacketBlock:^(RedpacketMessageModel *redpacket) {
        // 用户发红包的通知
        [SELF sendRedpacketMessage:redpacket];
    }];
    
    // 通知 红包 SDK 刷新 Token
    [[YZHRedpacketBridge sharedBridge] reRequestRedpacketUserToken];
}

#pragma mark - 融云消息与红包插件消息转换与处理
// 发送融云红包消息
- (void)sendRedpacketMessage:(RedpacketMessageModel *)redpacket
{
    RedpacketMessage *message = [RedpacketMessage messageWithRedpacket:redpacket];
    [self performSelector:@selector(sendMessage:) withObject:message];
}

// 红包被抢消息处理
- (void)onRedpacketTakenMessage:(RedpacketMessageModel *)redpacket
{
    RedpacketMessage *message = [RedpacketMessage messageWithRedpacket:redpacket];
    [self performSelector:@selector(sendMessage:) withObject:message];
}

#pragma mark - 红包功能显示界面处理
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<XHMessageModel> message = [self.dataSource messageForRowAtIndexPath:indexPath];
    BOOL displayTimestamp = YES;
    BOOL displayPeerName = NO;
    if ([self.delegate respondsToSelector:@selector(shouldDisplayTimestampForRowAtIndexPath:)]) {
        displayTimestamp = [self.delegate shouldDisplayTimestampForRowAtIndexPath:indexPath];
    }
    if ([self.delegate respondsToSelector:@selector(shouldDisplayPeerName)]) {
        displayPeerName = [self.delegate shouldDisplayPeerName];
    }
    
    XHMessageTableViewCell *messageTableViewCell;
    switch (message.bubbleMessageType) {
        case XHBubbleMessageTypeReceiving:
            messageTableViewCell = [tableView dequeueReusableCellWithIdentifier:receiverCellIdentifier];
            if (!messageTableViewCell) {
                messageTableViewCell = [[XHMessageTableViewCell alloc] initWithMessage:message
                                                                       reuseIdentifier:receiverCellIdentifier];
                messageTableViewCell.delegate = self;
            }
            break;
        case XHBubbleMessageTypeSending:
            messageTableViewCell = [tableView dequeueReusableCellWithIdentifier:senderCellIdentifier];
            displayPeerName = NO;
            if (!messageTableViewCell) {
                messageTableViewCell = [[XHMessageTableViewCell alloc] initWithMessage:message
                                                                       reuseIdentifier:senderCellIdentifier];
                messageTableViewCell.delegate = self;
            }
            break;
    }
    
    messageTableViewCell.indexPath = indexPath;
    [messageTableViewCell configureCellWithMessage:message displaysTimestamp:displayTimestamp displaysPeerName:displayPeerName];
    [messageTableViewCell setBackgroundColor:tableView.backgroundColor];
    
    if ([self.delegate respondsToSelector:@selector(configureCell:atIndexPath:)]) {
        [self.delegate configureCell:messageTableViewCell atIndexPath:indexPath];
    }
    return messageTableViewCell;
}

#pragma mark - 红包功能入口事件处理
- (void)didSelecteShareMenuItem:(XHShareMenuItem *)shareMenuItem atIndex:(NSInteger)index
{
    if (0 == index) { // 红包功能
        int c = (int)self.conversation.members.count;
        if (1 == c) {
            [self.redpacketControl presentRedPacketViewController];
        }
        else if(c > 1) {
            [self.redpacketControl presentRedPacketMoreViewControllerWithCount:c];
        }
    }
    else {
        [super didSelecteShareMenuItem:shareMenuItem atIndex:index];
    }
}
@end
