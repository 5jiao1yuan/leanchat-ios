//
//  RedpacketConfig.m
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-4-25.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "RedpacketConfig.h"
#import <AVOSCloud/AVOSCloud.h>
#import "CDChatManager.h"
#import <objc/runtime.h>
#import "AFNetworking.h"

#import "YZHRedpacketBridge.h"
#import "RedpacketMessageModel.h"

//	*此为演示地址* App需要修改为自己AppServer上的地址, 数据格式参考此地址给出的格式。
static NSString *requestUrl = @"https://rpv2.yunzhanghu.com/api/sign?duid=";

@interface RedpacketConfig ()

@end

@implementation RedpacketConfig

+ (instancetype)sharedConfig
{
    static RedpacketConfig *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[RedpacketConfig alloc] init];
        [[YZHRedpacketBridge sharedBridge] setDataSource:config];
    });
    return config;
}

+ (void)config
{
    [[self sharedConfig] config];
}

+ (void)logout
{
    [[YZHRedpacketBridge sharedBridge] redpacketUserLoginOut];
}

+ (void)reconfig
{
    [self logout];
    [[self sharedConfig] config];
}

- (void)configWithSignDict:(NSDictionary *)dict
{
    NSString *partner = [dict valueForKey:@"partner"];
    NSString *appUserId = [dict valueForKey:@"user_id"];
    unsigned long timeStamp = [[dict valueForKey:@"timestamp"] unsignedLongValue];
    NSString *sign = [dict valueForKey:@"sign"];
    
    
    [[YZHRedpacketBridge sharedBridge] configWithSign:sign
                                              partner:partner
                                            appUserId:appUserId
                                            timeStamp:timeStamp];
}

- (void)config
{
    if(![[YZHRedpacketBridge sharedBridge] isRedpacketTokenExist]) {
        NSString *userId = [self userId];
        
        if (userId) {
            
            // 获取应用自己的签名字段。实际应用中需要开发者自行提供相应在的签名计算服务
            
            NSString *urlStr = [NSString stringWithFormat:@"%@%@",requestUrl, userId];
            NSURL *url = [NSURL URLWithString:urlStr];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            
            [[[AFHTTPRequestOperationManager manager] HTTPRequestOperationWithRequest:request
                                                                              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                                  if ([responseObject isKindOfClass:[NSDictionary class]]) {
                                                                                      [self configWithSignDict:responseObject];
                                                                                  }
                                                                              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                                  NSLog(@"request redpacket sign failed:%@", error);
                                                                              }] start];
        }
    }
}

- (RedpacketUserInfo *)redpacketUserInfo
{
    RedpacketUserInfo *user = [[RedpacketUserInfo alloc] init];
    id<CDUserModelDelegate> selfUser = [[CDChatManager manager].userDelegate getUserById:[AVUser currentUser].objectId];
    user.userId = [selfUser userId];
    user.userNickname = [selfUser username];
    user.userAvatar = [selfUser avatarUrl];
    return user;
}

- (NSString *)userId
{
    if ([[AVUser currentUser] isAuthenticated]) {
        return [AVUser currentUser].objectId;
    }

    return nil;
}
@end
