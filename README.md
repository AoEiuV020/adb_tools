# adb_tools

flutter开发跨平台连接安卓adb工具集合，

## 计划中

1. 主页添加连接设备，包括安卓自己连接本机，
1. 连接设备点开管理页面，
1. 管理页面多标签，每个标签页是一个功能，不预加载，每个功能可以有自己的设置页，
1. 自带几个简单功能， 命令行，文件管理，安装apk，日志查看，
1. 想个办法支持拓展，比如更复杂的日志标签管理功能，比如冻结功能，做成多个项目隔离开，
1. 安卓本机连接考虑支持shizuku/root, 但这样功能的实现可能比较割裂，
1. 想办法支持打开多个设备并在各页面切换，

### adb

参考adb_kit，  
https://github.com/nightmare-space/adb_kit  
使用adb可执行文件， 远程连接安卓设备，执行命令  
对于安卓设备本身还支持连接本机，  

### web端
考虑直接tcp连接adb server，  
似乎没有dart上的实现，参考java的，  
https://github.com/vidstige/jadb  
好像太复杂了些，  
不知道有没有web专用的js实现的库能集成进来，或者直接web端绕过adb server连接手机的实现  
https://github.com/yume-chan/ya-webadb  
https://app.webadb.com/tcpip  


