//
//  RedpacketUserAccount.h
//  ChatDemo-UI3.0
//
//  Created by Mr.Yang on 16/3/1.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YZHRedpacketBridgeProtocol.h"


@interface YZHRedpacketBridge : NSObject

/*
 *  主动获取昵称和头像，用户修改后可以及时获取最新的数据
 */
//@property (nonatomic, weak) id <YZHRedpacketBridgeDelegate> delegate;

@property (nonatomic, weak) id <YZHRedpacketBridgeDataSource>dataSource;


+ (YZHRedpacketBridge *)sharedBridge;

@property (nonatomic, assign) BOOL isRedpacketTokenValidate;

#pragma mark - 通过签名的方式获取Token
- (void)configWithSign:(NSString *)sign
               partner:(NSString *)partner
             appUserId:(NSString *)appUserid
             timeStamp:(long)timeStamp;

#pragma mark - 通过验证imToken的方式获取Token
- (void)configWithAppKey:(NSString *)appKey
               appUserId:(NSString *)appUserId
                imUserId:(NSString*)imUserId
           andImUserpass:(NSString *)userPass;

/**
 *  用户退出登录，在其它地点登录后，清除用户信息
 */
- (void)redpacketUserLoginOut;

/**
 *   重新请求红包用户Token
 */
- (void)reRequestRedpacketUserToken;



@end
