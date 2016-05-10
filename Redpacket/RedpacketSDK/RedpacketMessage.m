//
//  RedpacketMessage.m
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-6.
//  Copyright © 2016年 云帐户. All rights reserved.
//
#import <LeanChatLib/LeanChatLib.h>
#import "AVIMTextMessage.h"

#import "RedpacketMessage.h"

#import <AVOSCloud/AVOSCloud.h>
#import "CDChatManager.h"
#import <objc/runtime.h>

static NSString *const RedpacketDictKey = @"redpacket";
static NSString *const RedpacketTypeDictKey = @"type";
static NSString *const RedpacketTakenTypeValue = @"redpacket_taken";
static NSString *const RedpacketUserDictKey = @"redpacket_user";
static NSString *const RedpacketUserIdKey = @"id";
static NSString *const RedpacketUserNameKey = @"username";

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

- (NSString *)redpacketString
{
    if (RedpacketMessageTypeRedpacket == self.redpacket.messageType) {
        return [NSString stringWithFormat:@"[云红包]%@", self.redpacket.redpacket.redpacketGreeting];
    }
    else if (RedpacketMessageTypeTedpacketTakenMessage == self.redpacket.messageType) {
        NSDictionary *user = self.redpacketPayload[RedpacketUserDictKey];
        NSString *s = nil;
        if([self.redpacket.currentUser.userId isEqualToString:self.redpacket.redpacketReceiver.userId]) {
            // 显示我抢了别人的红包的提示
            s =[NSString stringWithFormat:@"%@%@%@", // 你领取了 XXX 的红包
                NSLocalizedString(@"你领取了", @"领取红包消息"),
                user[RedpacketUserNameKey],
                NSLocalizedString(@"的红包", @"领取红包消息结尾")
                ];
        }
        else { // 收到了别人抢了我的红包的消息提示
            s = [NSString stringWithFormat:@"%@%@", // XXX 领取了你的红包
                 user[RedpacketUserNameKey],
                 NSLocalizedString(@"领取了你的红包", @"领取红包消息")];
        }
        return s;
    }
    return @"";
}

@end

#pragma mark - AVIMTypedMessage (Redpacket)
// 因为后面抢红包的消息也需要同样的接口，所以把扩展做到 AVIMTypedMessage 上
// 这是一些通用需要的实现

@implementation AVIMMessage (Redpacket)
@dynamic redpacketPayload;
@dynamic redpacketChecked;

+ (instancetype)messageWithRedpacket:(RedpacketMessageModel *)redpacket
{
    id message = [self messageWithContent:@"[云红包]"];
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
            userDict[RedpacketUserNameKey] = userName;
        }
        if (userId) {
            userDict[RedpacketUserIdKey] = userId;
        }
        if (userAvatar) {
            userDict[@"avatar"] = userAvatar;
        }
        if (userDict.count) {
            attributes[RedpacketUserDictKey] = userDict;
        }
        
        [message setRedpacketPayload:attributes];
        [message setRedpacket:redpacket];
    }
    return message;
}

- (void)setRedpacketChecked:(BOOL)checked
{
    objc_setAssociatedObject(self, @selector(redpacketChecked), (__bridge id)(void *)checked, OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)redpacketChecked
{
    return (BOOL)(__bridge void *) objc_getAssociatedObject(self, @selector(redpacketChecked));
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
        if (self.redpacketPayload) {
            NSDictionary *rp = self.redpacketPayload[RedpacketDictKey];
            if (rp) {
                redpacket = [RedpacketMessageModel redpacketMessageModelWithDic:rp];
                self.redpacket = redpacket;
                return self.redpacket;
            }
        }
    }
    return redpacket;
}

// redpacketPayload 保存的是与 AVIMTypedMessage.attributes 同级别的信息
// 即 "redpacket":"..."
- (void)setRedpacketPayload:(NSDictionary *)attributes
{
    objc_setAssociatedObject(self, @selector(redpacketPayload), attributes, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary *)redpacketPayload
{
    NSDictionary *redpacket = objc_getAssociatedObject(self, @selector(redpacketPayload));
    // 如果为空且未检查过 payload
    if (nil == redpacket && !self.redpacketChecked) {
        self.redpacketChecked = YES;
        if (self.redpacket) {
            self.redpacketPayload = @{RedpacketDictKey: [self.redpacket redpacketMessageModelToDic]};
            return self.redpacketPayload;
        }
        // 如果是 AVIMTextMessage 消息，则应在 attributes 里带了 redpacket 的信息
        if ([self isKindOfClass:[AVIMTextMessage class]]) {
            // 如果是发的红包消息，是保存在消息的 attributes 属性里
            AVIMTextMessage *txtMessage = (AVIMTextMessage *)self;
            NSDictionary *dict = txtMessage.attributes[RedpacketDictKey];
            if(dict) {
                NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:2];
                d[RedpacketDictKey] = dict;
                d[RedpacketUserDictKey] = txtMessage.attributes[RedpacketUserDictKey];
                self.redpacketPayload = d;
                return self.redpacketPayload;
            }
        }
        // 如果是 抢红包消息，保存在 AVIMMessage 中传输，直接使用 payload
        NSData *payload = [self.payload dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:payload
                                                             options:0
                                                               error:&error];
        NSDictionary *redpacketDict = dict[RedpacketDictKey];
        if (redpacketDict) {
            NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:2];
            d[RedpacketDictKey] = redpacketDict;
            d[RedpacketUserDictKey] = dict[RedpacketUserDictKey];
            self.redpacketPayload = d;
            return self.redpacketPayload;
        }
    }
    return redpacket;
}

- (BOOL)isRedpacket
{
    return (nil != self.redpacketPayload[RedpacketDictKey]);
}

- (NSString *)redpacketString
{
    if (RedpacketMessageTypeRedpacket == self.redpacket.messageType) {
        return [NSString stringWithFormat:@"[云红包]%@", self.redpacket.redpacket.redpacketGreeting];
    }
    else if (RedpacketMessageTypeTedpacketTakenMessage == self.redpacket.messageType) {
        NSDictionary *user = self.redpacketPayload[RedpacketUserDictKey];
        NSString *s = nil;
        if([self.redpacket.currentUser.userId isEqualToString:self.redpacket.redpacketReceiver.userId]) {
            // 显示我抢了别人的红包的提示
            s =[NSString stringWithFormat:@"%@%@%@", // 你领取了 XXX 的红包
                NSLocalizedString(@"你领取了", @"领取红包消息"),
                user[RedpacketUserNameKey],
                NSLocalizedString(@"的红包", @"领取红包消息结尾")
                ];
        }
        else { // 收到了别人抢了我的红包的消息提示
            s = [NSString stringWithFormat:@"%@%@", // XXX 领取了你的红包
                 user[RedpacketUserNameKey],
                 NSLocalizedString(@"领取了你的红包", @"领取红包消息")];
        }
        return s;
    }
    return @"";
}
@end

@implementation AVIMTextMessage (Redpacket)

+ (instancetype)messageWithRedpacket:(RedpacketMessageModel *)redpacket
{
    AVIMTextMessage* message = [super messageWithRedpacket:redpacket];
    message.text = NSLocalizedString(@"当前版本不支持红包消息", @"当前版本不支持红包消息");
    message.attributes = [message.redpacketPayload copy];
    return message;
}

@end

#pragma mark - RedpacketTakenAVIMMessage
@interface RedpacketTakenAVIMMessage ()

@property (nonatomic, readwrite, strong) RedpacketMessageModel *redpacket;

@end

@implementation RedpacketTakenAVIMMessage

- (NSString *)payload
{
    NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:self.redpacketPayload];
    payload[RedpacketTypeDictKey] = RedpacketTakenTypeValue;
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

@implementation RedpacketTakenAVIMTypedMessage
+ (instancetype)messageWithAVIMMessage:(AVIMMessage *)avimmessage
{
    RedpacketTakenAVIMTypedMessage* message = [self messageWithRedpacket:avimmessage.redpacket];
    message.content = avimmessage.content;
    message.sendTimestamp = avimmessage.sendTimestamp;
    message.deliveredTimestamp = avimmessage.deliveredTimestamp;
    message.redpacketPayload = avimmessage.redpacketPayload;
    return message;
    
}

+ (AVIMMessageMediaType)classMediaType
{
    return REDPACKET_TAG;
}

+ (void)load {
    [self registerSubclass];
}

- (instancetype)init {
    if ((self = [super init])) {
        self.mediaType = [[self class] classMediaType];
    }
    return self;
}

@end
