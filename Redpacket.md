LeanCloud红包 SDK 接入文档
=================

使用 LeanCloud demo app
------------------

`红包 SDK` 的 demo 直接嵌入进 LeanCloud demo 2.0 中，对于原 demo 仅做了少量的修改。如果你的 app 采用 LeanCloud 的 demo app 作为原型的话，这里的方法是简单快捷的。

在LeanCloud demo app 里做的修改添加了相关的 `#pragma mark` 标记，可以在 Xcode 快速跳转到相应的标记

##1. clone demo:[ https://github.com/YunzhanghuOpen/leanchat-ios](https://github.com/YunzhanghuOpen/leanchat-ios)

`git clone https://github.com/YunzhanghuOpen/leanchat-ios`

具体参考
`https://github.com/YunzhanghuOpen/leanchat-ios/blob/master/README.md`
来进行更新


##2. 下载最新的红包 SDK 库文件 ( master 或者是 release )

因为`红包 SDK` 在一直更新维护，所以为了不与 demo 产生依赖，所以采取了单独下载 zip 包的策略

[https://github.com/YunzhanghuOpen/iOSRedpacketLib](https://github.com/YunzhanghuOpen/iOSRedpacketLib)

解压后将 RedpacketLib 复制至 leanchat-ios/Redpacket 目录下。

##3. LeanChat/LeanChat.xcworkspace

在工程中Redpacket文件夹中导入RedpacketLib文件夹。如遇到`file not fond`
请在 `Pods.xcodeproj` 的 `LeanChatLib Target` 的 `Build Settings` 下的 `User Header Search Path` 中查看路径设置是否正确

##4. 设置红包信息

在用户获取到IMtoken时

```objc
#pragma mark - 配置红包信息
[RedpacketConfig configRedpacket];
```
执行`红包 SDK` 的信息注册

退出登录时需调用
```objc
#pragma mark - 红包相关功能
[RedpacketConfig logout];
```
来清理`红包 SDK` 的信息注册
如对注册信息有其他要求,请自行参考`RedpacketConfig`实现和`YZHRedpacketBridge`所提供API

##5. 在聊天对话中添加红包支持API

1) 添加类支持

在 LeanCloud demo app 中已经实现 `CDChatVC` ，为了尽量不改动原来的代码，我们重新定义 `CDChatVC` 的子类 `RedpacketDemoViewController`。

在 `LeanChat/Manager/CDIMService.m` 中的

```objc
- (void)pushToChatRoomByConversation:(AVIMConversation *)conversation fromNavigation:(UINavigationController *)navigation completion:(CompletionBlock)completion {
```

找到并修改`CDChatVC`的实例化为`RedpacketDemoViewController`的实例化

2) 添加红包功能

查看 `RedpacketDemoViewController.m` 的 源代码注释了解红包功能的。

添加的部分包括：

    (1) 注册消息显示 Cell
    (2) 设置红包插件界面
    (3) 设置红包功能相关的参数
    (4) 设置红包接收用户信息
    (5) 设置红包 SDK 功能回调

##6. 显示零钱功能

通过执行
```objc
[RedpacketViewControl presentChangeMoneyViewController]
```

##7. 抢红包的消息使用的是 AVIMMessage 格式，为了处理这一格式，在 LeaChatLib/LeanChatLib/Classes/data/CDChatManager.m 里做相应的修改，详见代码中 pragma mark 标记的 "红包相关修改"