//
//  RedpacketMessageModel.h
//  ChatDemo-UI3.0
//
//  Created by Mr.Yang on 16/3/8.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RedpacketOpenConst.h"


typedef NS_ENUM(NSInteger, RedpacketMessageType) {
    
    RedpacketMessageTypeRedpacket = 1001,
    RedpacketMessageTypeTedpacketTakenMessage,
    
};

typedef NS_ENUM(NSInteger, RedpacketType) {
    
    RedpacketTypeSingle = 2001,
    RedpacketTypeGroup
    
};

@interface RedpacketUserInfo : NSObject <NSCopying>

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *userNickname;
@property (nonatomic, copy) NSString *userAvatar;
@property (nonatomic, assign) BOOL isGroup;

@end

@interface RedpacketViewModel : NSObject <NSCopying>

@property (nonatomic, copy) NSString *redpacketGreeting;
@property (nonatomic, copy) NSString *redpacketOrgName;

//????:未来可定制化?
@property (nonatomic, copy) NSString *redpacketIcon;
@property (nonatomic, copy) NSString *redpacketOrgIcon;

@end

/**
 *  红包消息
 */
@interface RedpacketMessageModel : NSObject <NSCopying>

/**
 *  红包ID
 */
@property (nonatomic, copy, readonly) NSString *redpacketId;

/**
 *  红包消息类型，红包消息， 红包被领取的消息
 */
@property (nonatomic, assign) RedpacketMessageType messageType;

//  红包的类型
@property (nonatomic, assign) RedpacketType redpacketType;

/**
 *  当前用户是否是红包的发送者
 */
@property (nonatomic, assign, readonly) BOOL isRedacketSender;

/**
 *  当前用户信息
 */
@property (nonatomic, readonly) RedpacketUserInfo *currentUser;
/**
 *  红包发送者信息
 */
@property (nonatomic, strong) RedpacketUserInfo *redpacketSender;
/**
 *  红包接受者信息
 */
@property (nonatomic, strong) RedpacketUserInfo *redpacketReceiver;
/**
 *  红包视图相关信息
 */
@property (nonatomic, strong) RedpacketViewModel *redpacket;

/**
 *  红包相关信息外挂
 */
@property (nonatomic, strong)   NSDictionary *redpacketDetailDic;

/**
 *  是否红包相关信息
 *
 *  @param redpacketDic 红包消息，通过IM传递的信息字典
 *
 *  @return @YES 跟红包相关  @NO 跟红包无关
 */
+ (BOOL)isRedpacketRelatedMessage:(NSDictionary *)redpacketDic;
/**
 *  是否是红包信息
 *
 *  @param redpacketDic 红包消息，通过IM传递的信息字典
 *
 *  @return YES 是红包信息
 */
+ (BOOL)isRedpacket:(NSDictionary *)redpacketDic;
/**
 *  是否是红包被抢的消息
 *
 *  @param redpacketDic
 *
 *  @return 
 */
+ (BOOL)isRedpacketMessage:(NSDictionary *)redpacketDic;

+ (RedpacketMessageModel *)redpacketMessageModelWithDic:(NSDictionary *)redpacketDic;

- (void)configWithRedpacketDic:(NSDictionary *)repacketDic;

- (NSDictionary *)redpacketMessageModelToDic;


@end
