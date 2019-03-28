#配置参数

#需要传入的信息

path=`dirname $0`
cd $path

#配置打包结果输出的路径
outFilePath=$1
#应用名称
appName=$2
#发布版本号
version=$3
#编译版本号
buildversion=$4
#bundleid
bundleId=$5
#配置打包方式Release或者Debug
Configuration=$6
#p12路径
p12path=$7
#p12证书密码
p12password=$8
#配置文件地址
mobileprovisionfilepath=${9}


#目前暂时固定的信息
#电脑密码
macuser="电脑用户名"
macpassword="电脑密码"
#工程名字
Project_Name="工程名称"


#获取文件名称
fileName=${outFilePath##*/}
#获取文件路径
EnterprisePrijectOutPath=$(dirname ${outFilePath})


#workspace的名字，如果没有则不需要
Workspace_Name=""
#基础主路径
BUILD_PATH=./build
#工程地址
project_path='.'
#基础子路径
#enterprise
ENTERPRISE_PATH=${BUILD_PATH}/${Project_Name}/enterprise
#正式使用资源路径，图标和闪图的上级目录
resource_path=./images
#配置编译文件的存放地址
#企业
CONFIGURATION_BUILD_PATH_ENTERPRISE=${ENTERPRISE_PATH}/${Configuration}-iphoneos

#加载的plist文件
EnterpriseExportOptionsPlist="./ExportOptions.plist"

#首先清除原来的文件夹
rm -rf ${BUILD_PATH}
#创建文件夹，路径需要一层一层创建，不然会创建失败
mkdir ${BUILD_PATH}
mkdir ${ENTERPRISE_PATH}
#编译文件
mkdir ${CONFIGURATION_BUILD_PATH_ENTERPRISE}
#打包输出的文件
mkdir ${EnterprisePrijectOutPath}
#copy
mkdir ${DSYM_COPY_PATH_ENTERPRISE}

#---------------------------------------------------------------------------------------------------------------------------------
prepare(){
    #如果工程中配置了Automatically manage signing，那么就不需要证书名和描述文件名，请确保工程中配置的证书名和描述文件是你打包想要用的
    #企业(enterprise)证书名#描述文件
    mobileprovision_teamname=`/usr/libexec/PlistBuddy -c "Print TeamName" /dev/stdin <<< $(security cms -D -i $mobileprovisionfilepath)`
    mobileprovision_name=`/usr/libexec/PlistBuddy -c "Print Name" /dev/stdin <<< $(security cms -D -i $mobileprovisionfilepath)`
    teamIdentifier=`/usr/libexec/PlistBuddy -c "Print TeamIdentifier:0" /dev/stdin <<< $(security cms -D -i $mobileprovisionfilepath)`

    prefix="iPhone Distribution"
    if [[ $Configuration == "Debug" ]]
    then
       prefix="iPhone Developer"
    fi

    ENTERPRISECODE_SIGN_IDENTITY="$prefix: $mobileprovision_teamname"
    ENTERPRISEROVISIONING_PROFILE_NAME="$mobileprovision_name"uuid


    #修改xcode project中相关配置信息
    pbxproj_path="$path/ZiRu_OP.xcodeproj/project.pbxproj"
    pbxproj_path2="$path/project.pbxproj"
    cp $pbxproj_path $pbxproj_path2
    sed -i -e "s/PROVISIONING_PROFILE_SPECIFIER = .*;/PROVISIONING_PROFILE_SPECIFIER = \"$mobileprovision_name\";/" $pbxproj_path2
    sed -i -e "s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = \"$bundleId\";/" $pbxproj_path2
    sed -i -e "s/DEVELOPMENT_TEAM = .*;/DEVELOPMENT_TEAM = $teamIdentifier;/" $pbxproj_path2
    sed -i -e "s/CODE_SIGN_IDENTITY = .*;/CODE_SIGN_IDENTITY = \"$prefix\";/" $pbxproj_path2
    cp $pbxproj_path2 $pbxproj_path
    rm $pbxproj_path2


    #修改ExportOptions.plist中相关配置信息
    ExportOptionsplist_path="$path/ExportOptions.plist"
    #如果设备列表大于0 那么需要是ad-hoc的设置，如果ProvisionsAllDevices返回
    method=""
    signingCertificate="iPhone Distribution"
    #获取设备列表
    ProvisionedDevices=`/usr/libexec/PlistBuddy -c "Print ProvisionedDevices" /dev/stdin <<< $(security cms -D -i $mobileprovisionfilepath)`
    if [[ ${#ProvisionedDevices} != 0 ]]
    then
      gettaskallow=`/usr/libexec/PlistBuddy -c "Print Entitlements:get-task-allow" /dev/stdin <<< $(security cms -D -i $mobileprovisionfilepath)`
      if [[ $gettaskallow == "true" ]]
      then
         signingCertificate="iPhone Developer"
         method="development"
      else
         method="ad-hoc"
      fi
    else
        ProvisionsAllDevices=`/usr/libexec/PlistBuddy -c "Print ProvisionsAllDevices" /dev/stdin <<< $(security cms -D -i $mobileprovisionfilepath)`
        echo $ProvisionsAllDevices
        if [[ $ProvisionsAllDevices == "true" ]]
        then
           method="enterprise"
        else
           method="app-store"
        fi
    fi
    /usr/libexec/PlistBuddy -c "Set method $method" $ExportOptionsplist_path
    /usr/libexec/PlistBuddy -c "Set signingCertificate $signingCertificate" $ExportOptionsplist_path
    /usr/libexec/PlistBuddy -c 'Delete :provisioningProfiles' $ExportOptionsplist_path
    /usr/libexec/PlistBuddy -c 'Add :provisioningProfiles dict' $ExportOptionsplist_path
    /usr/libexec/PlistBuddy -c "Add :provisioningProfiles:$bundleId string $mobileprovision_name" $ExportOptionsplist_path
    /usr/libexec/PlistBuddy -c "Set teamID $teamIdentifier" $ExportOptionsplist_path


    #导入配置文件
    mobileprovisionudid=`grep UUID -A1 -a $mobileprovisionfilepath| grep -io '[-A-F0-9]\{36\}'`
    mobileprovisionhomepath=`echo ~`
    cp $mobileprovisionfilepath "$mobileprovisionhomepath/Library/MobileDevice/Provisioning Profiles/$mobileprovisionudid.mobileprovision"


    #导入p12证书
    security unlock-keychain -p $macpassword "/Users/$macuser/Library/Keychains/login.keychain"
    security list-keychains -s "/Users/$macuser/Library/Keychains/login.keychain"
    security import $p12path -k "/Users/$macuser/Library/Keychains/login.keychain" -P $p12password -T /usr/bin/codesign

    #替换displayName以及bundleId
    sed -i '' "/CFBundleDisplayName/{n;s/<string>.*<\/string>/<string>${appName}<\/string>/;}" $plist_path
    sed -i '' "/CFBundleName/{n;s/<string>.*<\/string>/<string>${appName}<\/string>/;}" $plist_path
    sed -i '' "/CFBundleIdentifier/{n;s/<string>.*<\/string>/<string>${bundleId}<\/string>/;}" $plist_path
    sed -i '' "/CFBundleShortVersionString/{n;s/<string>.*<\/string>/<string>${version}<\/string>/;}" $plist_path
    sed -i '' "/CFBundleVersion/{n;s/<string>.*<\/string>/<string>${buildversion}<\/string>/;}" $plist_path

}

prepare

#解锁证书
security unlock-keychain  -p $macpassword ~/Library/Keychains/login.keychain

xcodebuild archive -scheme $Project_Name -configuration $Configuration -archivePath ${ENTERPRISE_PATH}/$Project_Name-enterprise.xcarchive
CODE_SIGN_IDENTITY="${ENTERPRISECODE_SIGN_IDENTITY}" PROVISIONING_PROFILE="${ENTERPRISEROVISIONING_PROFILE_NAME}" PRODUCT_BUNDLE_IDENTIFIER=${bundleId}

xcodebuild -exportArchive -archivePath ${ENTERPRISE_PATH}/$Project_Name-enterprise.xcarchive -exportOptionsPlist $EnterpriseExportOptionsPlist -exportPath ${EnterprisePrijectOutPath}

cd $EnterprisePrijectOutPath

#重命名为指定文件名称
mv "$Project_Name.ipa" $fileName
