消息格式
===========

发红包格式
-------

使用的 Text Message (iOS 类是 AVIMTextMessage)

文本内容是： “当前版本不支持红包消息”

附加属性格式：

```
    redpacket =     {
        ID = 16053022388bbd5217f44710918996d534fd2c2c;
        "is_money_msg" = 1;
        "money_greeting" = "\U606d\U559c\U53d1\U8d22\Uff0c\U5927\U5409\U5927\U5229\Uff01";
        "money_receiver_id" = 574bef13a3413100591cf36b;
        "money_sender" = sprhawk;
        "money_sender_id" = 572afddd1532bc0065d7e24f;
        "money_sponsor_name" = "\U4e91\U7ea2\U5305";
    };
    "redpacket_user" =     {
        id = 572afddd1532bc0065d7e24f;
        username = sprhawk;
    };
```

redpacket 的格式是由 iOS 库带的 API 生成的，之所以加了  redpacket_user 是因为库生成的信息不带把消息者的信息（主要是用户名，用于在界面上展示）

抢红包消息格式
---------

在默认的 iOS Demo 里，只有 AVIMMessage 类型的格式默认被 Demo 忽略，其他消息都会显示“不识别消息”，所以这里的方法是:

发送的消息是 AVIMMessage 消息，本地使用其他格式类（iOS 的实现上，只有 AVIMTypedMessage才能被本地操作）存储和操作

发送的消息格式是:

```
redpacket =     {
        ID = 16053022388bbd5217f44710918996d534fd2c2c;
        "is_open_money_msg" = 1;
        "money_greeting" = "\U606d\U559c\U53d1\U8d22\Uff0c\U5927\U5409\U5927\U5229\Uff01";
        "money_receiver" = sprhawk;
        "money_receiver_id" = 572afddd1532bc0065d7e24f;
        "money_sender" = sprhawk;
        "money_sender_id" = 572afddd1532bc0065d7e24f;
        "money_sponsor_name" = "\U4e91\U7ea2\U5305";
    };
    "redpacket_user" =     {
        id = 572afddd1532bc0065d7e24f;
        username = sprhawk;
    };
    type = "redpacket_taken";
```

这里只是增加了 `type = "redpacket_taken";`，

发红包消息里的`is_money_msg" = 1`变成了 `is_open_money_msg" = 1;`
