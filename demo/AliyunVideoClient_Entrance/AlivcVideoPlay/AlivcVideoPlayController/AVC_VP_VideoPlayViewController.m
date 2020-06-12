//
//  AVC_VP_VideoPlayViewController.m
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/4/11.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "AVC_VP_VideoPlayViewController.h"
#import "AliyunVodPlayerView.h"
#import "AVCVideoConfig.h"
#import <sys/utsname.h>
#import "AVCLogView.h"
#import "MBProgressHUD+AlivcHelper.h"
#import "AVCVideoDownloadTCell.h"
#import "AlivcAppServer.h"
#import "AVCSelectSharpnessView.h"
#import "AlivcVideoPlayManager.h"
#import "AlivcVideoPlayListModel.h"
#import "AlivcPlayListsView.h"
#import "AlivcVideoDataBase.h"
#import "AliyunReachability.h"
#import "AVC_VP_PlaySettingVC.h"
#import "UIImage+AlivcHelper.h"
#import "DownloadManager.h"
#import "AlivcAlertView.h"
#import "MBProgressHUD+AlivcHelper.h"


NS_ASSUME_NONNULL_BEGIN

#define VIEWSAFEAREAINSETS(view) ({UIEdgeInsets i; if(@available(iOS 11.0, *)) {i = view.safeAreaInsets;} else {i = UIEdgeInsetsZero;} i;})

static CGFloat kExchangeHeight = 50; //日志离线视频行的高度
static NSString *kSaveVideoFileName = @"AVCLocalVideo";
static NSInteger alertViewTag_downLoad_continue = 1002; //wifi为4g时下载是否继续的tag
static NSInteger alertViewTag_exit_continue = 1003; //是否继续退出
static NSInteger alertViewTag_delete_video = 1004; //删除本地视频

@interface AVC_VP_VideoPlayViewController ()<AliyunVodPlayerViewDelegate,UITableViewDataSource,UITableViewDelegate,DownloadManagerDelegate,AVCSelectSharpnessViewDelegate,AlivcPlayListsViewDelegate,UIAlertViewDelegate,AVCVideoDownloadTCellDelegate>

//播放器
@property (nonatomic,strong, nullable)AliyunVodPlayerView *playerView;

//控制锁屏
@property (nonatomic, assign)BOOL isLock;

//是否隐藏navigationbar
@property (nonatomic,assign)BOOL isStatusHidden;

//进入前后台时，对界面旋转控制 ？？？？？？ 这个是干什么用的
@property (nonatomic, assign)BOOL isBecome;

//网络监听
@property (nonatomic, strong) AliyunReachability *reachability;

/**
 切换的容器视图
 */
@property (nonatomic, strong) UIView *exchangeContainView;

/**
 蓝色切换条
 */
@property (nonatomic, strong) UIView *exchangeLineView;

/**
 播放列表
 */
@property (nonatomic, strong) AlivcPlayListsView *listView;

/**
 播放列表按钮
 */
@property (nonatomic, strong) UIButton *listButton;

/**
 日志视图
 */
@property (nonatomic, strong) AVCLogView *logView;

/**
 日志按钮
 */
@property (nonatomic, strong) UIButton *logButton;

/**
 离线视频
 */
@property (nonatomic, strong) UIButton *offLineVideoButton;

/**
 离线视频上的小红点
 */
@property (nonatomic, strong) UIView *redView;

/**
 下载容器视图
 */
@property (nonatomic, strong) UIView *downloadContainView;

/**
 下载容器视图横屏的时候 左边的手势识别视图
 */
@property (nonatomic, strong) UIView *downloadGestureView;

/**
 离线视频下载tableView
 */
@property (nonatomic, strong) UITableView *downloadTableView;

/**
 下载编辑视频的容器视图
 */
@property (nonatomic, strong) UIView *downloadEditContainView;

/**
 是否在编辑下载视频
 */
@property (nonatomic, assign) BOOL isEdit;

/**
 是否全部选中
 */
@property (nonatomic, assign) BOOL isAllSelected;

/**
 是否在展示模态视图
 */
@property (nonatomic, assign) BOOL isPresent;

/**
 选择清晰度
 */
@property (nonatomic, strong) AVCSelectSharpnessView *selectView;

// data define

/**
 正在缓存列表
 */
@property (nonatomic, strong) NSMutableArray <DownloadSource *>*downloadingVideoArray;

/**
 已缓存列表
 */
@property (nonatomic, strong) NSMutableArray <DownloadSource *>*doneVideoArray;

/**
 选中的编辑列表
 */
@property (nonatomic, strong) NSMutableArray <DownloadSource *>*editVideoArray;

/**
 准备下载的视频参数
 */
@property (nonatomic, strong) DownloadSource *readyDataSource;

/**
 记录之前竖屏状态下在哪个界面 0:播放列表 1：日志， 2：离线视频
 */
@property (assign, nonatomic) NSInteger logOrDownload;

/**
 提示框
 */
@property (strong, nonatomic) MBProgressHUD *hud;

/**
 全屏状态下是否点击了查看离线视频
 */
@property (assign, nonatomic) BOOL isLookingVideoWhenFullScreen;

/**
 当前播放的视频的Model
 */
@property (strong, nonatomic) AlivcVideoPlayListModel *currentPlayVideoModel;
/**
点击了下载按钮
 */
@property (assign, nonatomic) BOOL clickDownload;

@end

@implementation AVC_VP_VideoPlayViewController

#pragma mark - Lazy init
- (NSMutableArray <DownloadSource *>*)downloadingVideoArray{
    if (!_downloadingVideoArray) {
        _downloadingVideoArray = [[NSMutableArray alloc]init];
    }
    return _downloadingVideoArray;
}

- (NSMutableArray <DownloadSource *>*)doneVideoArray{
    if (!_doneVideoArray) {
        _doneVideoArray = [[NSMutableArray alloc]init];
    }
    return _doneVideoArray;
}

- (NSMutableArray <DownloadSource *>*)editVideoArray{
    if (!_editVideoArray) {
        _editVideoArray = [[NSMutableArray alloc]init];
    }
    return _editVideoArray;
}

/**
 播放视图
 */
- (AliyunVodPlayerView *__nullable)playerView{
    if (!_playerView) {
        CGFloat width = 0;
        CGFloat height = 0;
        CGFloat topHeight = 0;
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationPortrait ) {
            width = ScreenWidth;
            height = ScreenWidth * 9 / 16.0;
            topHeight = 20;
        }else{
            width = ScreenWidth;
            height = ScreenHeight;
            topHeight = 20;
        }
        /****************UI播放器集成内容**********************/
        _playerView = [[AliyunVodPlayerView alloc] initWithFrame:CGRectMake(0,topHeight, width, height) andSkin:AliyunVodPlayerViewSkinRed];
        _playerView.currentModel = _currentPlayVideoModel;
        [_playerView setDelegate:self];
        [_playerView setPrintLog:YES];
        
        _playerView.isScreenLocked = false;
        _playerView.fixedPortrait = false;
        self.isLock = self.playerView.isScreenLocked||self.playerView.fixedPortrait?YES:NO;
    
    }
    return _playerView;
}

- (UIView *)exchangeContainView{
    if (!_exchangeContainView) {
        CGFloat eHeight = kExchangeHeight;
        _exchangeContainView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, eHeight)];
        CGPoint eCenter = CGPointMake(ScreenWidth / 2, self.playerView.frame.size.height +20+ eHeight / 2);
        
        if(IPHONEX){
            eCenter = CGPointMake(eCenter.x, eCenter.y + 16);
        }

        _exchangeContainView.center = eCenter;
        _exchangeContainView.backgroundColor = [UIColor clearColor];
        UILabel *devideLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, _exchangeContainView.frame.size.height - 1, _exchangeContainView.frame.size.width, 1)];
        devideLabel.backgroundColor = [UIColor colorWithRed:216/255.0 green:216/255.0 blue:216/255.0 alpha:0.5];
        [_exchangeContainView addSubview:devideLabel];
        
        [_exchangeContainView addSubview:self.listButton];
        [_exchangeContainView addSubview:self.logButton];
        [_exchangeContainView addSubview:self.offLineVideoButton];
        [_exchangeContainView addSubview:self.exchangeLineView];
    }
    return _exchangeContainView;
}

- (UIView *)exchangeLineView{
    if (!_exchangeLineView) {
        _exchangeLineView = [[UIView alloc]initWithFrame:CGRectMake(0, self.exchangeContainView.frame.size.height - 2, ScreenWidth / 3, 2)];
        _exchangeLineView.backgroundColor = [UIColor colorWithHexString:@"00c1de"];
    }
    return _exchangeLineView;
}

- (UIButton *)listButton{
    if (!_listButton) {
        _listButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_listButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_listButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [_listButton setFrame:CGRectMake(0, 0, self.exchangeContainView.frame.size.width / 3, self.exchangeContainView.frame.size.height)];
        [_listButton setTitle:[NSLocalizedString(@"视频列表", nil)  localString] forState:UIControlStateNormal];
        [_listButton setTitle:[NSLocalizedString(@"视频列表", nil) localString] forState:UIControlStateSelected];
        [_listButton setTitleEdgeInsets:UIEdgeInsetsMake(10, 0, 0, 0)];
        [_listButton addTarget:self action:@selector(listButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    return _listButton;
}

- (UIButton *)logButton{
    if (!_logButton) {
        _logButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_logButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_logButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [_logButton setFrame:CGRectMake(self.exchangeContainView.frame.size.width / 3, 0, self.exchangeContainView.frame.size.width / 3, self.exchangeContainView.frame.size.height)];
        [_logButton setTitle:[NSLocalizedString(@"日志", nil) localString] forState:UIControlStateNormal];
        [_logButton setTitle:[NSLocalizedString(@"日志", nil) localString] forState:UIControlStateSelected];
        [_logButton setTitleEdgeInsets:UIEdgeInsetsMake(10, 0, 0, 0)];
        [_logButton addTarget:self action:@selector(logButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    return _logButton;
}

- (UIButton *)offLineVideoButton{
    if (!_offLineVideoButton) {
        _offLineVideoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_offLineVideoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_offLineVideoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [_offLineVideoButton setFrame:CGRectMake(self.exchangeContainView.frame.size.width*2 / 3, 0, self.exchangeContainView.frame.size.width / 3, self.exchangeContainView.frame.size.height)];
        [_offLineVideoButton setTitle:[NSLocalizedString(@"离线视频", nil) localString] forState:UIControlStateNormal];
        [_offLineVideoButton setTitle:[NSLocalizedString(@"离线视频", nil)  localString] forState:UIControlStateSelected];
        [_offLineVideoButton setTitleEdgeInsets:UIEdgeInsetsMake(10, 0, 0, 0)];
        [_offLineVideoButton addTarget:self action:@selector(offLineVideoButtonTouched) forControlEvents:UIControlEventTouchUpInside];
        CGFloat width = 8;
        self.redView = [[UIView alloc]initWithFrame:CGRectMake(_offLineVideoButton.frame.size.width - 26, 16, width, width)];
        self.redView.layer.cornerRadius = width / 2;
        self.redView.clipsToBounds = true;
        self.redView.hidden = true;
        self.redView.backgroundColor = [UIColor redColor];
        [_offLineVideoButton addSubview:self.redView];
    }
    return _offLineVideoButton;
}

- (AlivcPlayListsView *)listView{
    if (!_listView) {
        CGFloat increat = 0;
        if(IPHONEX){
            increat = 16;
        }
        CGFloat y = self.playerView.frame.size.height + 20 + self.exchangeContainView.frame.size.height + increat;
        _listView = [[AlivcPlayListsView alloc]initWithFrame:CGRectMake(0, y, ScreenWidth, ScreenHeight - y)];
        _listView.delegate = self;
    }
    return _listView;
}


- (AVCLogView *)logView{
    if (!_logView) {
        CGFloat y = self.playerView.frame.size.height + 20 + self.exchangeContainView.frame.size.height;
        if(IPHONEX){
            y += 16;
        }
        _logView = [[AVCLogView alloc]initWithFrame:CGRectMake(0, y, ScreenWidth, ScreenHeight - y)];
        _logView.hidden = YES;
    }
    return _logView;
}

- (UIView *)downloadContainView{
    if (!_downloadContainView) {
        CGFloat y = self.playerView.frame.size.height + 20 + self.exchangeContainView.frame.size.height;
        if(IPHONEX){
            y += 16;
        }
        _downloadContainView = [[UIView alloc]initWithFrame:CGRectMake(0, y, ScreenWidth, ScreenHeight - y)];
        _downloadContainView.backgroundColor = [UIColor clearColor];
        [_downloadContainView addSubview:self.downloadTableView];
        [_downloadContainView addSubview:self.downloadEditContainView];
        _downloadContainView.hidden = YES;
    }
    return _downloadContainView;
}

- (UITableView *)downloadTableView{
    if (!_downloadTableView) {
//        CGFloat y = self.playerView.frame.size.height + self.exchangeContainView.frame.size.height;
        _downloadTableView = [[UITableView alloc]init];
        _downloadTableView.frame = CGRectMake(0, 0, ScreenWidth, _downloadContainView.frame.size.height - 50);
        [_downloadTableView registerNib:[UINib nibWithNibName:@"AVCVideoDownloadTCell" bundle:nil] forCellReuseIdentifier:@"AVCVideoDownloadTCell"];
        _downloadTableView.tableFooterView = [UIView new];
        _downloadTableView.dataSource = self;
        _downloadTableView.delegate = self;
        _downloadTableView.backgroundColor = [AlivcUIConfig shared].kAVCBackgroundColor;
        [_downloadTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    }
    return _downloadTableView;
}

- (UIView *)downloadEditContainView{
    if (!_downloadEditContainView) {
        _downloadEditContainView = [[UIView alloc]initWithFrame:CGRectMake(0, self.downloadTableView.frame.size.height, ScreenWidth, 50)];
        [_downloadContainView setBackgroundColor:[UIColor colorWithHexString:@"373d41"]];
    }
    return _downloadEditContainView;
}

- (UIView *)downloadGestureView{
    if (!_downloadGestureView) {
        _downloadGestureView = [[UIView alloc]init];
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapDownloadSpace)];
        [_downloadGestureView addGestureRecognizer:gesture];
        [_downloadGestureView setBackgroundColor:[UIColor clearColor]];
    }
    return _downloadGestureView;
}

#pragma mark - System Method

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DEFAULT_DM.delegate = self;
    
    __weak typeof(self) weakself = self;
    [self configBaseUI];
    [self configBaseDataSuccess:^{
        AlivcVideoPlayListModel *model = [[AlivcVideoPlayListModel alloc]init];
        self.playerView.currentModel = model;
        [weakself startPlayVideo];
    }];
    [self loadLocalVideo];

    /**************************************/
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resignActive)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(changePresentStatue:) name:@"ShowPresentView" object:nil];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self destroyPlayVideo];
}

- (void)returnAction{
    BOOL haveDownloadingVideo = false;
    if (self.downloadingVideoArray.count > 0) {
        for (DownloadSource *video in self.downloadingVideoArray) {
            if (video.downloadStatus == DownloadTypeLoading) {
                haveDownloadingVideo = true;
                break;
            }
        }
    }
    if (haveDownloadingVideo) {
        AlivcAlertView *alertView = [[AlivcAlertView alloc]initWithAlivcTitle:nil message:NSLocalizedString(@"当前有视频在下载中,退出界面将暂停下载任务", nil)  delegate:self cancelButtonTitle:NSLocalizedString(@"取消" , nil)  confirmButtonTitle:NSLocalizedString(@"继续退出", nil) ];
        alertView.tag = alertViewTag_exit_continue;
        [alertView show];
    }else{
        [self.navigationController popViewControllerAnimated:true];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = true;
    
    NSLog(@"self view y:%f",self.view.frame.origin.y);
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = false;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void)configChanged{
    [self startPlayVideo];
}

//适配iphone x 界面问题，没有在 viewSafeAreaInsetsDidChange 这里做处理 ，主要 旋转监听在 它之后获取。
-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    NSString *platform =  [self iphoneType];
    CGFloat width = 0;
    CGFloat height = 0;
    CGFloat topHeight = 0;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait ) {
        width = ScreenWidth;
        height = ScreenWidth * 9 / 16.0;
        topHeight = 20;
        [self changeDownloadViewFrameWhenFullScreen:false];
        [self refreshUIWhenScreenChanged:false];
    }else{
        width = ScreenWidth;
        height = ScreenHeight;
        topHeight = 0;
        [self changeDownloadViewFrameWhenFullScreen:true];
        [self refreshUIWhenScreenChanged:true];
    }
    CGRect tempFrame = CGRectMake(0,topHeight, width, height);
    //    UIDevice *device = [UIDevice currentDevice] ;
    //iphone x
    if (![platform isEqualToString:@"iPhone10,3"] && ![platform isEqualToString:@"iPhone10,6"]&& ![platform isEqualToString:@"iPhone11,8"] && ![platform isEqualToString:@"iPhone11,6"]) {
        switch (orientation) {
            case UIInterfaceOrientationUnknown:
            case UIInterfaceOrientationPortraitUpsideDown:
                break;
            case UIInterfaceOrientationPortrait: {
                self.playerView.frame = tempFrame;
            }
                break;
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:  {
                self.playerView.frame = tempFrame;
            }
                break;
            default:
                break;
        }
        [self.selectView layoutSubviews];
        return;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
    switch (orientation) {
        case UIInterfaceOrientationUnknown:
        case UIInterfaceOrientationPortraitUpsideDown: {
            if (self.isStatusHidden) {
                CGRect frame = self.playerView.frame;
                frame.origin.x = VIEWSAFEAREAINSETS(self.view).left;
                frame.origin.y = VIEWSAFEAREAINSETS(self.view).top;
                frame.size.width = ScreenWidth-VIEWSAFEAREAINSETS(self.view).left*2;
                frame.size.height = ScreenHeight-VIEWSAFEAREAINSETS(self.view).bottom-VIEWSAFEAREAINSETS(self.view).top;
                self.playerView.frame = frame;
            }else{
                CGRect frame = self.playerView.frame;
                frame.origin.y = VIEWSAFEAREAINSETS(self.view).top;
                //竖屏全屏时 isStatusHidden 来自是否 旋转回调。
                if (self.playerView.fixedPortrait&&self.isStatusHidden) {
                    frame.size.height = ScreenHeight- VIEWSAFEAREAINSETS(self.view).top- VIEWSAFEAREAINSETS(self.view).bottom;
                }
                self.playerView.frame = frame;
            }
        }
            break;
        case UIInterfaceOrientationPortrait: {
            width = ScreenWidth;
            height = ScreenWidth * 9 / 16.0;
            topHeight = 20;
            [self changeDownloadViewFrameWhenFullScreen:false];
            [self refreshUIWhenScreenChanged:false];
            
            CGRect frame = CGRectMake(0, topHeight, width, height);
            frame.origin.y = VIEWSAFEAREAINSETS(self.view).top;
            //竖屏全屏时 isStatusHidden 来自是否 旋转回调。
            if (self.playerView.fixedPortrait&&self.isStatusHidden) {
                frame.size.height = ScreenHeight- VIEWSAFEAREAINSETS(self.view).top- VIEWSAFEAREAINSETS(self.view).bottom;
            }
            self.playerView.frame = frame;
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight: {
            CGRect frame = self.playerView.frame;
            frame.origin.x = VIEWSAFEAREAINSETS(self.view).left;
            frame.origin.y = VIEWSAFEAREAINSETS(self.view).top;
            frame.size.width = ScreenWidth-VIEWSAFEAREAINSETS(self.view).left*2;
            frame.size.height = ScreenHeight-VIEWSAFEAREAINSETS(self.view).bottom;
            self.playerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);// frame;
        }
            break;
        default:
            break;
    }
#endif
}

- (void)configBaseUI{
    [self.view addSubview:self.playerView];
    [self.view addSubview:self.exchangeContainView];
    [self.view addSubview:self.listView];
    [self.view addSubview:self.logView];
    [self.view addSubview:self.downloadContainView];
    self.downloadContainView.hidden = true;
    [self configDownloadEditView:self.isEdit];
}

- (void)configBaseDataSuccess:(void(^)(void))success{
    
    //加载默认的STS数据
    self.config = [[AVCVideoConfig alloc]init];
    self.config.playMethod = AliyunPlayMedthodSTS;
    __weak typeof(self)weakself = self;
    
    [AlivcAppServer getStsDataSucess:^(NSString *accessKeyId, NSString *accessKeySecret, NSString *securityToken) {
        weakself.config.stsAccessKeyId = accessKeyId;
        weakself.config.stsAccessSecret = accessKeySecret;
        weakself.config.stsSecurityToken = securityToken;
        //查询视频列表
        [AlivcVideoPlayManager requestPlayListVodPlayWithCateId:@"1000063702" sucess:^(NSArray *ary, long total) {
            
            self.listView.dataAry = ary;
            AlivcVideoPlayListModel *model = ary.firstObject;
            weakself.config.videoId = model.videoId;
            weakself.config.playMethod = AliyunPlayMedthodSTS;
            //赋值
            _currentPlayVideoModel = [ary objectAtIndex:0];
            
            NSArray *waterMarkArray = @[[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:YES]];
            NSMutableArray *dataArray  = [[NSMutableArray alloc]initWithCapacity:self.listView.dataAry.count];
            for (int i=0; i<ary.count; ++i) {
                AlivcVideoPlayListModel *itemModel = [ary objectAtIndex:i];
                itemModel.stsAccessKeyId = weakself.config.stsAccessKeyId;
                itemModel.stsAccessSecret = weakself.config.stsAccessSecret;
                itemModel.stsSecurityToken = weakself.config.stsSecurityToken;
                
                if (waterMarkArray.count > i) {
                    itemModel.waterMark = [[waterMarkArray objectAtIndex:i] boolValue];
                }
                [dataArray addObject:itemModel];
            }
             self.listView.dataAry = dataArray;
            
            if (success) {
                success();
            }
        } failure:^(NSString *errString) {
            //
        }];
    } failure:^(NSString *errorString) {
        [MBProgressHUD showMessage:errorString inView:self.view];
    }];
}

- (void)loadLocalVideo{
  
    [self.doneVideoArray removeAllObjects];
    [self.downloadingVideoArray removeAllObjects];
    
    self.downloadingVideoArray =  [NSMutableArray arrayWithArray:DEFAULT_DM.downloadingdSources];
    self.doneVideoArray = [NSMutableArray arrayWithArray:DEFAULT_DM.doneSources];
    for (DownloadSource *source in self.downloadingVideoArray) {
        source.downloadStatus = DownloadTypeStoped;
    }
    [self.downloadTableView reloadData];
}

/**
 开始播放视频
 */
- (void)startPlayVideo {
    
    // 清理播放器缓存
    if (self.config.isLocal) {
        [self.playerView reset];
        [self.playerView setTitle:self.config.videoTitle];
        [self.playerView playViewPrepareWithLocalURL:self.config.videoUrl];
    }else{
        [self.playerView stop];
        
//        [self.playerView reset];//不显示最后一帧
        //播放器播放方式
        if (!self.config) {
            self.config = [[AVCVideoConfig alloc] init];
        }
        
        switch (self.config.playMethod) {
            case AliyunPlayMedthodURL: {
                [self.playerView playViewPrepareWithURL:self.config.videoUrl];
            }
                break;
            case AliyunPlayMedthodSTS: {
                [self.playerView playViewPrepareWithVid:self.config.videoId
                                            accessKeyId:self.config.stsAccessKeyId
                                        accessKeySecret:self.config.stsAccessSecret
                                          securityToken:self.config.stsSecurityToken];
            }
                break;
            default:
                break;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Custom Method

#pragma mark - UI Refresh
/**
 刷新UI，全屏和非全屏切换的时候

 @param isFullScreen 是否全屏
 */
- (void)refreshUIWhenScreenChanged:(BOOL)isFullScreen{
    if (isFullScreen) {
//        self.selectView.hidden = true;
        self.exchangeContainView.hidden = true;
        self.logView.hidden = true;
        if (!self.isLookingVideoWhenFullScreen) {
            self.downloadContainView.hidden = true;
        }
        self.listView.hidden = YES;
    }else{
        self.isLookingVideoWhenFullScreen = false;
        //        self.selectView.hidden = false;
        self.exchangeContainView.hidden = false;
        self.downloadContainView.hidden = false;
        self.listView.hidden = NO;
        switch (self.logOrDownload) {
            case 0:
                [self listButtonTouched];
                break;
            case 1:
                [self logButtonTouched];
                break;
            case 2:
                [self offLineVideoButtonTouched];
                break;
            default:
                break;
        }
    }
}

/**
 全屏状态下显示视频下载列表视图
 */
- (void)showDownloadTableViewWhenFullScreen{
    if (ScreenWidth > ScreenHeight) {
        self.isLookingVideoWhenFullScreen = true;
        self.downloadContainView.hidden = false;
        [self.view addSubview:self.downloadGestureView];
        [self changeDownloadViewFrameWhenFullScreen:true];
    }
}

/**
 全屏状态下隐藏视频下载列表视图
 */
- (void)dismissDownloadTableViewWhenFullScreen{
    if (ScreenWidth > ScreenHeight) {
        self.isLookingVideoWhenFullScreen = false;
        self.downloadContainView.hidden = true;
        [self.downloadGestureView removeFromSuperview];
    }
}

/**
 调整下载列表视图的frame以及其中子视图的frame
 @param isFullScreen 是否全屏
 */
- (void)changeDownloadViewFrameWhenFullScreen:(BOOL)isFullScreen{
    if (!isFullScreen) {
        //竖屏
        CGFloat y = self.playerView.frame.size.height + 20 + self.exchangeContainView.frame.size.height;
        if (IPHONEX) {
            y += 16;
        }
        _downloadContainView.frame = CGRectMake(0, y, ScreenWidth, ScreenHeight - y);
        [self.downloadGestureView removeFromSuperview];
    }else{
        //全屏
        CGRect frame = self.downloadContainView.frame;
        frame.size.height = ScreenHeight;
        frame.origin.x = ScreenWidth - frame.size.width;
        frame.origin.y = 0;
        self.downloadContainView.frame = frame;
        //        self.downloadContainView.backgroundColor = [UIColor redColor];
        self.downloadGestureView.frame = CGRectMake(0, 0, ScreenWidth - frame.size.width, ScreenHeight);
    }
    _downloadTableView.frame = CGRectMake(0, 0, self.downloadContainView.frame.size.width, _downloadContainView.frame.size.height - 50);
    _downloadEditContainView.frame = CGRectMake(0, self.downloadTableView.frame.size.height, self.downloadContainView.frame.size.width, 50);
//    [self configDownloadEditView:self.isEdit]; //防止iPhone 5s下
}

/**
 适配让下载视频列表界面是否进入编辑模式

 @param isEdit 是否是编辑模式
 */
- (void)refreshUIWhenDownloadVideoIsEdit:(BOOL)isEdit{
    [self configDownloadEditView:isEdit];
    [self.downloadTableView reloadData];
}

/**
 适配下载编辑视图

 @param isEdit 是否在编辑
 */
- (void)configDownloadEditView:(BOOL)isEdit{
    self.downloadEditContainView.backgroundColor = [UIColor darkGrayColor];
    for (UIView *view in self.downloadEditContainView.subviews) {
        [view removeFromSuperview];
    }
    if (isEdit) {
        //全选
        UIButton *allButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 100, self.downloadEditContainView.frame.size.height)];
        [allButton addTarget:self action:@selector(selectAll:) forControlEvents:UIControlEventTouchUpInside];
        [allButton setTitle:NSLocalizedString(@"全选", nil) forState:UIControlStateNormal];
        [allButton setImage:[UIImage imageNamed:@"avcDownloadNormal"] forState:UIControlStateNormal];
        [allButton setImage:[UIImage imageNamed:@"avcSelected"] forState:UIControlStateSelected];
        [self.downloadEditContainView addSubview:allButton];
        allButton.selected = self.isAllSelected;
        //删除
        UIButton *deleteButton = [[UIButton alloc]initWithFrame:CGRectMake(self.downloadEditContainView.frame.size.width - 120, 0, 50, 50)];
        [deleteButton setImage:[UIImage imageNamed:@"avcDelete"] forState:UIControlStateNormal];
        [deleteButton addTarget:self action:@selector(deleteDownloadVideo) forControlEvents:UIControlEventTouchUpInside];
        [self.downloadEditContainView addSubview:deleteButton];
        //cancel的按钮
        UIButton *cancelButton = [[UIButton alloc]init];
        cancelButton.frame = CGRectMake(CGRectGetMaxX(deleteButton.frame) + 8, 0, 50, self.downloadEditContainView.frame.size.height);
        [cancelButton addTarget:self action:@selector(endEdit) forControlEvents:UIControlEventTouchUpInside];
        [cancelButton setImage:[UIImage imageNamed:@"avcClose"] forState:UIControlStateNormal];
        [self.downloadEditContainView addSubview:cancelButton];
    }else{
        
        UIButton *editButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, self.downloadEditContainView.frame.size.width, self.downloadEditContainView.frame.size.height)];
        [editButton setTitle:NSLocalizedString(@"编辑", nil)  forState:UIControlStateNormal];
        [editButton addTarget:self action:@selector(editVideo) forControlEvents:UIControlEventTouchUpInside];
        [self.downloadEditContainView addSubview:editButton];
    }
}

- (void)destroyPlayVideo{
    if (_playerView != nil) {
        [_playerView stop];
        [_playerView releasePlayer];
        [_playerView removeFromSuperview];
        _playerView = nil;
    }
}

#pragma mark - Response

- (void)listButtonTouched{
    self.listView.hidden = NO;
    self.logOrDownload = 0;
    
    self.downloadContainView.hidden = true;
    self.logView.hidden = YES;
    
    CGFloat cx = self.exchangeContainView.frame.size.width * 1 / 6;
    CGFloat cy = self.exchangeLineView.center.y;
    [UIView animateWithDuration:0.5 animations:^{
        self.exchangeLineView.center = CGPointMake(cx, cy);
    }];
}

- (void)logButtonTouched{
    self.logView.hidden = false;
    self.logOrDownload = 1;
    
    self.listView.hidden = YES;
    self.downloadContainView.hidden = true;
    
    CGFloat cx = self.exchangeContainView.frame.size.width *1  /2;
    CGFloat cy = self.exchangeLineView.center.y;
    [UIView animateWithDuration:0.5 animations:^{
        self.exchangeLineView.center = CGPointMake(cx, cy);
    }];
}

- (void)offLineVideoButtonTouched{
    self.redView.hidden = true;
    if (ScreenWidth < ScreenHeight) {
        self.logView.hidden = true;
        self.logOrDownload = 2;
        
        self.listView.hidden = YES;
        self.downloadContainView.hidden = false;
        
        CGFloat cx = self.exchangeContainView.frame.size.width * 5 / 6;
        CGFloat cy = self.exchangeLineView.center.y;
        [UIView animateWithDuration:0.5 animations:^{
            self.exchangeLineView.center = CGPointMake(cx, cy);
        }];
    }
}

- (void)changePresentStatue:(NSNotification *)noti {
    if ([noti.object isEqual:@"1"]) {
        self.isPresent = YES;
    }else if ([noti.object isEqual:@"0"]){
        self.isPresent = NO;
    }
}

- (void)willResignActive {
    if (_playerView &&  self.playerView.playerViewState == AVPStatusStarted){
        [self.playerView pause];
    }
}

- (void)becomeActive{
    if (self.isPresent == NO) {
        self.isBecome = NO;
        NSLog(@"%@%ld",NSLocalizedString(@"播放器状态:", nil),(long)self.playerView.playerViewState);
        if (self.playerView && [self.playerView getPopLayerIsHidden] == YES){
            [self.playerView resume];
        }
    }
}

- (void)resignActive{
    if (self.isPresent) {
        self.isBecome = YES;
    }
    if (_playerView &&  self.playerView.playerViewState == AVPStatusStarted){
        [self.playerView pause];
    }
}

- (NSString*)iphoneType {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString*platform = [NSString stringWithCString: systemInfo.machine encoding:NSASCIIStringEncoding];
    return platform;
}

- (void)editVideo{
    self.isEdit = true;
    self.editVideoArray = [[NSMutableArray alloc]init];
    [self refreshUIWhenDownloadVideoIsEdit:true];
}

- (void)selectAll:(UIButton *__nullable)button{
    button.selected = !button.isSelected;
    self.isAllSelected = button.selected;
    if (button.selected) {
        if (self.downloadingVideoArray.count > 0) {
            [self.editVideoArray addObjectsFromArray:self.downloadingVideoArray];
        }
        if (self.doneVideoArray.count > 0) {
            [self.editVideoArray addObjectsFromArray:self.doneVideoArray];
        }
        
    }else{
        [self.editVideoArray removeAllObjects];
    }
    [self.downloadTableView reloadData];
}

- (void)deleteDownloadVideo{
    if (self.editVideoArray.count == 0) {
        [MBProgressHUD showMessage:NSLocalizedString(@"请选择至少一个视频", nil) inView:self.view];
    }else{
        AlivcAlertView *alertView = [[AlivcAlertView alloc]initWithAlivcTitle:nil message:NSLocalizedString(@"确定要删除选中的视频吗?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"取消", nil) confirmButtonTitle:NSLocalizedString(@"确定", nil)];
        alertView.tag = alertViewTag_delete_video;
        [alertView showInView:self.view];
    }
}

- (void)endEdit{
    self.isEdit = false;
    [self refreshUIWhenDownloadVideoIsEdit:false];
}

//横屏下下载列表空白区域点击
- (void)tapDownloadSpace{
    [self dismissDownloadTableViewWhenFullScreen];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == alertViewTag_downLoad_continue) {
        if (buttonIndex == 1) {
            [self prepareTODownLoadWithVideoId:self.config.videoId];
            return;
        }
    }
    
    if (alertView.tag == alertViewTag_delete_video) {
        if (buttonIndex == 1) {
            for (DownloadSource *video in self.editVideoArray) {
                [DEFAULT_DM clearMedia:video];
                [self.downloadingVideoArray removeObject:video];
                [self.doneVideoArray removeObject:video];
                [MBProgressHUD showWarningMessage:NSLocalizedString(@"视频已删除", nil) inView:self.view];
            }
            self.isEdit = false;
            [self refreshUIWhenDownloadVideoIsEdit:self.isEdit];
        }
        return;
    }
    
    // 是否退出
    if (alertView.tag == alertViewTag_exit_continue) {
        if (buttonIndex == 1) {
            for (DownloadSource *source in self.downloadingVideoArray) {
                [source stopDownLoad];
            }
            [self.navigationController popViewControllerAnimated:true];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger )numberOfSectionsInTableView:(UITableView *)tableView{
    NSInteger sections = 0;
    if (self.downloadingVideoArray.count > 0) {
        sections += 1;
    }
    if (self.doneVideoArray.count > 0) {
        sections += 1;
    }
    return sections;
}

- (NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:{
            if (self.downloadingVideoArray.count > 0) {
                return  self.downloadingVideoArray.count;
            }else{
                return self.doneVideoArray.count;
            }
        }
            break;
        case 1:{
            return self.doneVideoArray.count;
        }
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    AVCVideoDownloadTCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AVCVideoDownloadTCell"];
    DownloadSource *video = nil;
    switch (indexPath.section) {
        case 0:
            if (self.downloadingVideoArray.count > 0 && indexPath.row < self.downloadingVideoArray.count) {
                video = self.downloadingVideoArray[indexPath.row];
            }else if(indexPath.row < self.doneVideoArray.count){
                video = self.doneVideoArray[indexPath.row];
            }
            break;
        case 1:
            if (indexPath.row < self.doneVideoArray.count) {
                video = self.doneVideoArray[indexPath.row];
            }
            
            break;
            
        default:
            break;
    }
    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (video) {
        [cell configWithSource:video];
        //选中状态根据self.editVideoArray来适配，保证ui和数据的统一
        BOOL haveSelected = false;
        for (DownloadSource *editVideo in self.editVideoArray) {
            if ([editVideo isEqualToSource:video]) {
                haveSelected = true;
                break;
            }
        }
        [cell setSelectedCustom:haveSelected];
    }
    [cell setTOEditStyle:self.isEdit];
    return cell;
}

- (NSString *)titleStringForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            if (self.downloadingVideoArray.count > 0) {
                return [NSLocalizedString(@"正在缓存", nil)  localString];
            }else{
                return [NSLocalizedString(@"已缓存", nil) localString];
            }
            break;
        case 1:
            return [NSLocalizedString(@"已缓存", nil)localString];
            
        default:
            break;
    }
    return @"";
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
    titleLabel.text = [self titleStringForHeaderInSection:section];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    [titleLabel sizeToFit];
    return titleLabel;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100.0f;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    DownloadSource *video = nil;
    switch (indexPath.section) {
        case 0:{
            if (self.downloadingVideoArray.count > 0) {
                if (indexPath.row < self.downloadingVideoArray.count) {
                    video = self.downloadingVideoArray[indexPath.row];
                }
            }else{
                if (indexPath.row < self.doneVideoArray.count) {
                    video = self.doneVideoArray[indexPath.row];
                }
            }
        }
            break;
        case 1:{
            if (indexPath.row < self.doneVideoArray.count) {
                video = self.doneVideoArray[indexPath.row];
            }
        }
        default:
            break;
    }
    
    if (video) {
        if (self.isEdit) {
            //切换选中非选中状态
            AVCVideoDownloadTCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            BOOL selected = !cell.customSelected;
            [cell setSelectedCustom:selected];
            if (selected) {
                [self.editVideoArray addObject:video];
            }else{
                [self.editVideoArray removeObject:video];
            }
        }else{
            //播放视频
            [self changeToPlayLocalVideo:video];
        }
        
    }
}

- (void)changeToPlayLocalVideo:(DownloadSource *)video{
    if (video.downloadStatus != DownloadTypefinish) {
        [MBProgressHUD showMessage:NSLocalizedString(@"视频还未下载完成", nil) inView:self.view];
        return;
    }
    
    NSString *path = DEFAULT_DM.downLoadPath;
    NSString *str = [NSString stringWithFormat:@"%@/%@",path,video.downloadedFilePath];
    self.config.playMethod = AliyunPlayMedthodURL;
    self.config.isLocal = true;
    self.config.videoUrl = [NSURL URLWithString:str];
    self.config.video_format = video.title;
    self.config.videoId = video.vid;
    self.config.videoTitle = video.title;
    
    AlivcVideoPlayListModel *model = [[AlivcVideoPlayListModel alloc]init];
    self.playerView.currentModel = model;
    [self startPlayVideo];
}

#pragma mark -  AVCVideoDownloadTCellDelegate
- (void)videoDownTCell:(AVCVideoDownloadTCell *)cell video:(DownloadSource *)video selected:(BOOL)selected{
    if (selected) {
        [self.editVideoArray addObject:video];
    }else{
        [self.editVideoArray removeObject:video];
    }
}

- (void)videoDownTCell:(AVCVideoDownloadTCell *)cell actionButtonTouchedWithVideo:(DownloadSource *)video{
    
    switch (video.downloadStatus) {
        case DownloadTypeStoped: {
            self.readyDataSource = video;
            [video startDownLoad:self.view];
        }
            break;
        case DownloadTypePrepared :{
            //重新开始下载 - stsData得重新获取
            [video startDownLoad:self.view];
        }
            break;
        case DownloadTypeFailed :{
            [video startDownLoad:self.view];
        }
            break;
        case DownloadTypeLoading:{
            //暂停下载
            [video stopDownLoad];
            video.downloadStatus = DownloadTypeStoped;
        }
            break;
        case DownloadTypeWaiting:
            break;
        default:
            break;
    }
    [self.downloadTableView reloadData];
}

#pragma mark - Download

- (void)showAlertViewWithString:(NSString *)string{
    AlivcAlertView *alertView = [[AlivcAlertView alloc]initWithAlivcTitle:nil message:string delegate:self cancelButtonTitle:nil confirmButtonTitle:NSLocalizedString(@"确定", nil)];
    [alertView showInView:self.view];
}

- (void)prepareTODownLoadWithVideoId:(NSString *)vid{
    //准备下载

    [AlivcAppServer getStsDataSucess:^(NSString * _Nonnull accessKeyId, NSString * _Nonnull accessKeySecret, NSString * _Nonnull securityToken) {
        //AliyunDataSource
        DEFAULT_DM.accessKeyId = accessKeyId;
        DEFAULT_DM.accessKeySecret = accessKeySecret;
        DEFAULT_DM.securityToken = securityToken;
        DownloadSource *source = [[DownloadSource alloc]init];
        source.vid = self.config.videoId;
        self.readyDataSource = source;
        [DEFAULT_DM clearAllPreparedSources];
        [DEFAULT_DM prepareDownloadSource:self.readyDataSource];
       
    } failure:^(NSString * _Nonnull errorString) {
        [MBProgressHUD showMessage:errorString inView:self.view];
    }];
}

#pragma mark DownloadManagerDelegate

/**
 @brief 下载准备完成事件回调
 @param source 下载source指针
 @param info 下载准备完成回调，@see AVPMediaInfo
 */
-(void)downloadManagerOnPrepared:(DownloadSource *)source mediaInfo:(AVPMediaInfo*)info {
   
    self.readyDataSource = source;
    NSLog(@"准备下载 ---- \n ");
    if (![self.hud isHidden]) {
        [self.hud hideAnimated:true];
    }

    if (_clickDownload == YES) {
        [self.selectView removeFromSuperview];
        self.selectView = [[AVCSelectSharpnessView alloc]initWithMedias:info.tracks source:source];
        [self.selectView showInView:self.view];
        self.selectView.delegate = self;
        _clickDownload = NO;
    }
}

/**
 @brief 错误代理回调
 @param source 下载source指针
 @param errorModel 播放器错误描述，参考AliVcPlayerErrorModel
 */
- (void)downloadManagerOnError:(DownloadSource *)source errorModel:(AVPErrorModel *)errorModel {
    
    NSLog(@"下载错误:%@",errorModel.message);
    for (DownloadSource *downloadVideo in self.downloadingVideoArray) {
        BOOL isfind = [downloadVideo refreshStatusWithMedia:source];
        if (isfind) {
            downloadVideo.downloadStatus = DownloadTypeFailed;
            break;
        }
    }
    [self.downloadTableView reloadData];
}

/**
 @brief 下载进度回调
 @param source 下载source指针
 @param percent 下载进度 0-100
 */
- (void)downloadManagerOnProgress:(DownloadSource *)source percentage:(int)percent {
    
    NSLog(@"~~~~~~~~~~%d",percent);
    source.downloadStatus = DownloadTypeLoading;
    DownloadSource *currentSource = nil;
    for (DownloadSource *downloadSource in self.downloadingVideoArray) {
        BOOL success = (downloadSource == source);
        if (success) {
            currentSource = downloadSource;
            break;
        }
        
    }
    //找到对应的cell
    currentSource.percent = percent;
    if (currentSource) {
        NSInteger index = [self.downloadingVideoArray indexOfObject:currentSource];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        UITableViewCell *cell = [self.downloadTableView cellForRowAtIndexPath:indexPath];
        AVCVideoDownloadTCell *downloadCell = (AVCVideoDownloadTCell *)cell;
        if (downloadCell) {
            [downloadCell configWithSource:currentSource];
        }
    }
}

/**
 @brief 下载完成回调
 @param source 下载source指针
 */
- (void)downloadManagerOnCompletion:(DownloadSource *)source {
    if (source) {
        [source refreshStatusWithMedia:source];
        source.downloadStatus = DownloadTypefinish;
        [self.downloadingVideoArray removeObject:source];
        [self.doneVideoArray addObject:source];
        [self.downloadTableView reloadData];
        
        //添加或者更新进本地数据库
        [[AlivcVideoDataBase shared]deleteVideo:source];
        [[AlivcVideoDataBase shared]addVideo:source];
        NSString *showString = [NSString stringWithFormat:@"%@ %@",source.title,NSLocalizedString(@"下载成功", nil)];
        [MBProgressHUD showSucessMessage:showString inView:self.view];
    }
}

/**
 下载状态改变回调
 */
- (void)onSourceStateChanged:(DownloadSource *)source {
    [self.downloadTableView reloadData];
}

#pragma mark - AliyunVodPlayerViewDelegate
- (void)onDownloadButtonClickWithAliyunVodPlayerView:(AliyunVodPlayerView *)playerView{
    
    _clickDownload = YES;
    
    //判断视频类型
    if (self.config.playMethod == AliyunPlayMedthodURL) {
        [self showAlertViewWithString:NSLocalizedString(@"此类型的视频不支持下载", nil)];
        return;
    }
    //判断网络
    _reachability = [AliyunReachability reachabilityForInternetConnection];
    [_reachability startNotifier];
    switch ([self.reachability currentReachabilityStatus]) {
        case AliyunPVNetworkStatusNotReachable://由播放器底层判断是否有网络
            break;
        case AliyunPVNetworkStatusReachableViaWiFi:
            break;
        case AliyunPVNetworkStatusReachableViaWWAN: {
            AlivcAlertView *alertView = [[AlivcAlertView alloc]initWithAlivcTitle:nil message:NSLocalizedString(@"当前网络环境为4G,继续下载将耗费流量", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"取消", nil) confirmButtonTitle:NSLocalizedString(@"确定", nil)];
            alertView.tag = alertViewTag_downLoad_continue;
            [alertView show];
            return;
        }
            break;
        default:
            break;
    }
    
    // 准备下载
    [self prepareTODownLoadWithVideoId:self.config.videoId];
    self.hud = [MBProgressHUD showMessage:NSLocalizedString(@"请求资源中...", nil)  alwaysInView:self.view];
    [self.hud hideAnimated:true afterDelay:15];
}

- (void)onBackViewClickWithAliyunVodPlayerView:(AliyunVodPlayerView *)playerView{
    [self returnAction];
}

- (void)aliyunVodPlayerView:(AliyunVodPlayerView *)playerView happen:(AVPEventType)event{
    AVCLogModel *model = [[AVCLogModel alloc]initWithEvent:event];
    [self.logView haveReceivedNewEvent:model];
}

- (void)aliyunVodPlayerView:(AliyunVodPlayerView*)playerView onPause:(NSTimeInterval)currentPlayTime{
    NSLog(@"onPause");
}

- (void)aliyunVodPlayerView:(AliyunVodPlayerView*)playerView onResume:(NSTimeInterval)currentPlayTime{
    NSLog(@"onResume");
}

- (void)aliyunVodPlayerView:(AliyunVodPlayerView*)playerView onStop:(NSTimeInterval)currentPlayTime{
    NSLog(@"onStop");
}

- (void)aliyunVodPlayerView:(AliyunVodPlayerView*)playerView onSeekDone:(NSTimeInterval)seekDoneTime{
    NSLog(@"onSeekDone");
}

-(void)onFinishWithAliyunVodPlayerView:(AliyunVodPlayerView *)playerView{
    NSLog(@"onFinish");
    if (self.config.isLocal && self.doneVideoArray.count > 0) {
        [self.playerView setUIStatusToReplay];
        return;
    }
    //vid列表播放
    [self.listView playNextMediaVideo];
}

- (void)aliyunVodPlayerView:(AliyunVodPlayerView *)playerView lockScreen:(BOOL)isLockScreen{
    self.isLock = isLockScreen;
}

- (void)aliyunVodPlayerView:(AliyunVodPlayerView *)playerView fullScreen:(BOOL)isFullScreen{
    NSLog(@"isfullScreen --%d",isFullScreen);
    
    self.isStatusHidden = isFullScreen  ;
    [self refreshUIWhenScreenChanged:isFullScreen];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)aliyunVodPlayerView:(AliyunVodPlayerView *)playerView onVideoDefinitionChanged:(NSString *)videoDefinition {
}

- (void)onSecurityTokenExpiredWithAliyunVodPlayerView:(AliyunVodPlayerView *)playerView {
    __weak typeof(self) weakself = self;
    [AlivcAppServer getStsDataSucess:^(NSString * _Nonnull accessKeyId, NSString * _Nonnull accessKeySecret, NSString * _Nonnull securityToken) {
        weakself.config.stsAccessKeyId = accessKeyId;
        weakself.config.stsAccessSecret = accessKeySecret;
        weakself.config.stsSecurityToken = securityToken;
        for (AlivcVideoPlayListModel *model in self.listView.dataAry) {
            model.stsAccessKeyId = weakself.config.stsAccessKeyId;
            model.stsAccessSecret = weakself.config.stsAccessSecret;
            model.stsSecurityToken = weakself.config.stsSecurityToken;
        }
        [self startPlayVideo];
    } failure:^(NSString * _Nonnull errorString) {
        [MBProgressHUD showMessage:errorString inView:self.view];
    }];
}

- (void)onCircleStartWithVodPlayerView:(AliyunVodPlayerView *)playerView {
}

- (void)onClickedAirPlayButtonWithVodPlayerView:(AliyunVodPlayerView *)playerView{
    [MBProgressHUD showSucessMessage:@"功能正在开发中" inView:self.view];
}

- (void)onClickedBarrageBtnWithVodPlayerView:(AliyunVodPlayerView *)playerView{
    [MBProgressHUD showSucessMessage:NSLocalizedString(@"功能正在开发中", nil) inView:self.view];
}

#pragma mark - AVCSelectSharpnessViewDelegate
- (void)selectSharpnessView:(AVCSelectSharpnessView *)view haveSelectedMediaInfo:(AVPTrackInfo *)medioInfo{
    self.readyDataSource.format = medioInfo.vodFormat;
    CGFloat mSize = (CGFloat)medioInfo.vodFileSize / 1024 / 1024;
    NSString *mString = [NSString stringWithFormat:@"%.1fM",mSize];
    self.readyDataSource.totalDataString = mString;
    self.readyDataSource.trackIndex = medioInfo.trackIndex;
}

- (void)selectSharpnessView:(AVCSelectSharpnessView *)view okButtonTouched:(UIButton *)button{
    // 开始下载
    for (DownloadSource *video in self.downloadingVideoArray){
        if ([video isEqualToSource:self.readyDataSource]) {
            [MBProgressHUD showMessage:NSLocalizedString(@"该视频已在下载,请耐心等待", nil) inView:self.view];
            return;
        }
    }
    for (DownloadSource *video in self.doneVideoArray){
        if ([video isEqualToSource:self.readyDataSource]) {
            [MBProgressHUD showMessage:NSLocalizedString(@"该视频已下载完成" , nil)inView:self.view];
            return;
        }
    }
    BOOL find = false;
    for (DownloadSource *source in self.downloadingVideoArray) {
        if (source == self.readyDataSource) {
            find = true;
            [self.downloadTableView reloadData];
            return;
        }
    }
    if (!find) {
        //显示小红点
        if (self.logOrDownload != 2) {
                self.redView.hidden = false;
        }
        [self.downloadingVideoArray addObject:self.readyDataSource];
        [self.downloadTableView reloadData];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *url = [NSURL URLWithString:self.readyDataSource.coverURL];
            if (url) {
                NSData *imageData = [NSData dataWithContentsOfURL:url];
                if (imageData) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                         self.readyDataSource.video_imageData = imageData;
                         [[AlivcVideoDataBase shared]addVideo:self.readyDataSource];// 加入数据库
                    });
                }
            }
        });
    }
    
    [DEFAULT_DM addDownloadSource:self.readyDataSource];
    [DEFAULT_DM startDownloadSource:self.readyDataSource];
    
    [view dismiss];
    if (ScreenWidth > ScreenHeight) {
        [self showDownloadTableViewWhenFullScreen];
    }
}

- (void)selectSharpnessView:(AVCSelectSharpnessView *)view cancelButtonTouched:(UIButton *)button{
    [view dismiss];
}

- (void)selectSharpnessView:(AVCSelectSharpnessView *)view lookVideoButtonTouched:(UIButton *)button{
    //横屏状态下才有这个按钮 1.隐藏选择视图， 2.展示视频列表视图
    if (ScreenWidth > ScreenHeight) {
        [view dismiss];
        [self showDownloadTableViewWhenFullScreen];
    }
}

#pragma mark - AlivcPlayListsViewDelegate
- (void)alivcPlayListsView:(AlivcPlayListsView *)playListsView didSelectModel:(AlivcVideoPlayListModel *)listModel{
    
    _currentPlayVideoModel = listModel;
    self.playerView.currentModel = listModel;
    self.playerView.coverUrl = [NSURL URLWithString:listModel.coverURL];
    [self.playerView setTitle:listModel.title];
    self.config.isLocal = false;
    if (listModel.videoUrl) {
        self.config.playMethod = AliyunPlayMedthodURL;
        self.config.videoUrl = [NSURL URLWithString:listModel.videoUrl];
        [self startPlayVideo];
        
    }else if (listModel.videoId  && !listModel.videoUrl){
        self.config.playMethod = AliyunPlayMedthodSTS;
        self.config.videoId = listModel.videoId;
        self.config.stsAccessKeyId = listModel.stsAccessKeyId;
        self.config.stsAccessSecret = listModel.stsAccessSecret;
        self.config.stsSecurityToken = listModel.stsSecurityToken;
        [self startPlayVideo];
    }
}

- (void)alivcPlayListsView:(AlivcPlayListsView *)playListsView playSettingButtonTouched:(UIButton *)buton{
    [self.playerView pause];
    
    AVC_VP_PlaySettingVC *targetVC = [[AVC_VP_PlaySettingVC alloc]initWithNibName:@"AVC_VP_PlaySettingVC" bundle:[NSBundle mainBundle]];
    
    __weak typeof(self) weakself = self;
    targetVC.setBlock = ^(AVCVideoConfig *config) {
        
        weakself.config = config;
        weakself.isPresent = NO;
        [weakself.playerView reset];
        
        AlivcVideoPlayListModel *model = [[AlivcVideoPlayListModel alloc]init];
        model.videoUrl = [config.videoUrl absoluteString];
        weakself.playerView.currentModel = model;
        [weakself.playerView setTitle:nil];
        
        switch (config.playMethod) {
            case AliyunPlayMedthodURL: {
                [weakself.playerView playViewPrepareWithURL:config.videoUrl];
            }
                break;
            case AliyunPlayMedthodSTS: {
                [weakself.playerView playViewPrepareWithVid:config.videoId
                                                accessKeyId:config.stsAccessKeyId
                                            accessKeySecret:config.stsAccessSecret
                                              securityToken:config.stsSecurityToken];
            }
                break;
            default:
                break;
        }
    };
    
    targetVC.backBlock = ^{
        [weakself.playerView resume];
        weakself.isPresent = NO;
    };
    
    targetVC.enterViewBlock = ^{
        weakself.isPresent = YES;
    };
    
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:targetVC];
    [self presentViewController:nav animated:true completion:nil];
}

#pragma mark - 锁屏功能
/**
 * 说明：播放器父类是UIView。
 屏幕锁屏方案需要用户根据实际情况，进行开发工作；
 如果viewcontroller在navigationcontroller中，需要添加子类重写navigationgController中的 以下方法，根据实际情况做判定 。
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    if (self.isLock) {
        return toInterfaceOrientation = UIInterfaceOrientationPortrait;
    }else{
        return YES;
    }
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate{
    return !self.isLock;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    if (self.isLock) {
        return UIInterfaceOrientationMaskLandscapeRight;
    }else{
        return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskLandscapeLeft|UIInterfaceOrientationMaskLandscapeRight;
    }
}

-(BOOL)prefersStatusBarHidden {
    return self.isStatusHidden;
}

@end

NS_ASSUME_NONNULL_END
