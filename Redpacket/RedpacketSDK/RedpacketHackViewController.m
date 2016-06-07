//
//  RedpacketHackViewController.m
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-9.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "RedpacketHackViewController.h"
#import "CDFailedMessageStore.h"
#import "CDSoundManager.h"
#import "RedpacketMessageCell.h"
#import "RedpacketTakenMessageTipCell.h"

@import ObjectiveC;

@implementation RedpacketHackViewController


// 为了尽量沿用原来的代码而不修改原始的文件和代码, 需要执行 [super method] 的基类方法
// 但由于原来的基类未开放大部分的接口，所以不能通过 [- performSelector:withObject:]
// 需要使用 ObjC 运行时库来执行
// 参考:
// http://stackoverflow.com/questions/20127714/the-infinite-loop-when-using-super-peformselector-method
// http://stackoverflow.com/questions/16678463/accessing-a-method-in-a-super-class-when-its-not-exposed
- (id)callSuperClass:(Class)class method:(SEL)method withObject:(id)object
{
    struct objc_super mySuper;
    mySuper.receiver = self;
    mySuper.super_class = class;
    
    // 必须先把原先的方法强制转成特定的函数指针形式才可以执行
    // 必须对应参数的类型，不能使用强制转换的类型（因为 ARC 会使编译器对 ObjectiveC 对象 进行 retain/release 操作，如果参数为标量
    // 则必须将参数类型指明，否则引起异常
    id ret = ((id (*)(struct objc_super *, SEL, id))objc_msgSendSuper)(&mySuper, method, object);
    return ret;
}

- (void)callVoidSuperClass:(Class)class method:(SEL)method withObject:(id)object
{
    struct objc_super mySuper;
    mySuper.receiver = self;
    mySuper.super_class = class;
    
    // 必须先把原先的方法强制转成特定的函数指针形式才可以执行
    // 必须对应参数的类型，不能使用强制转换的类型（因为 ARC 会使编译器对 ObjectiveC 对象 进行 retain/release 操作，如果参数为标量
    // 则必须将参数类型指明，否则引起异常
    ((void (*)(struct objc_super *, SEL, id))objc_msgSendSuper)(&mySuper, method, object);
}

- (CGFloat)superCalculateCellHeightWithMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath
{
    struct objc_super mySuper;
    mySuper.receiver = self;
    mySuper.super_class = [XHMessageTableViewController class];
    
    SEL method = @selector(calculateCellHeightWithMessage:atIndexPath:);
    // 必须先把原先的方法强制转成特定的函数指针形式才可以执行
    CGFloat ret = ((CGFloat (*)(struct objc_super *, SEL, id, id))objc_msgSendSuper)(&mySuper, method, message, indexPath);
    return ret;
}

- (void)sendCustomRedpacketMessage:(RedpacketMessage*)message;
{
    [self performSelector:@selector(sendMessage:) withObject:message];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeText];
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
            // 这个类用来占位置，不支持发送
            avimMessage = [RedpacketTakenAVIMTypedMessage messageWithRedpacket:r.redpacket];
        }
        return avimMessage;
    }
    
    SEL method = @selector(getAVIMTypedMessageWithMessage:);
    return [self callSuperClass:[CDChatRoomVC class] method:method withObject:message];
}

- (void)sendMessage:(XHMessage *)message {
    void (^success)(NSString *messageUUID)  = ^(NSString *messageUUID) {
        if ([message isKindOfClass:[RedpacketMessage class]]) {
            RedpacketMessage *redpacketMessage = (RedpacketMessage *)message;
            if (RedpacketMessageTypeTedpacketTakenMessage == redpacketMessage.redpacket.messageType) {
                
                return ;
            }
        }
        [[CDSoundManager manager] playSendSoundIfNeed];
    };
    
    void (^failed)(NSString *messageUUID, NSError *error) = ^(NSString *messageUUID, NSError *error) {
        message.messageId = messageUUID;
        [[CDFailedMessageStore store] insertFailedXHMessage:message];
    };
    
    ((void (*)(id, SEL, id, id, id))objc_msgSend)(self, @selector(sendMessage:success:failed:), message, success, failed);
}

- (XHMessage *)getXHMessageByMsg:(AVIMTypedMessage *)message {
    // 为了处理 抢红包消息
    if (message.redpacket) {
        id<CDUserModelDelegate> fromUser = [[CDChatManager manager].userDelegate getUserById:message.clientId];
        RedpacketMessage *xhMessage = [RedpacketMessage messageWithRedpacket:message.redpacket];
        xhMessage.redpacketPayload = message.redpacketPayload;
        xhMessage.avator = nil;
        xhMessage.avatorUrl = [fromUser avatarUrl];
        xhMessage.sender = [fromUser username];
        
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
    
    id msg = message;
    return [self callSuperClass:[CDChatRoomVC class]
                         method:@selector(getXHMessageByMsg:)
                     withObject:msg];
}

- (CGFloat)calculateCellHeightWithMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight = 0;
    if ([message isKindOfClass:[RedpacketMessage class]]) {

        RedpacketMessage *m = (RedpacketMessage *)message;
        if (RedpacketMessageTypeRedpacket == m.redpacket.messageType) {
            BOOL displayTimestamp = YES;
            BOOL displayPeerName = NO;
            
            //FIXME:indexPath changed, timestamp change the way wether display or not, but showed the old way.
            if ([self.delegate respondsToSelector:@selector(shouldDisplayTimestampForRowAtIndexPath:)]) {
                displayTimestamp = [self.delegate shouldDisplayTimestampForRowAtIndexPath:indexPath];
            }
            if ([self.delegate respondsToSelector:@selector(shouldDisplayPeerName)]) {
                displayPeerName = [self.delegate shouldDisplayPeerName];
            }
            cellHeight = [RedpacketMessageCell calculateCellHeightWithMessage:message displaysTimestamp:displayTimestamp displaysPeerName:displayPeerName];
        }
        else {
            cellHeight = [RedpacketTakenMessageTipCell calculateCellHeightWithMessage:message displaysTimestamp:NO displaysPeerName:NO];
        }
    }
    else {
        cellHeight = [self superCalculateCellHeightWithMessage:message atIndexPath:indexPath];
    }
    return cellHeight;
}


@end
