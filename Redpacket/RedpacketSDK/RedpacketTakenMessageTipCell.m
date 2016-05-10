//
//  RedpacketTakenMessageTipCell.m
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-7.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "RedpacketTakenMessageTipCell.h"
#import "RedpacketMessage.h"

#define REDPACKET_BUNDLE(name) @"RedpacketCellResource.bundle/" name
#define BACKGROUND_LEFT_RIGHT_PADDING 10
#define ICON_LEFT_RIGHT_PADDING 2
#define REDPACKET_TAKEN_MESSAGE_TOP_BOTTOM_PADDING 20
#define REDPACKET_MESSAGE_TOP_BOTTOM_PADDING 20

@interface RedpacketTakenMessageTipCell ()
@property(nonatomic, strong) UIView *bgView;
@property (nonatomic, weak) UIView *baseContentView;

@property(strong, nonatomic) UILabel *tipMessageLabel;
@property(strong, nonatomic) UIImageView *iconView;
@property (nonatomic, strong, readwrite) id<XHMessageModel> message;
@end

@implementation RedpacketTakenMessageTipCell

- (instancetype)initWithMessage:(id<XHMessageModel>)message reuseIdentifier:(NSString *)cellIdentifier {
    self = [super initWithMessage:message reuseIdentifier:cellIdentifier];
    if (self) {
        self.message = message;
        self.baseContentView = self.contentView;
        [self.messageBubbleView removeFromSuperview];
        [self performSelector:@selector(setMessageBubbleView:) withObject:nil];
        
        [self initialize];
        
    }
    return self;
}

- (void)initialize {
    
    self.baseContentView.backgroundColor = [UIColor clearColor];
    
    self.bgView = [[UIView alloc] initWithFrame:self.baseContentView.bounds];
    self.bgView.userInteractionEnabled = NO;
    self.bgView.backgroundColor = [UIColor colorWithRed:0xdd * 1.0f / 255.0f
                                                  green:0xdd * 1.0f / 255.0f
                                                   blue:0xdd * 1.0f / 255.0f
                                                  alpha:1.0f];
    self.bgView.autoresizingMask = UIViewAutoresizingNone;
    self.bgView.layer.cornerRadius = 4.0f;
    [self.baseContentView addSubview:self.bgView];
    
    self.tipMessageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.tipMessageLabel.font = [UIFont systemFontOfSize:12];
    self.tipMessageLabel.textColor = [UIColor colorWithRed:0x9e * 1.0f / 255.0f
                                                     green:0x9e * 1.0f / 255.0f
                                                      blue:0x9e * 1.0f / 255.0f
                                                     alpha:1.0f];
    self.tipMessageLabel.userInteractionEnabled = NO;
    self.tipMessageLabel.numberOfLines = 1;
    [self.bgView addSubview:self.tipMessageLabel];
    
    self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 12, 15)];
    self.iconView.image = [UIImage imageNamed:REDPACKET_BUNDLE(@"redpacket_smallIcon")];
    self.iconView.userInteractionEnabled = NO;
    [self.bgView addSubview:self.iconView];
}

- (void)configureMessageBubbleViewWithMessage:(id<XHMessageModel>)message {
    
    assert([message isKindOfClass:[RedpacketMessage class]]);
    RedpacketMessage *m = (RedpacketMessage *)message;
    self.tipMessageLabel.text = [m redpacketString];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.tipMessageLabel sizeToFit];
    
    CGRect frame = self.tipMessageLabel.frame;
    CGRect iconFrame = self.iconView.frame;
    CGRect bgFrame = CGRectMake(0, 0,
                                frame.size.width + iconFrame.size.width + 2 * BACKGROUND_LEFT_RIGHT_PADDING,
                                22);
    
    frame.origin.y = (bgFrame.size.height - frame.size.height) * 0.5;
    iconFrame.origin.x = BACKGROUND_LEFT_RIGHT_PADDING - ICON_LEFT_RIGHT_PADDING;
    iconFrame.origin.y = frame.origin.y + (frame.size.height - iconFrame.size.height) * 0.5;
    self.iconView.frame = iconFrame;
    
    frame.origin.x = ICON_LEFT_RIGHT_PADDING + iconFrame.origin.x + iconFrame.size.width;
    self.tipMessageLabel.frame = frame;
    
    
    bgFrame.origin.y = REDPACKET_TAKEN_MESSAGE_TOP_BOTTOM_PADDING;
    bgFrame.origin.x = (self.baseContentView.bounds.size.width - bgFrame.size.width) * 0.5;
    
    self.bgView.frame = bgFrame;
}

+ (CGFloat)calculateCellHeightWithMessage:(id<XHMessageModel>)message
                        displaysTimestamp:(BOOL)displayTimestamp
                         displaysPeerName:(BOOL)displayPeerName
{
    return 40; //
}

- (void)configPeerName:(BOOL)displayPeerName atMessage:(id<XHMessageModel>)message {
}

- (void)configAvatorWithMessage:(id<XHMessageModel>)message {
    self.avatorButton.hidden = YES;
}
@end
