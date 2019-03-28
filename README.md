第一步

将 xcodebuild.sh 拷贝到带有项目文件的目录下面

第二步

打开 xcodebuild.sh 将其中的 电脑用户名 、电脑密码、项目名称 填写在文件中，然后保存

第三步

打开终端，执行 ：  chmod +x "xcodebuild.sh文件路径"    给脚本文件增加执行权限


第四步,执行脚本


1.发布版本（AppStore 或者 企业版本）打包

需要：发布配置文件、发布证书

./xcodebuild.sh "带有文件名称的ipa生成路径" "app安装显示名称" "版本号" "Build版本号" "包名" Release "p12证书存储路径" "p12证书密码" "配置文件路径"


2.ad-hoc 打包

需要：adhoc配置文件、发布证书

./xcodebuild.sh "带有文件名称的ipa生成路径" "app安装显示名称" "版本号" "Build版本号" "包名" Release "p12证书存储路径" "p12证书密码" "配置文件路径"


3.开发版本打包

需要：开发配置文件、开发证书

./xcodebuild.sh "带有文件名称的ipa生成路径" "app安装显示名称" "版本号" "Build版本号" "包名" Debug "p12证书存储路径" "p12证书密码" "配置文件路径"



