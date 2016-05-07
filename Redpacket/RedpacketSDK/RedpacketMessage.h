//
//  RedpacketMessage.h
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-6.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import <LeanChatLib/LeanChatLib.h>

#import "AVIMTextMessage.h"
#import "RedpacketMessageModel.h"

#pragma mark - 红包相关的宏定义
#define REDPACKET_TAG 216
#pragma mark -

#pragma mark - 红包 XHMessage 子类
// 处理红包的消息，因为 ChatVC 使用的是 XHMessage 的消息机制，所以这里也继承 XHMessage
@interface RedpacketMessage : XHMessage
@property (nonatomic, readonly, strong) RedpacketMessageModel *redpacket;

+ (instancetype)messageWithRedpacket:(RedpacketMessageModel *)redpacket;

- (instancetype)initWithRedpacket:(RedpacketMessageModel *)redpacket;

@end

@interface AVIMTypedMessage (Redpacket)

@property (nonatomic, readonly, strong) RedpacketMessageModel *redpacket;

+ (instancetype)messageWithRedpacket:(RedpacketMessageModel *)redpacket;

@end

#pragma mark - AVIMTypedMessage 的红包功能扩展
// 这里只使用 AVIMTextMessage 的 attributes 来传递红包信息
@interface AVIMTextMessage (Redpacket)

@end

#pragma mark - 自定义的抢红包消息
// 但是不能让所有人都显示红包被抢消息，所以使用自定义的消息类型
@interface RedpacketTakenAVIMMessage : AVIMTypedMessage <AVIMTypedMessageSubclassing>

@end
