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

- (void)receiveMessage:(NSNotification *)notification {
    AVIMMessage *message = notification.object;
    if([message isKindOfClass:[AVIMMessage class]]
       && [message isRedpacket]) {
        [self insertMessage:(AVIMTypedMessage *)notification.object];
    }
    else {
        [self callVoidSuperClass:[CDChatRoomVC class]
                          method:@selector(receiveMessage:)
                      withObject:notification];
    }
}

// 基类的方法使用的是 self.avimTypedMessage 作为计数，需要改为使用 self.messages 作为计数
- (void)insertMessage:(AVIMTypedMessage *)message {
    if (self.loadingMoreMessage) {
        return;
    }
    self.loadingMoreMessage = YES;
    NSArray *messages = @[message];
    void (^callback)(BOOL succeeded, NSError *error) = ^(BOOL succeeded, NSError *error) {
        struct objc_super mySuper;
        mySuper.receiver = self;
        mySuper.super_class = [CDChatRoomVC class];
        BOOL result = ((BOOL (*)(struct objc_super *, SEL, id))objc_msgSendSuper)(&mySuper, @selector(filterError:), error);
        if (result) {
            XHMessage *xhMessage = [self getXHMessageByMsg:message];
            [self.messages addObject:xhMessage];
            // avimTypedMessage 的消息必须与 xhMessage 消息一致，否则一些内部操作会错位 
            NSMutableArray *avimTypedMessage = [self performSelector:@selector(avimTypedMessage)];
            RedpacketTakenAVIMTypedMessage *m = [RedpacketTakenAVIMTypedMessage messageWithAVIMMessage:message];
            [avimTypedMessage addObject:m];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count -1 inSection:0];
            [self.messageTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self scrollToBottomAnimated:YES];
        }
        self.loadingMoreMessage = NO;
    };
    
    [self callVoidSuperClass:[CDChatRoomVC class]
                      method:@selector(runInGlobalQueue:)
                  withObject:^{
                      NSMutableSet *userIds = [[NSMutableSet alloc] init];
                      for (AVIMTypedMessage *message in messages) {
                          [userIds addObject:message.clientId];
                          if ([message isMemberOfClass:[AVIMMessage class]]) {
                              
                          }
                          else {
                              if (message.mediaType == kAVIMMessageMediaTypeImage || message.mediaType == kAVIMMessageMediaTypeAudio) {
                                  AVFile *file = message.file;
                                  if (file && file.isDataAvailable == NO) {
                                      NSError *error;
                                      // 下载到本地
                                      NSData *data = [file getData:&error];
                                      if (error || data == nil) {
                                          DLog(@"download file error : %@", error);
                                      }
                                  }
                              } else if (message.mediaType == kAVIMMessageMediaTypeVideo) {
                                  NSString *path = [[CDChatManager manager] videoPathOfMessag:(AVIMVideoMessage *)message];
                                  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                                      NSError *error;
                                      NSData *data = [message.file getData:&error];
                                      if (error) {
                                          DLog(@"download file error : %@", error);
                                      } else {
                                          [data writeToFile:path atomically:YES];
                                      }
                                  }
                              }
                          }
                      }
                      if ([[CDChatManager manager].userDelegate respondsToSelector:@selector(cacheUserByIds:block:)]) {
                          [[CDChatManager manager].userDelegate cacheUserByIds:userIds block:^(BOOL succeeded, NSError *error) {
                              [self callVoidSuperClass:[CDChatRoomVC class]
                                                method:@selector(runInMainQueue:)
                                            withObject:^{
                                                !callback ?: callback(succeeded, error);
                                            }];
                          }];
                      } else {
                          [self callVoidSuperClass:[CDChatRoomVC class]
                                            method:@selector(runInMainQueue:)
                                        withObject:^{
                                            callback(YES, nil);
                                        }];
                      }
                  }];
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
    // 为了处理 抢红包消息，这里传进来的事实上可能是 AVIMMessage
    if (message.redpacket) {
        id<CDUserModelDelegate> fromUser = [[CDChatManager manager].userDelegate getUserById:message.clientId];
        RedpacketMessage *xhMessage = [RedpacketMessage messageWithRedpacket:message.redpacket];
        xhMessage.redpacketPayload = message.redpacketPayload;
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
