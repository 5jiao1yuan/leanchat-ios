//
//  RedpacketMessageCell.m
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-7.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "RedpacketMessageCell.h"

@import ObjectiveC;

#define Redpacket_Message_Font_Size 14
#define Redpacket_SubMessage_Font_Size 12
#define Redpacket_Background_Extra_Height 25
#define Redpacket_SubMessage_Text NSLocalizedString(@"查看红包", @"查看红包")
#define Redpacket_Label_Padding 2

#define REDPACKET_BUNDLE(name) @"RedpacketCellResource.bundle/" name

// 下面的常量来自 XHMessageTableViewCell.m
static const CGFloat kXHAvatorPaddingX = 8.0;
static const CGFloat kXHAvatorPaddingY = 15;
//气泡底部距离ContentView底部的距离
static const CGFloat kXHBubbleMessageViewTopPadding = 0;
static const CGFloat kXHBubbleMessageViewBottomPadding = 8;
static const CGFloat kXHPeerNameLabelHeight = 20.0f;

@interface RedpacketMessageCell ()
@property(strong, nonatomic) UILabel *greetingLabel;
@property(strong, nonatomic) UILabel *subLabel; // 显示 "查看红包"
@property(strong, nonatomic) UILabel *orgLabel;
@property(strong, nonatomic) UIImageView *iconView;
@property(strong, nonatomic) UIImageView *orgIconView;

@property(nonatomic, strong) UIImageView *bubbleBackgroundView;

@property (nonatomic, weak) UIView *messageContentView;

@property (nonatomic, strong, readwrite) id<XHMessageModel> message;
@end

@implementation RedpacketMessageCell

- (instancetype)initWithMessage:(id<XHMessageModel>)message reuseIdentifier:(NSString *)cellIdentifier {
    self = [super initWithMessage:message reuseIdentifier:cellIdentifier];
    if (self) {
        self.message = message;
        self.messageContentView = self.contentView;
        [self.messageBubbleView removeFromSuperview];
        [self performSelector:@selector(setMessageBubbleView:) withObject:nil];
        
        CGFloat bubbleX = 0.0f;
        CGFloat offsetX = 0.0f;
        CGFloat bubbleViewHeight = [[self class] getBubbleSize].height;
        CGFloat bubbleViewY;
        
        if (message.bubbleMessageType == XHBubbleMessageTypeReceiving) {
            bubbleX = kXHAvatorImageSize + 2 * kXHAvatorPaddingX;
            bubbleViewY = CGRectGetMinY(self.avatorButton.frame) + kXHBubbleMessageViewTopPadding;
        } else {
            offsetX = kXHAvatorImageSize + 2 * kXHAvatorPaddingX;
            bubbleViewY = CGRectGetMinY(self.avatorButton.frame) + kXHBubbleMessageViewTopPadding + kXHPeerNameLabelHeight;
        }
        
        CGRect frame = CGRectMake(bubbleX,
                                  bubbleViewY,
                                  self.contentView.frame.size.width - bubbleX - offsetX,
                                  bubbleViewHeight);
        // 设置背景
        self.bubbleBackgroundView = [[UIImageView alloc] initWithFrame:frame];
        [self.messageContentView addSubview:self.bubbleBackgroundView];
        
        [self initialize];
    
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    

    self.bubbleBackgroundView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.bubbleBackgroundView addGestureRecognizer:tap];
    
    // 设置红包图标
    UIImage *icon = [UIImage imageNamed:REDPACKET_BUNDLE(@"redPacket_redPacktIcon")];
    self.iconView = [[UIImageView alloc] initWithImage:icon];
    self.iconView.frame = CGRectMake(13, 19, 26, 34);
    [self.bubbleBackgroundView addSubview:self.iconView];
    
    // 设置红包文字
    self.greetingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.greetingLabel.frame = CGRectMake(48, 19, 137, 15);
    self.greetingLabel.font = [UIFont systemFontOfSize:Redpacket_Message_Font_Size];
    self.greetingLabel.textColor = [UIColor whiteColor];
    self.greetingLabel.numberOfLines = 1;
    [self.greetingLabel setLineBreakMode:NSLineBreakByCharWrapping];
    [self.greetingLabel setTextAlignment:NSTextAlignmentLeft];
    [self.bubbleBackgroundView addSubview:self.greetingLabel];
    
    // 设置次级文字
    self.subLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    CGRect frame = self.greetingLabel.frame;
    frame.origin.y = 41;
    self.subLabel.frame = frame;
    self.subLabel.text = Redpacket_SubMessage_Text;
    self.subLabel.font = [UIFont systemFontOfSize:Redpacket_SubMessage_Font_Size];
    self.subLabel.numberOfLines = 1;
    self.subLabel.textColor = [UIColor whiteColor];
    self.subLabel.numberOfLines = 1;
    [self.subLabel setLineBreakMode:NSLineBreakByCharWrapping];
    [self.subLabel setTextAlignment:NSTextAlignmentLeft];
    [self.bubbleBackgroundView addSubview:self.subLabel];
    
    // 设置次级文字
    self.orgLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    frame = CGRectMake(13, 76, 150, 12);
    self.orgLabel.frame = frame;
    self.orgLabel.text = Redpacket_SubMessage_Text;
    self.orgLabel.font = [UIFont systemFontOfSize:Redpacket_SubMessage_Font_Size];
    self.orgLabel.numberOfLines = 1;
    self.orgLabel.textColor = [UIColor lightGrayColor];
    self.orgLabel.numberOfLines = 1;
    [self.orgLabel setLineBreakMode:NSLineBreakByCharWrapping];
    [self.orgLabel setTextAlignment:NSTextAlignmentLeft];
    [self.bubbleBackgroundView addSubview:self.orgLabel];
    
    // 设置红包厂商图标
    icon = [UIImage imageNamed:REDPACKET_BUNDLE(@"redPacket_yunAccount_icon")];
    self.orgIconView = [[UIImageView alloc] initWithImage:icon];
    [self.bubbleBackgroundView addSubview:self.orgIconView];
    
    
    CGRect rt = self.orgIconView.frame;
    rt.origin = CGPointMake(165, 75);
    rt.size = CGSizeMake(21, 14);
    self.orgIconView.frame = rt;
    
    UIView *statusView = [self performSelector:@selector(statusView)];
    statusView.hidden = YES;
}

- (void)configureMessageBubbleViewWithMessage:(id<XHMessageModel>)message {
    
    assert([message isKindOfClass:[RedpacketMessage class]]);
    self.message = message;
    RedpacketMessage *redpacketMessage = (RedpacketMessage *)message;
    NSString *messageString = redpacketMessage.redpacket.redpacket.redpacketGreeting;
    self.greetingLabel.text = messageString;
    
    NSString *orgString = redpacketMessage.redpacket.redpacket.redpacketOrgName;
    self.orgLabel.text = orgString;
    
    CGSize bubbleBackgroundViewSize = [[self class] getBubbleSize];
    CGRect messageContentViewRect = self.messageContentView.frame;
    
    // 设置红包文字
    if (XHBubbleMessageTypeReceiving == message.bubbleMessageType) {
        messageContentViewRect.size.width = bubbleBackgroundViewSize.width;
        self.messageContentView.frame = messageContentViewRect;
        
        self.bubbleBackgroundView.frame = CGRectMake(-8, 0, bubbleBackgroundViewSize.width, bubbleBackgroundViewSize.height);
        UIImage *image = [UIImage imageNamed:REDPACKET_BUNDLE(@"redpacket_receiver_bg")];
        self.bubbleBackgroundView.image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(70, 9, 25, 20)];
    } else {
        
        messageContentViewRect.size.width = bubbleBackgroundViewSize.width;
        messageContentViewRect.origin.x = self.messageContentView.bounds.size.width - (messageContentViewRect.size.width + 12 + 50 /*头像部分尺寸*/ + 10);
        self.messageContentView.frame = messageContentViewRect;
        
        self.bubbleBackgroundView.frame = CGRectMake(8, 0, bubbleBackgroundViewSize.width, bubbleBackgroundViewSize.height);
        UIImage *image = [UIImage imageNamed:REDPACKET_BUNDLE(@"redpacket_sender_bg")];
        self.bubbleBackgroundView.image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(70, 9, 25, 20)];
    }
}

- (void)tap:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
//        [self.delegate didTapMessageCell:self.model];
        RedpacketMessage *redpacketMessage = (RedpacketMessage *)self.message;
        [self.redpacketDelegate redpacketCell:self didTap:redpacketMessage];
    }
}

+ (CGSize)getBubbleSize {
    CGSize bubbleSize = CGSizeMake(198, 94);
    return bubbleSize;
}

+ (CGSize)getBubbleBackgroundViewSize:(RedpacketMessage *)message {
    return [[self class] getBubbleSize];
}

+ (CGFloat)calculateCellHeightWithMessage:(id<XHMessageModel>)message
                        displaysTimestamp:(BOOL)displayTimestamp
                         displaysPeerName:(BOOL)displayPeerName
{
    if([message isKindOfClass:[RedpacketMessage class]]) {
        return [self getBubbleSize].height + 40;
    }
    else {
        return [super calculateCellHeightWithMessage:message
                                   displaysTimestamp:displayTimestamp
                                    displaysPeerName:displayPeerName];
    }
}

@end
