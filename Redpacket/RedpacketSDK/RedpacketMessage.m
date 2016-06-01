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

@import ObjectiveC;

static NSString *const RedpacketDictKey = @"redpacket";
static NSString *const RedpacketTypeDictKey = @"type";
static NSString *const RedpacketTakenTypeValue = @"redpacket_taken";

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

+ (NSString *)redpacketStringForRedpacket:(RedpacketMessageModel *)redpacket
{
    if (RedpacketMessageTypeRedpacket == redpacket.messageType) {
        return [NSString stringWithFormat:@"[云红包]%@", redpacket.redpacket.redpacketGreeting];
    }
    else if (RedpacketMessageTypeTedpacketTakenMessage == redpacket.messageType) {
        NSString *s = nil;
        if([redpacket.currentUser.userId isEqualToString:redpacket.redpacketReceiver.userId]) {
            // 显示我抢了别人的红包的提示
            if ([redpacket.redpacketSender.userId isEqualToString:redpacket.redpacketReceiver.userId]) {
                s = @"你领取了自己的红包";
            }
            else {
                s =[NSString stringWithFormat:@"%@%@%@", // 你领取了 XXX 的红包
                    NSLocalizedString(@"你领取了", @"领取红包消息"),
                    redpacket.redpacketSender.userNickname,
                    NSLocalizedString(@"的红包", @"领取红包消息结尾")
                    ];
            }
        }
        else { // 收到了别人抢了我的红包的消息提示
            s = [NSString stringWithFormat:@"%@%@", // XXX 领取了你的红包
                 redpacket.redpacketReceiver.userNickname,
                 NSLocalizedString(@"领取了你的红包", @"领取红包消息")];
        }
        return s;
    }
    return @"";
}

- (NSString *)redpacketString
{
    return [RedpacketMessage redpacketStringForRedpacket:self.redpacket];
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
    return [RedpacketMessage redpacketStringForRedpacket:self.redpacket];
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

    [message customSetConversationId:avimmessage.conversationId];
    [message customSetMessageId:avimmessage.messageId];
    [message customSetClientId:avimmessage.clientId];
 
    return message;
}

- (void)customSetClientId:(NSString *)clientId
{
    SEL method = @selector(setClientId:);
    [self callVoidSuperClass:[AVIMMessage class]
                      method:method
                  withObject:clientId];
}
     
- (void)customSetMessageId:(NSString *)messageId
{
    SEL method = @selector(setMessageId:);
    [self callVoidSuperClass:[AVIMMessage class]
                      method:method
                  withObject:messageId];
}

- (void)customSetConversationId:(NSString *)conversationId
{
    SEL method = @selector(setConversationId:);
    [self callVoidSuperClass:[AVIMMessage class]
                      method:method
                  withObject:conversationId];
}

- (void)callVoidSuperClass:(Class)class method:(SEL)method withObject:(id)object
{
    struct objc_super mySuper;
    mySuper.receiver = self;
    mySuper.super_class = class;
    
    // 必须先把原先的方法强制转成特定的函数指针形式才可以执行
    // 必须对应参数的类型，不能使用强制转换的类型（因为 ARC 会使编译器对 ObjectiveC 对象 进行 retain/release 操作，如果参数为标量
    // 则必须将参数类型指明，否则引起异常
    ((void (*)(struct objc_super *, SEL, id))objc_msgSendSuper)(&mySuper, method, object);
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
