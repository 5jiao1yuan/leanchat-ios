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

@import ObjectiveC;

@implementation RedpacketHackViewController

- (void)sendCustomRedpacketMessage:(RedpacketMessage*)message;
{
    [self performSelector:@selector(sendMessage:) withObject:message];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeText];
}
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
    id ret = ((id (*)(struct objc_super *, SEL, id))objc_msgSendSuper)(&mySuper, method, object);
    return ret;
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
            avimMessage = [RedpacketTakenAVIMTypedMessage messageWithRedpacket:r.redpacket];
        }
        assert(avimMessage);
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
    
    id msg = message;
    return [self callSuperClass:[CDChatRoomVC class]
                         method:@selector(getXHMessageByMsg:)
                     withObject:msg];
}

@end
