//
//  RedpacketHackViewController.h
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-9.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "CDChatVC.h"
#import "RedpacketMessage.h"

@interface RedpacketHackViewController : CDChatVC

- (void)sendCustomRedpacketMessage:(RedpacketMessage*)message;

@end
