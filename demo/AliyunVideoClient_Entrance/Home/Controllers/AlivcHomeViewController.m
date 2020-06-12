//
//  AVC_ET_HomeViewController.m
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/3/22.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "AlivcHomeViewController.h"
#import <AVFoundation/AVFoundation.h>
#include <sys/param.h>
#include <sys/mount.h>

#import "AVC_ET_ModuleItemCCell.h"
#import "AVC_ET_ModuleDefine.h"
#import "ELCVFlowLayout.h"
#import "AlivcLiveEnvManager.h"
#import "SDKVersionManager.h"
#import "AlivcDefine.h"
#import "AlivcQuUserManager.h"
//#import <AliyunVideoSDKPro/AliyunVideoSDKInfo.h>
#import "AlivcDefine.h"
#import "AlivcQuUserManager.h"
#import "AlivcAppInfoViewController.h"


//helper
#import "UIImage+AlivcHelper.h"
#import "MBProgressHUD+AlivcHelper.h"
#import "NSData+AlivcHelper.h"

#import "UIApplication+AlivcHelper.h"

//user
#import "AliVideoClientUser.h"

#if __has_include(<AliyunVideoSDKPro/AliyunVideoSDKInfo.h>)
#import <AliyunVideoSDKPro/AliyunVideoSDKInfo.h>
#endif 

NS_ASSUME_NONNULL_BEGIN

static CGFloat deviceInCollectionView = 12; //两个item之间的距离
static CGFloat besise = 16; //collectionView的边距
static CGFloat lableDevideToTop = 44; //阿里云视频label距离顶部的距离


@interface AlivcHomeViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UIScrollViewDelegate>


/**
 模块描述字符串集合
 */
@property (strong, nonatomic) NSArray <AVC_ET_ModuleDefine *>*dataArray;


/**
 阿里云视频的label
 */
@property (strong, nonatomic) UILabel *aliLabel;

/**
 欢迎label
 */
@property (strong, nonatomic) UILabel *welcomeLabel;

/**
 用户设置按钮
 */
@property (strong, nonatomic) UIButton *appInfoButton;

/**
 展示列表
 */
@property (strong, nonatomic) UICollectionView *collectionView;

/**
 列表的页数
 */
@property (strong, nonatomic, nullable) UIPageControl *pageController;

@property (assign, nonatomic) BOOL isClipConfig;

@property (strong, nonatomic) UIImageView *bg;
/**
 环境
 */
@property (strong, nonatomic) UIButton *envButton;
@property (nonatomic, assign) int envMode;
/**
 环境
 */
@property (nonatomic, assign) BOOL isChangedRow;


/**
 简单路由
 */
//@property (nonatomic, strong) AlivcShortVideoRoute *alivcRoute;

@property (nonatomic,copy)NSString *plistString;
@end

@implementation AlivcHomeViewController


#pragma mark - System & Init

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    [self redirectNSlogToDocumentFolder];
    
    self.isChangedRow = NO;
    
    [self configBaseData];
    [self configBaseUI];
    [self setDefaultEnv];
//    [self settingQuietModePlaying];//设置静音模式的播放方式
    [self checkFreeDiskSpaceInBytes];
    
    // 开启短视频log
#if __has_include(<AliyunVideoSDKPro/AliyunVideoSDKInfo.h>)
    [AliyunVideoSDKInfo setLogLevel:kAlivcLogLevel];
#endif
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //导航栏设置
    self.navigationController.navigationBar.hidden = true;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
//    self.navigationController.navigationBar.hidden = false;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - 旋转
- (BOOL)shouldAutorotate{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Lazy init
- (UILabel *)aliLabel{
    if (!_aliLabel) {
        _aliLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
        _aliLabel.font = [UIFont systemFontOfSize:26];
        _aliLabel.textColor = [UIColor whiteColor];
        _aliLabel.text = [@"alivc_yun_video" localString];
        [_aliLabel sizeToFit];
        CGFloat heightAliLabel = CGRectGetHeight(_aliLabel.frame);
        CGFloat widthAlilabel = CGRectGetWidth(_aliLabel.frame);
        _aliLabel.center = CGPointMake(besise + widthAlilabel / 2,lableDevideToTop + heightAliLabel / 2);
        _aliLabel.userInteractionEnabled =YES;
    }
    return _aliLabel;
}
- (UILabel *)welcomeLabel{
    if (!_welcomeLabel) {
        _welcomeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
        _welcomeLabel.font = [UIFont systemFontOfSize:14];
        _welcomeLabel.textColor = [UIColor whiteColor];
        _welcomeLabel.text = [@"WELCOME TO START THE VIDEO JOURNEY" localString];
        [_welcomeLabel sizeToFit];
        CGFloat heightWLabel = CGRectGetHeight(_welcomeLabel.frame);
        CGFloat widthWLabel = CGRectGetWidth(_welcomeLabel.frame);
        _welcomeLabel.center = CGPointMake(besise + widthWLabel / 2, lableDevideToTop + self.aliLabel.frame.size.height + 16 + heightWLabel / 2);
    }
    return _welcomeLabel;
}

- (UIButton *)appInfoButton{
    if (!_appInfoButton) {
        _appInfoButton = [[UIButton alloc]initWithFrame:CGRectMake(PortraitScreenWidth - 66, lableDevideToTop, 26, 26)];
        [_appInfoButton setBackgroundImage:[UIImage imageNamed:@"appInfo"] forState:UIControlStateNormal];
        [_appInfoButton setBackgroundImage:[UIImage imageNamed:@"appInfo"] forState:UIControlStateSelected];
        _appInfoButton.center = CGPointMake(PortraitScreenWidth - besise - _appInfoButton.frame.size.width / 2, lableDevideToTop + _appInfoButton.frame.size.height / 2);
        [_appInfoButton addTarget:self action:@selector(showSdkInfo) forControlEvents:UIControlEventTouchUpInside];
    }
    return _appInfoButton;
}

- (UICollectionView *)collectionView{
    if (!_collectionView) {
        
        CGFloat cWidth = PortraitScreenWidth - 2 * besise;
        CGFloat cItemWidth = (cWidth - deviceInCollectionView) / 2;
        CGFloat cItemHeight = 120;
        CGFloat cHeight = cItemHeight * 3 + deviceInCollectionView * 2;
        CGFloat cDevideToTop = ((ScreenHeight-CGRectGetMaxY(_welcomeLabel.frame)-30)-cHeight)/2.0+CGRectGetMaxY(_welcomeLabel.frame);
        CGRect cFrame = CGRectMake(besise, cDevideToTop, cWidth, cHeight);
        ELCVFlowLayout *layout = [[ELCVFlowLayout alloc]init];
        layout.itemSize = CGSizeMake(cItemWidth, cItemHeight);
        [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        UICollectionView *cView = [[UICollectionView alloc]initWithFrame:cFrame collectionViewLayout:layout];
        [cView registerNib:[UINib nibWithNibName:@"AVC_ET_ModuleItemCCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"AVC_ET_ModuleItemCCell"];
        cView.dataSource = self;
        cView.delegate = self;
        cView.pagingEnabled = true;
        cView.scrollEnabled = YES;
        cView.backgroundColor = [UIColor clearColor];
        cView.showsVerticalScrollIndicator = false;
        cView.showsHorizontalScrollIndicator = false;
        _collectionView = cView;
    }
    return _collectionView;
}

- (UIPageControl *__nullable)pageController{
    if (!_pageController && self.dataArray.count > 6) {
        _pageController = [[UIPageControl alloc]init];
        NSInteger shang = self.dataArray.count / 6;
        NSInteger yushu = self.dataArray.count % 6;
        if (yushu) {
            shang += 1;
        }
        _pageController.numberOfPages = shang;
        CGFloat cx = PortraitScreenWidth / 2;
        CGFloat cy = PortraitScreenHeight - 20;
        _pageController.center = CGPointMake(cx, cy);
    }
    return _pageController;
}

- (UIButton *)envButton{
    if (!_envButton) {
        UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(ScreenWidth - 50, lableDevideToTop+50, 60, 46)];
        button.titleLabel.font = [UIFont systemFontOfSize:10];
        [button setTitle:[@"note_city_PreRelease" localString] forState:UIControlStateNormal];
        [button sizeToFit];
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        CGRect rect = button.frame;
        rect.size.width += 10;
        button.frame = rect;
        [button addTarget:self action:@selector(envButtonTouched) forControlEvents:UIControlEventTouchUpInside];
        
        if (self.pageController.center.y > 0) {
            button.center = CGPointMake(ScreenWidth - besise - button.frame.size.width / 2,
                                        self.pageController.center.y);
        }else{
            button.center = CGPointMake(ScreenWidth - besise - button.frame.size.width / 2,
                                        ScreenHeight - button.bounds.size.height - 20);
        }
        _envButton = button;
    }
    _envButton.hidden = YES;
    return _envButton;
}

#pragma mark - EnvManager
- (void)envButtonTouched{
#ifdef DEBUG
    [self debugEnvChanged];
#else
    [self releaseEnvChanged];
#endif
}

- (void)debugEnvChanged{
    _envMode = _envMode+1;
    if (_envMode == 4) {
        _envMode = 0;
    }
    switch (_envMode) {
        case 0:
            [_envButton setTitle:[@"note_city_Shanghai" localString] forState:UIControlStateNormal];
            break;
        case 1:
             [_envButton setTitle:[@"note_city_Singapore" localString] forState:UIControlStateNormal];
            break;
        case 2:
            [_envButton setTitle:[@"note_city_PreRelease" localString] forState:UIControlStateNormal];
            break;
        case 3:
           [_envButton setTitle:[@"note_city_Daily" localString] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    [AlivcLiveEnvManager AlivcAppServerSetTestEnvMode:_envMode];
}

- (void)releaseEnvChanged{
    _envMode = _envMode+1;
    if (_envMode == 2) {
        _envMode = 0;
    }
    if (_envMode == 0) {
        [_envButton setTitle:[@"note_city_Shanghai" localString] forState:UIControlStateNormal];
        [AlivcLiveEnvManager AlivcAppServerSetTestEnvMode:0];
        
    }else{
        [_envButton setTitle:[@"note_city_Singapore" localString] forState:UIControlStateNormal];
        [AlivcLiveEnvManager AlivcAppServerSetTestEnvMode:1];
    }
}

- (void)setDefaultEnv{
    [_envButton setTitle:[@"note_city_Shanghai" localString] forState:UIControlStateNormal];
    [AlivcLiveEnvManager AlivcAppServerSetTestEnvMode:0];
}



#pragma mark - BaseSet
/**
 适配基本的数据
 */
- (void)configBaseData{
    
    NSMutableArray *mArray = [[NSMutableArray alloc]init];
    
    //功能配置
    
    NSInteger shouldAddValue = 0b10000000;    
    for (int i = 0; i < 16; i ++) {
        NSInteger typeValue = 1 << i;
        BOOL shouldAdd = shouldAddValue & typeValue;
        if (shouldAdd) {
            AVC_ET_ModuleType type = (AVC_ET_ModuleType)typeValue;
            AVC_ET_ModuleDefine *module = [[AVC_ET_ModuleDefine alloc]initWithModuleType:type];
            [mArray addObject:module];
        }
    }
    self.dataArray = (NSArray *)mArray;
}

/**
 适配基本的UI
 */
- (void)configBaseUI{
    
    // 背景图
    _bg = [[UIImageView alloc] initWithFrame:CGRectMake(60, 0, ScreenWidth-60, (ScreenWidth-60)*378/644.0)];
    _bg.image = [UIImage imageNamed:@"bg_home"];
    _bg.userInteractionEnabled =YES;
    [self.view addSubview:_bg];
    
    //ali label
    [self.view addSubview:self.aliLabel];
    
    //welcome label
    [self.view addSubview:self.welcomeLabel];
    
    //user setting
    [self.view addSubview:self.appInfoButton];
    
    //env
    [self.view addSubview:self.envButton];
    
    //CollectionView
    [self.view addSubview:self.collectionView];
    
    //pageController
    if (self.pageController) {
        [self.view addSubview:self.pageController];
    }
}



#pragma mark - Custom Method
- (void)pushTargetVCWithClassString:(NSString *)classString{
    Class viewControllerClass = NSClassFromString(classString);
    if (viewControllerClass) {
        UIViewController *targetVC = [[viewControllerClass alloc]init];
        
        if (targetVC) {
            [self.navigationController pushViewController:targetVC animated:true];
        }
    }
}

- (void)pushTargetVCWithClassString:(NSString *)classString value:(id)value valueString:(NSString *)valueString{
    Class viewControllerClass = NSClassFromString(classString);
    if (viewControllerClass) {
        UIViewController *targetVC = [[viewControllerClass alloc]init];
        if (targetVC) {
            if (value && valueString) {
                [targetVC setValue:value forKey:valueString];
            }
            [self.navigationController pushViewController:targetVC animated:true];
        }
    }
}

-(void)showSdkInfo{
    AlivcAppInfoViewController *appInfoVC =[[AlivcAppInfoViewController alloc]init];
    self.navigationController.navigationBar.hidden = NO;
    [self.navigationController pushViewController:appInfoVC animated:YES];
}
- (void)redirectNSlogToDocumentFolder
{
#if __has_include(<AliyunVideoSDKPro/AliyunVideoSDKInfo.h>)
    [AliyunVideoSDKInfo setLogLevel:kAlivcLogLevel];
#endif
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"app.log"];
    NSString *logFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    //先删除已经存在的文件
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    [defaultManager removeItemAtPath:logFilePath error:nil];
    // 将log输入到文件
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stderr);
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return deviceInCollectionView;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return deviceInCollectionView;
}



#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.dataArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    AVC_ET_ModuleItemCCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AVC_ET_ModuleItemCCell" forIndexPath:indexPath];
    if (self.dataArray.count > indexPath.row) {
        AVC_ET_ModuleDefine *define = self.dataArray[indexPath.row];
        [cell configWithModule:define];
    }
    return cell;
}



#pragma mark - UICollectionViewDelegate

- (void)repeatDelay{
    self.isChangedRow = false;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.isChangedRow == NO) {
        self.isChangedRow = YES;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(repeatDelay) object:nil];
        [self performSelector:@selector(repeatDelay) withObject:nil afterDelay:0.5];
        
        if (indexPath.row < self.dataArray.count) {
            AVC_ET_ModuleDefine *module = self.dataArray[indexPath.row];
            [self configImageBundleWithType:module.type];
            switch (module.type) {
                case AVC_ET_ModuleType_VideoShooting:
                    [self pushTargetVCWithClassString:@"AliyunRecordParamViewController"];break;
                    
                case AVC_ET_ModuleType_VideoEdit:
                     [self pushTargetVCWithClassString:@"AliyunConfigureViewController" value:@"NO" valueString:@"isClipConfig"];break;
                    
                case AVC_ET_ModuleType_VideoClip:
                    [self pushTargetVCWithClassString:@"AliyunConfigureViewController" value:@"YES" valueString:@"isClipConfig"];break;
                    
                case AVC_ET_ModuleType_ShortVideo:
                    [self pushTargetVCWithClassString:@"AlivcShortVideoQuHomeTabBarController"];break;
                    
                case AVC_ET_ModuleType_VideoShooting_Basic:
                    [self pushTargetVCWithClassString:@"AlivcBase_RecordParamViewController"];break;
                    
                    
                    // 互动直播
                case AVC_ET_ModuleType_VideoLive:[self pushTargetVCWithClassString:@"AlivcCombinationListViewController"];break;
                    
                    // 直播推流
                case AVC_ET_ModuleType_PushFlow:[self pushTargetVCWithClassString:@"AlivcLivePushRootViewController"];break;
                    
                    
                    // 视频播放
                case AVC_ET_ModuleType_VideoPaly:[self pushTargetVCWithClassString:@"AVC_VP_VideoPlayViewController"];break;
                    
                    // RTC
                case AVC_ET_ModuleType_RTC:[self pushTargetVCWithClassString:@"AlivcRTCHomeViewController"];break;
                    // RTC audio
                case AVC_ET_ModuleType_RTC_Audio:[self pushTargetVCWithClassString:@"AlivcRTCAudioHomeViewController"];break;
                    //互动白板
                case AVC_ET_ModuleType_Smartboard:[self pushTargetVCWithClassString:@"AlivcSmartboardLoginViewController"];break;
                    
                default:
                    break;
            }
        }else{
            NSAssert(false, @"数组越界test");
        }
    }else{
        return;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    CGPoint offset = scrollView.contentOffset;
    NSInteger currentPage = offset.x / scrollView.frame.size.width;
    if (currentPage < self.pageController.numberOfPages) {
        self.pageController.currentPage = currentPage;
    }
}


- (void)dealloc{
    if ([self respondsToSelector:@selector(repeatDelay)]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(repeatDelay) object:nil];
    }
}

#pragma mark - ImageBundleConfig

- (void)configImageBundleWithType:(AVC_ET_ModuleType)type{
    switch (type) {
        case AVC_ET_ModuleType_VideoShooting:
            [AlivcImage setImageBundleName:@"AlivcShortVideoImage"];
            break;
        case AVC_ET_ModuleType_VideoEdit:
            [AlivcImage setImageBundleName:@"AlivcShortVideoImage"];
            break;
        case AVC_ET_ModuleType_VideoClip:
            [AlivcImage setImageBundleName:@"AlivcShortVideoImage"];
            break;
        case AVC_ET_ModuleType_ShortVideo:
            [AlivcImage setImageBundleName:@"AlivcShortVideoImage"];
            break;
        case AVC_ET_ModuleType_VideoPaly:
            [AlivcImage setImageBundleName:@"AliyunImageSource"];
            
        default:
            break;
    }
}

-(void)settingQuietModePlaying{
    //手机静音，播放有声音
    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    [avSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [avSession setActive:YES error:nil];
}


- (void)checkFreeDiskSpaceInBytes{
    CGFloat freeSpace =[self freeDiskSpaceInBytes]-160;
    if (freeSpace<100 && freeSpace>0.1) {
        UIAlertController *alert =[UIAlertController alertControllerWithTitle:NSLocalizedString(@"提示", nil) message:NSLocalizedString(@"设备内存不足，请及时清理" , nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action =[UIAlertAction actionWithTitle:NSLocalizedString(@"知道了", nil) style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:NO completion:nil];
    }
    NSLog(@"设备剩余内存%f",freeSpace);
}


// 空余硬盘大小
- (CGFloat)freeDiskSpaceInBytes{
    
    CGFloat totalFreeSpace = 0.0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = (([freeFileSystemSizeInBytes floatValue]/1024.f)/1024.f);
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    
//    if (@available(iOS 11.0, *)) {
//        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:NSTemporaryDirectory()];
//        NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&error];
//        if (!results) {
//            NSLog(@"Error retrieving resource keys: %@%@",[error localizedDescription], [error userInfo]);
//            abort();
//
//        }
//        NSLog(@"Available capacity for important usage: %lf",[[results objectForKey:NSURLVolumeAvailableCapacityForImportantUsageKey] floatValue]);
//        totalFreeSpace = [[results objectForKey:NSURLVolumeAvailableCapacityForImportantUsageKey] floatValue]/1000.f/1000.f;
//    } else {
//
//    }
    return totalFreeSpace;
    
}



@end

NS_ASSUME_NONNULL_END