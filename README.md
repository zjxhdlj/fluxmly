# fluxmly

Flutter 喜马拉雅插件。
因为项目需要使用喜马拉雅SDK，故开发此插件

Android & IOS 通用

目前实现功能:

[✅] 初始化SDK

[✅] 获取猜你喜欢列表

[✅] 获取专辑信息

[✅] 初始化播放器

[✅] 播放器控制

[✅] 播放器回调


其他功能暂无使用，故没有开发，不过都差不多，举一反三也能完成

Android：

需要在AndroidManifest.xml中添加，注册播放器
<service android:name="com.ximalaya.ting.android.opensdk.player.service.XmPlayerService"
            android:process=":player" />


IOS：
Build Settings 下 Other Linker Flags 中添加 -lXMOpenPlatform
# Library Search Paths 中添加 $(PROJECT_DIR)/Frameworks
