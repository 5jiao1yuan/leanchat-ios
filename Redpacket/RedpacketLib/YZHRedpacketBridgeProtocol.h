//
//  YZHRedpacketBridgeProtocol.h
//  RedpacketLib
//
//  Created by Mr.Yang on 16/4/8.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#ifndef YZHRedpacketBridgeProtocol_h
#define YZHRedpacketBridgeProtocol_h

@class RedpacketUserInfo;

typedef NS_ENUM(NSInteger, RequestTokenMethod) {
    RequestTokenMethodByImToken,
    RequestTokenMethodBySign
};

@protocol YZHRedpacketBridgeDataSource <NSObject>

- (RedpacketUserInfo *)redpacketUserInfo;

@end


@protocol YZHRedpacketBridgeDelegate <NSObject>

- (void)redpacketUserTokenGetInfoByMethod:(RequestTokenMethod)method;

@end


#endif /* YZHRedpacketBridgeProtocol_h */
