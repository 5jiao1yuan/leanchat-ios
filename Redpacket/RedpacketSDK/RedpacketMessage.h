//
//  RedpacketMessage.h
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-6.
//  Copyright © 2016年 云帐户. All rights reserved.
//


#import "RedpacketMessageModel.h"
#import "XHMessage.h"

@class AVIMMessage;
@class AVIMTextMessage;
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

@interface AVIMMessage (Redpacket)
// 注意：由于这里已经有了红包的信息，如果要自己设置新属性的话，一定要保留红包的信息
@property(nonatomic, strong)NSDictionary *attributes;
@property (nonatomic, readonly, strong) RedpacketMessageModel *redpacket;
+ (instancetype)messageWithRedpacket:(RedpacketMessageModel *)redpacket;
- (BOOL)isRedpacket;
// 原始的 Message 只有一个Payload，而- [isRedpacket] 只检查 attributes 但不对它进行修改，所以需要这个方法直接检查 payload 的属性
// isRedpacket 更多的是为了 AVIMTextMessage 及他们的子类所使用
- (BOOL)isRedpacketPayload;
- (NSString *)redpacketString;
@end

#pragma mark - AVIMTypedMessage 的红包功能扩展
// 这里只使用 AVIMTextMessage 的 attributes 来传递红包信息
@interface AVIMTextMessage (Redpacket)

@end

#pragma mark - 自定义的抢红包消息
// 但是不能让所有人都显示红包被抢消息，所以使用自定义通用类型的消息，这样默认的 demo 是不作处理的
@interface RedpacketTakenAVIMMessage : AVIMMessage
@end

// 对于支持红包的程序，则转成 AVIMTypedMessage，这样由 ViewController 转成内部支持 XHMessage
@interface RedpacketTakenAVIMTypedMessage : AVIMTypedMessage
+ (instancetype)messageWithAVIMMessage:(AVIMMessage *)avimmessage;
@end
