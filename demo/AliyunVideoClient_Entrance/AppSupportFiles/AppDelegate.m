//
//  AppDelegate.m
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/3/22.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "AppDelegate.h"
#import "AlivcHomeViewController.h"
#import "AlivcBaseNavigationController.h"
#import "UIImage+AlivcHelper.h"
//versionCheck
#import "AlivcDefine.h"
//UMeng
#import <UMCommon/UMCommon.h>
#import <UMAnalytics/MobClick.h>
#import <artpSource/ArtpFactory.h>
#import <AliyunPlayer/AliyunPlayer.h>
#import "RCCRLiveHttpManager.h"
#import "RCCRRongCloudIMManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //crash init
    [self UMengInit];
    
    [self initAliyunPlayerComponent];
    
    // 初始化根视图控制器
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
 
    AlivcHomeViewController *vc_root = [[AlivcHomeViewController alloc]init];
 
    AlivcBaseNavigationController *nav_root = [[AlivcBaseNavigationController alloc]initWithRootViewController:vc_root];
   
    
 
    //导航栏设置
    [self setBaseNavigationBar:nav_root];
    self.window.rootViewController = nav_root;
    [self.window makeKeyAndVisible];
    
    // 语言 设置
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleLanguages"];
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *language = [languages objectAtIndex:0];
    
    if ([language hasPrefix:@"zh"]) {//检测开头匹配，是否为中文
        
        NSArray *lans = @[@"zh-Hans-CN"];
        [[NSUserDefaults standardUserDefaults] setObject:lans forKey:@"AppleLanguages"];//App语言设置为中文
        
    }else{//其他语言
        NSArray *lans = @[@"en-CN"];
        [[NSUserDefaults standardUserDefaults] setObject:lans forKey:@"AppleLanguages"];//App语言设置为英文
        
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self checkVersion];
    });
    [[RCCRRongCloudIMManager sharedRCCRRongCloudIMManager] initRongCloud:RCIMAPPKey];
    return YES;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    
    UINavigationController *navigationController = (id)self.window.rootViewController;
    if ([navigationController isKindOfClass:[UINavigationController class]]) {
        return [navigationController.visibleViewController supportedInterfaceOrientations];
    }
    return navigationController.supportedInterfaceOrientations;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"\n ===> 程序暂停 !");
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"\n ===> 进入后台 ！");
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - Public Method
- (void)UMengInit{
    NSString *appkey;
    if(kAlivcProductType == AlivcOutputProductTypeSmartVideo) {
        appkey = @"5c6d176eb465f5fccb000468";
    }else{
        appkey = @"5c6e4e0fb465f58fea00006a";
    }
    NSString *channel = @"Aliyun"; //渠道标记
    [UMConfigure setLogEnabled:YES];//此处在初始化函数前面是为了打印初始化的日志
    [MobClick setCrashReportEnabled:YES];
    [UMConfigure initWithAppkey:appkey channel:channel];
}

- (void)initAliyunPlayerComponent {
    [AliPlayer initPlayerComponent:[NSString stringWithUTF8String:ARTP_COMPONENT_NAME] function:getArtpFactory];
}

/**
 导航栏设置，全局有效
 */
- (void)setBaseNavigationBar:(UINavigationController *)nav{
    //
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [nav.navigationBar setBackgroundImage:[UIImage avc_imageWithColor:[AlivcUIConfig shared].kAVCBackgroundColor] forBarMetrics:UIBarMetricsDefault];
    [nav.navigationBar setShadowImage:[UIImage new]];
    nav.navigationBar.tintColor = [UIColor whiteColor];
    [nav.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}


#pragma mark - 版本更新

- (void)checkVersion{
    //确定对外输出的产品类型
    AlivcOutputProductType productType = kAlivcProductType;
    
    NSString *plistString = nil;
    switch (productType) {
        case AlivcOutputProductTypeSmartVideo:
            plistString = @"https://vod-download.cn-shanghai.aliyuncs.com/apsaravideo-upgrade/ios/littleVideo.plist";
            break;
        case AlivcOutputProductTypeAll:
            plistString = @"https://vod-download.cn-shanghai.aliyuncs.com/apsaravideo-upgrade/ios/ApsaraVideo.plist";
            
        default:
            break;
    }
    if (plistString) {
        NSString *releaseNoteString = [self releaseNoteStringWithString:plistString];
        if (releaseNoteString) {
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"检测到新版本，是否更新？" , nil) message:releaseNoteString preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:[@"确定" localString] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (@available(iOS 10.0, *)) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@",plistString]] options:@{} completionHandler:nil];
                } else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@",plistString]]];
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    exit(0);
                });
            }];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[@"取消" localString] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
               
            }];
            
            
            [alertC addAction:confirmAction];
            [alertC addAction:cancelAction];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.window.rootViewController presentViewController:alertC animated:YES completion:nil];
            });
        }
    }
    
}

/**
 检查本地版本号与服务器版本号，看下有无更新
 
 @param plistString 服务器版本号所在的url字符串
 @return nil - 无更新， 有值 - 有更新并且返回更新内容
 */
- (NSString *)releaseNoteStringWithString:(NSString *)plistString{
    
    
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:plistString]];
    NSString *releaseNote = dic[@"items"][0][@"metadata"][@"releaseNote"];
    NSString *onLineVersion = dic[@"items"][0][@"metadata"][@"bundle-version"];
    
    
    
    NSString *localVerson = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    if([localVerson compare:onLineVersion options:NSNumericSearch] == NSOrderedAscending){
        return releaseNote;
    }
    return nil;
}

@end
