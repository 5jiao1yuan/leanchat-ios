//
//  RedpacketMessage.m
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-6.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "RedpacketMessage.h"

#import <AVOSCloud/AVOSCloud.h>
#import "CDChatManager.h"
#import <objc/runtime.h>

#pragma mark - RedpacketMessage

@interface RedpacketMessage ()

@property (nonatomic, readwrite, strong) RedpacketMessageModel *redpacket;

@end

@implementation RedpacketMessage

+ (instancetype)messageWithRedpacket:(RedpacketMessageModel *)redpacket
{
    return [[self alloc] initWithRedpacket:redpacket];
}

- (instancetype)initWithRedpacket:(RedpacketMessageModel *)redpacket
{
    id<CDUserModelDelegate> selfUser = [[CDChatManager manager].userDelegate getUserById:[AVUser currentUser].objectId];
    
    self.sender = [selfUser username];
    self.timestamp = [NSDate date];
    self.redpacket = redpacket;
    self.messageMediaType = XHBubbleMessageMediaTypeText;
    self.text = NSLocalizedString(@"当前版本不支持红包消息", @"当前版本不支持红包消息");
    return self;
}

@end

#pragma mark - AVIMTypedMessage (Redpacket)
// 因为后面抢红包的消息也需要同样的接口，所以把扩展做到 AVIMTypedMessage 上
// 这是一些通用需要的实现
static NSString *const RedpacketDictKey = @"redpacket";
static NSString *const RedpacketUserDictKey = @"redpacket_user";

@implementation AVIMMessage (Redpacket)
@dynamic attributes;
+ (instancetype)messageWithRedpacket:(RedpacketMessageModel *)redpacket
{
    id message = nil;
    if (redpacket) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:2];
        
        NSDictionary *rp = [redpacket redpacketMessageModelToDic];
        attributes[RedpacketDictKey] = rp;
        
        id<CDUserModelDelegate> selfUser = [[CDChatManager manager].userDelegate getUserById:[AVUser currentUser].objectId];
        NSString *userName = [selfUser username];
        NSString *userId = [selfUser userId];
        NSString *userAvatar = [selfUser avatarUrl];
        NSMutableDictionary *userDict = [NSMutableDictionary dictionaryWithCapacity:3];
        if (userName) {
            userDict[@"name"] = userName;
        }
        if (userId) {
            userDict[@"id"] = userId;
        }
        if (userAvatar) {
            userDict[@"avatar"] = userAvatar;
        }
        if (userDict.count) {
            attributes[RedpacketUserDictKey] = @{RedpacketUserDictKey : userDict};
        }
        
        message = [[self alloc] init];
        [message setAttributes:[attributes copy]];
        [message setRedpacket:redpacket];
    }
    return message;
}

- (void)setRedpacket:(RedpacketMessageModel *)redpacket
{
    objc_setAssociatedObject(self, @selector(redpacket), redpacket, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (RedpacketMessageModel *)redpacket
{
    RedpacketMessageModel *redpacket = objc_getAssociatedObject(self, @selector(redpacket));
    if(!redpacket) {
        // 如果是收到的文本消息，会没有 redpacket 对象
        if (self.attributes) {
            NSDictionary *rp = self.attributes[RedpacketDictKey];
            if (rp) {
                redpacket = [RedpacketMessageModel redpacketMessageModelWithDic:rp];
                objc_setAssociatedObject(self, @selector(redpacket), redpacket, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
    return redpacket;
}

- (void)setAttributes:(NSDictionary *)attributes
{
    objc_setAssociatedObject(self, @selector(attributes), attributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *)attributes
{
    return objc_getAssociatedObject(self, @selector(attributes));
}

- (BOOL)isRedpacket
{
    NSDictionary *rp = self.attributes[RedpacketDictKey];
    return (nil != rp);
}


@end

@implementation AVIMTextMessage (Redpacket)

+ (instancetype)messageWithRedpacket:(RedpacketMessageModel *)redpacket
{
    AVIMTextMessage* message = [super messageWithRedpacket:redpacket];
    message.text = NSLocalizedString(@"当前版本不支持红包消息", @"当前版本不支持红包消息");
    return message;
}

@end

#pragma mark - RedpacketTakenAVIMMessage
@interface RedpacketTakenAVIMMessage ()

@property (nonatomic, readwrite, strong) RedpacketMessageModel *redpacket;

@end

@implementation RedpacketTakenAVIMMessage
@synthesize redpacket = _redpacket;

+ (BOOL)isRedpacketTakenMessagePayload:(NSDictionary *)payload
{
    NSString *t = payload[@"type"];
    NSDictionary *dict = payload[@"redpacket"];
    if ([t isEqualToString:@"redpacket_taken"] && dict) {
        return YES;
    }
    return NO;
}

- (instancetype)init {
    if ((self = [super init])) {
    }
    return self;
}

- (NSString *)payload
{
    NSDictionary *dict = [self.redpacket redpacketMessageModelToDic];
    NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithCapacity:2];
    payload[@"type"] = @"redpacket_taken";
    payload[@"redpacket"] = dict;
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    if (error) {
        NSLog(@"cannot convert payload to json :%@", payload);
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
