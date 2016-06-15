LeanCloud红包 SDK 接入文档
=================

使用 LeanCloud demo app
------------------

  `红包 SDK` 的 demo 直接嵌入进 LeanCloud demo 2.0 中，对于原 demo 仅做了少量的修改。如果你的 app 采用 LeanCloud 的 demo app 作为原型的话，这里的方法是简单快捷的。

  在LeanCloud demo app 里做的修改添加了相关的 `#pragma mark` 标记，可以在 Xcode 快速跳转到相应的标记

1. clone demo:[ https://github.com/YunzhanghuOpen/leanchat-ios](https://github.com/YunzhanghuOpen/leanchat-ios)

  `git clone https://github.com/YunzhanghuOpen/leanchat-ios`

  如果已有代码，需要执行

  `git pull --rebase`

  来进行更新。

  1.1 如果是想直接使用已做好的例子，请使用 `git checkout origin/Redpacket -b redpacket` 来直接使用已经修改好的代码, 并且以下的步骤可以省略

2. 下载最新的红包 SDK 库文件 ( master 或者是 release )

  因为`红包 SDK` 在一直更新维护，所以为了不与 demo 产生依赖，所以采取了单独下载 zip 包的策略

  [https://github.com/YunzhanghuOpen/iOSRedpacketLib](https://github.com/YunzhanghuOpen/iOSRedpacketLib)

  解压后将 RedpacketLib 复制至 leanchat-ios 目录下。

3. 通过 Terminal 进入 LeanChat 目录，执行(需要安装 CocoaPods)

    `pod install`
    
    开启 LeanChat/LeanChat.xcworkspace/ 工程文件

    3.1  开启的工程里，需要在 Pods.xcodeproj 的 LeanChatLib Target 的 Build Settings 下的 User Header Search Path 中添加

    `$(PROJECT_DIR)/../Redpacket/RedpacketLib` 和 `$(PROJECT_DIR)/../Redpacket/RedpacketSDK`

4. 设置红包信息

  在 `AppDelegate.m` 中的
  ```objc
  - (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
  ```

  最后添加了

    ```objc
    #pragma mark - 配置红包信息
    [RedpacketConfig configRedpacket];
    ```

  `RedpacketConfig` 类有两个作用。

    1) 它实现了 `YZHRedpacketBridgeDataSource` protocol，并在 Singleton 创建对象的时候设置了

      `[[YZHRedpacketBridge sharedBridge] setDataSource:config];`

      `YZHRedpacketBridgeDataSource` protocol 用以为红包 SDK 提供用户信息

    2) 它用于执行`YZHRedpacketBridge` 的

    ```objc
    - (void)configWithSign:(NSString *)sign
               partner:(NSString *)partner
             appUserId:(NSString *)appUserid
             timeStamp:(long)timeStamp;
    ```

    以执行`红包 SDK` 的信息注册

5. 在聊天对话中添加红包支持

  1) 添加类支持

  在 LeanCloud demo app 中已经实现 `CDChatVC` ，为了尽量不改动原来的代码，我们重新定义 `CDChatVC` 的子类 `RedpacketDemoViewController`。

  但是由于 LeanCloud 本身 demo 架构的缺陷，中间加了一层 'RedpacketHackViewController' 解决一些子类访问父类方法的问题

  在 `LeanChat/Manager/CDIMService.m` 中的

  ```objc
  - (void)pushToChatRoomByConversation:(AVIMConversation *)conversation fromNavigation:(UINavigationController *)navigation completion:(CompletionBlock)completion {
  ```

      找到并修改

  ```objc
  //如果是从类似朋友圈的地方跳转来，则重新 push 到一个新创建的聊天界面
      CDAppDelegate *delegate = ((CDAppDelegate *)[[UIApplication sharedApplication] delegate]);
      UIWindow *window = delegate.window;
          UITabBarController *tabbarController = (UITabBarController *)window.rootViewController;
#pragma mark - 创建支持红包功能的聊天界面
              CDChatVC *chatVC = [[RedpacketDemoViewController alloc] initWithConversation:conversation];
#pragma mark -
                  chatVC.hidesBottomBarWhenPushed = YES;
  ...
  ```

  2) 添加红包功能

  查看 `RedpacketDemoViewController.m` 的 源代码注释了解红包功能的。

    添加的部分包括：

        (1) 注册消息显示 Cell
       (2) 设置红包插件界面
       (3) 设置红包功能相关的参数
       (4) 设置红包接收用户信息
       (5) 设置红包 SDK 功能回调

6. 显示零钱功能

  通过执行

```objc
  - [RedpacketViewControl presentChangeMoneyViewController]
```

7. 抢红包的消息使用的是 AVIMMessage 格式，为了处理这一格式，在 LeaChatLib/LeanChatLib/Classes/data/CDChatManager.m 里做相应的修改，详见代码中 pragma mark 标记的 "红包相关修改"

