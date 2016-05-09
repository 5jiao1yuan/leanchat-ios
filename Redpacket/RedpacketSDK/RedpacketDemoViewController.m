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
#import "RedpacketMessageCell.h"
#import "RedpacketTakenMessageTipCell.h"
#pragma mark -

#pragma mark - 红包相关的宏定义
#define REDPACKET_BUNDLE(name) @"RedpacketCellResource.bundle/" name
#pragma mark -

#import <objc/objc-runtime.h>

static NSString *const RedpacketMessageCellReceiverIdentifier = @"RedpacketMessageCellReceiverIdentifier";
static NSString *const RedpacketMessageCellSenderIdentifier = @"RedpacketMessageCellSenderIdentifier";
static NSString *const RedpacketTakenMessageTipCellReceiverIdentifier = @"RedpacketTakenMessageTipCellReceiverIdentifier";
static NSString *const RedpacketTakenMessageTipCellSenderIdentifier = @"RedpacketTakenMessageTipSenderCellIdentifier";

@interface RedpacketDemoViewController () <RedpacketCellDelegate>

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
    if (2 == members.count) {
        // 不确定 member 里哪一个肯定是 对方的 userid
        if (![members[0] isEqualToString:self.conversation.clientId]) {
            user.userId = members[0];
        }
        else if (![members[1] isEqualToString:self.conversation.clientId]) {
            user.userId = members[1];
        }
        else {
            assert(user.userId);
        }
        id<CDUserModelDelegate> u = [[CDChatManager manager].userDelegate getUserById:user.userId];
        user.userAvatar = [u avatarUrl];
        user.userNickname = [u username];
    }
    else if(members.count > 2) {
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

// 为了尽量沿用原来的代码而不修改原始的文件和代码, 需要执行 [super method] 的基类方法
// 但由于原来的基类未开放大部分的接口，所以不能通过 [- performSelector:withObject:]
// 需要使用 ObjC 运行时库来执行
// 参考:
// http://stackoverflow.com/questions/20127714/the-infinite-loop-when-using-super-peformselector-method
// http://stackoverflow.com/questions/16678463/accessing-a-method-in-a-super-class-when-its-not-exposed
- (id)callSuperMethod:(SEL)method withObject:(id)object
{
    struct objc_super mySuper;
    mySuper.receiver = self;
    mySuper.super_class = self.superclass;
    
    // 另外由于 Xcode 的新要求，必须先把原先的方法强制转成特定的函数指针形式才可以执行
    return ((id (*)(struct objc_super *, SEL, ...))objc_msgSendSuper)(&mySuper, method, object);
}

#pragma mark - 融云消息与红包插件消息转换与处理
// 发送融云红包消息
- (void)sendRedpacketMessage:(RedpacketMessageModel *)redpacket
{
    RedpacketMessage *message = [RedpacketMessage messageWithRedpacket:redpacket];
    assert(message);
    
    [self performSelector:@selector(sendMessage:) withObject:message];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeText];
}

// 红包被抢消息处理
- (void)onRedpacketTakenMessage:(RedpacketMessageModel *)redpacket
{
    RedpacketMessage *message = [RedpacketMessage messageWithRedpacket:redpacket];
    assert(message);
    [self performSelector:@selector(sendMessage:) withObject:message];
}

- (AVIMTypedMessage *)getAVIMTypedMessageWithMessage:(XHMessage *)message
{
    if ([message isKindOfClass:[RedpacketMessage class]]) {
        RedpacketMessage *r = (RedpacketMessage *)message;
        AVIMTypedMessage *avimMessage = nil;
        if(RedpacketMessageTypeRedpacket == r.redpacket.messageType) {
            avimMessage = [AVIMTextMessage messageWithRedpacket:r.redpacket];
        }
        else if(RedpacketMessageTypeTedpacketTakenMessage == r.redpacket.messageType) {
            avimMessage = [RedpacketTakenAVIMMessage messageWithRedpacket:r.redpacket];
        }
        assert(avimMessage);
        return avimMessage;
    }

    SEL method = @selector(getAVIMTypedMessageWithMessage:);
    return [self callSuperMethod:method withObject:message];
}

- (XHMessage *)getXHMessageByMsg:(AVIMTypedMessage *)message {
    if (message.redpacket) {
        id<CDUserModelDelegate> fromUser = [[CDChatManager manager].userDelegate getUserById:message.clientId];
        XHMessage *xhMessage = [RedpacketMessage messageWithRedpacket:message.redpacket];
        xhMessage.avator = nil;
        xhMessage.avatorUrl = [fromUser avatarUrl];
        
        if ([[CDChatManager manager].clientId isEqualToString:message.clientId]) {
            xhMessage.bubbleMessageType = XHBubbleMessageTypeSending;
        } else {
            xhMessage.bubbleMessageType = XHBubbleMessageTypeReceiving;
        }
        NSInteger msgStatuses[4] = { AVIMMessageStatusSending, AVIMMessageStatusSent, AVIMMessageStatusDelivered, AVIMMessageStatusFailed };
        NSInteger xhMessageStatuses[4] = { XHMessageStatusSending, XHMessageStatusSent, XHMessageStatusReceived, XHMessageStatusFailed };
        
        if (xhMessage.bubbleMessageType == XHBubbleMessageTypeSending) {
            XHMessageStatus status = XHMessageStatusReceived;
            int i;
            for (i = 0; i < 4; i++) {
                if (msgStatuses[i] == message.status) {
                    status = xhMessageStatuses[i];
                    break;
                }
            }
            xhMessage.status = status;
        } else {
            xhMessage.status = XHMessageStatusReceived;
        }
        return xhMessage;
    }
    
    return [self callSuperMethod:@selector(getXHMessageByMsg:) withObject:message];
}

#pragma mark - 红包功能显示界面处理
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<XHMessageModel> message = [self.dataSource messageForRowAtIndexPath:indexPath];
    if ([message isKindOfClass:[RedpacketMessage class]]) {
        RedpacketMessage *redpacketMessage = (RedpacketMessage *)message;
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
                if (RedpacketMessageTypeRedpacket == redpacketMessage.redpacket.messageType) {
                    RedpacketMessageCell *redpacketCell = [tableView dequeueReusableCellWithIdentifier:RedpacketMessageCellReceiverIdentifier];
                    if (!redpacketCell) {
                        redpacketCell = [[RedpacketMessageCell alloc] initWithMessage:message
                                                                      reuseIdentifier:RedpacketMessageCellReceiverIdentifier];
                    }
                    redpacketCell.delegate = self;
                    redpacketCell.redpacketDelegate = self;
                    messageTableViewCell = redpacketCell;
                }
                else {
                    RedpacketTakenMessageTipCell *redpacketCell = [tableView dequeueReusableCellWithIdentifier:RedpacketTakenMessageTipCellReceiverIdentifier];
                    if (!redpacketCell) {
                        redpacketCell = [[RedpacketTakenMessageTipCell alloc] initWithMessage:message
                                                                              reuseIdentifier:RedpacketTakenMessageTipCellReceiverIdentifier];
                    }
                    redpacketCell.delegate = self;
                    messageTableViewCell = redpacketCell;
                }
                break;
            case XHBubbleMessageTypeSending:
                if (RedpacketMessageTypeRedpacket == redpacketMessage.redpacket.messageType) {
                    RedpacketMessageCell *redpacketCell = [tableView dequeueReusableCellWithIdentifier:RedpacketMessageCellSenderIdentifier];
                    if (!redpacketCell) {
                        redpacketCell = [[RedpacketMessageCell alloc] initWithMessage:message
                                                                      reuseIdentifier:RedpacketMessageCellSenderIdentifier];
                    }
                    redpacketCell.delegate = self;
                    redpacketCell.redpacketDelegate = self;
                    messageTableViewCell = redpacketCell;
                }
                else {
                    RedpacketTakenMessageTipCell *redpacketCell = [tableView dequeueReusableCellWithIdentifier:RedpacketTakenMessageTipCellSenderIdentifier];
                    if (!redpacketCell) {
                        redpacketCell = [[RedpacketTakenMessageTipCell alloc] initWithMessage:message
                                                                              reuseIdentifier:RedpacketTakenMessageTipCellSenderIdentifier];
                    }
                    redpacketCell.delegate = self;
                    messageTableViewCell = redpacketCell;
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
    else { // fallback to super
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

- (void)redpacketCell:(RedpacketMessageCell *)cell didTap:(RedpacketMessage *)message
{
    if(RedpacketMessageTypeRedpacket == message.redpacket.messageType) {
        [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeText];
        [self.redpacketControl redpacketCellTouchedWithMessageModel:message.redpacket];
    }
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
