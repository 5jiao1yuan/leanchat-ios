//
//  RedpacketMessageCell.h
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-7.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import <LeanChatLib/LeanChatLib.h>
#import "RedpacketMessage.h"

@class RedpacketMessageCell;
@protocol RedpacketCellDelegate <NSObject>

- (void)redpacketCell:(RedpacketMessageCell *)cell didTap:(RedpacketMessage *)message;

@end

@interface RedpacketMessageCell : XHMessageTableViewCell
@property (nonatomic, strong, readonly) id<XHMessageModel> message;
@property (nonatomic, weak, readwrite) id<RedpacketCellDelegate> redpacketDelegate;
@end
