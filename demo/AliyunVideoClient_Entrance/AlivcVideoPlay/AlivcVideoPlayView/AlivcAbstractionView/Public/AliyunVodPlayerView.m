//
//  AliyunVodPlayerView.m
//  AliyunVodPlayerViewSDK
//
//  Created by SMY on 16/9/8.
//  Copyright © 2016年 SMY. All rights reserved.
//

#import "AliyunVodPlayerView.h"

//public
#import "AliyunPrivateDefine.h"
#import "AliyunReachability.h"

//data
#import "AliyunDataSource.h"

//view
#import "AliyunPlayerViewControlView.h"
#import "AliyunViewMoreView.h"
#import "AliyunPlayerViewFirstStartGuideView.h"

//tipsView
#import "AliyunPlayerViewPopLayer.h"
#import "AliyunPlayerViewErrorView.h"
#import "MBProgressHUD+AlivcHelper.h"

//loading
#import "AlilyunViewLoadingView.h"

//log
#import "AliyunLog.h"

#import "NSString+AlivcHelper.h"
#import "AliyunPlayerViewProgressView.h"
#import "UIImageView+WebCache.h"
#import "AlivcVideoPlayThumbnailView.h"

#define PLAY_VIEW @"playView"

static const CGFloat AlilyunViewLoadingViewWidth  = 130;
static const CGFloat AlilyunViewLoadingViewHeight = 120;

@interface AliyunVodPlayerView () <AVPDelegate,AliyunPVPopLayerDelegate,AliyunControlViewDelegate,AliyunViewMoreViewDelegate>

#pragma mark - view
@property (nonatomic, strong) UIButton *downloadButton;               //下载按钮
@property (nonatomic, strong) AliPlayer *aliPlayer;               //点播播放器
@property (nonatomic, strong) UIView *playerView;
@property (nonatomic, strong) UIImageView *coverImageView;              //封面
@property (nonatomic, strong) AliyunPlayerViewControlView *controlView;
@property (nonatomic, strong) AliyunViewMoreView *moreView;             //更多界面
@property (nonatomic, strong) AliyunPlayerViewFirstStartGuideView *guideView;     //导航
@property (nonatomic, strong) AliyunPlayerViewPopLayer *popLayer;               //弹出的提示界面
@property (nonatomic, strong) AlilyunViewLoadingView *loadingView;         //loading
@property (nonatomic, strong) AlilyunViewLoadingView *qualityLoadingView;  //清晰度loading

#pragma mark - data
@property (nonatomic, strong) AliyunReachability *reachability;       //网络监听
@property (nonatomic, assign) CGRect saveFrame;                         //记录竖屏时尺寸,横屏时为全屏状态。
@property (nonatomic ,assign) ALYPVPlayMethod playMethod; //播放方式
@property (nonatomic, weak  ) NSTimer *timer;                           //计时器
@property (nonatomic, assign) NSTimeInterval currentDuration;           //记录播放时长
@property (nonatomic, copy  ) NSString *currentMediaTitle;              //设置标题，如果用户已经设置自己标题，不在启用请求获取到的视频标题信息。
@property (nonatomic, assign) BOOL isProtrait;                          //是否是竖屏
@property (nonatomic, assign) BOOL isRerty;                             //default：NO
@property (nonatomic, assign) float saveCurrentTime;                    //保存重试之前的播放时间
@property (nonatomic, assign) BOOL mProgressCanUpdate;                  //进度条是否更新，默认是NO
@property (nonatomic, strong) AliyunLog *playerViewLog;    //日志

#pragma mark - 播放方式
@property (nonatomic, strong) AliyunLocalSource *localSource;   //url 播放方式
@property (nonatomic, strong) AliyunPlayAuthModel *playAuthModel;    //vid+playAuth 播放方式
@property (nonatomic, strong) AliyunSTSModel *stsModel;              //vid+STS 播放方式
@property (nonatomic, strong) AliyunMPSModel *mpsModel;              //vid+MPS 播放方式

@property (nonatomic, assign) AVPStatus currentPlayStatus; //记录播放器的状态

@property (strong, nonatomic) AVPTrackInfo *currentTrackInfo;

@property (nonatomic, assign) CGFloat touchDownProgressValue;

@property (nonatomic, assign) NSTimeInterval keyFrameTime;

@property (nonatomic,strong)AlivcVideoPlayThumbnailView *thumbnailView;
@property (nonatomic,assign)BOOL progressIsTouchDown;

@property (nonatomic,assign)BOOL trackHasThumbnai;

@property (nonatomic,assign)AVPSeekMode seekMode;

@end

@implementation AliyunVodPlayerView

#pragma mark - 懒加载
- (AliPlayer *)aliPlayer {
    if (!_aliPlayer) {
        _aliPlayer = [[AliPlayer alloc] init];
        _aliPlayer.scalingMode =  AVP_SCALINGMODE_SCALEASPECTFIT;
    }
    return _aliPlayer;
}

- (UIView *)playerView {
    if (!_playerView) {
        _playerView = [[UIView alloc]init];
    }
    return _playerView;
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.backgroundColor = [UIColor clearColor];
        _coverImageView.contentMode =  UIViewContentModeScaleAspectFill;
        _coverImageView.clipsToBounds = YES;
    }
    return _coverImageView;
}

- (AliyunPlayerViewControlView *)controlView {
    if (!_controlView) {
        _controlView = [[AliyunPlayerViewControlView alloc] init];
    }
    return _controlView;
}

- (AliyunViewMoreView *)moreView {
    if (!_moreView) {
        _moreView = [[AliyunViewMoreView alloc] init];
    }
    return _moreView;
}

- (AliyunPlayerViewFirstStartGuideView *)guideView {
    if (!_guideView) {
        _guideView = [[AliyunPlayerViewFirstStartGuideView alloc] init];
    }
    return _guideView;
}

- (AliyunPlayerViewPopLayer *)popLayer {
    if (!_popLayer) {
        _popLayer = [[AliyunPlayerViewPopLayer alloc] init];
        _popLayer.frame = self.bounds;
        _popLayer.hidden = YES;
    }
    return _popLayer;
}

- (AlilyunViewLoadingView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[AlilyunViewLoadingView alloc] init];
    }
    return _loadingView;
}

- (AlilyunViewLoadingView *)qualityLoadingView {
    if (!_qualityLoadingView) {
        _qualityLoadingView = [[AlilyunViewLoadingView alloc] init];
    }
    return _qualityLoadingView;
}

- (AlivcVideoPlayThumbnailView *)thumbnailView {
    if (!_thumbnailView) {
        _thumbnailView = [[AlivcVideoPlayThumbnailView alloc]init];
        _thumbnailView.hidden = YES;
    }
    return _thumbnailView;
}

- (AVPSeekMode)seekMode {
    if (self.aliPlayer.duration < 300000) {
        return AVP_SEEKMODE_ACCURATE;
    }
    return AVP_SEEKMODE_INACCURATE;
}

#pragma mark - init
- (instancetype)init {
    self.mProgressCanUpdate = NO;
    return [self initWithFrame:CGRectZero];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    //指记录竖屏时界面尺寸
    if ([AliyunUtil isInterfaceOrientationPortrait]){
        if (!self.fixedPortrait) {
            self.saveFrame = frame;
        }
    }
}

- (void)setViewSkin:(AliyunVodPlayerViewSkin)viewSkin {
    _viewSkin = viewSkin;
    self.controlView.skin = viewSkin;
    self.guideView.skin = viewSkin;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame andSkin:AliyunVodPlayerViewSkinBlue];
}

//初始化view
- (void)initView {
    self.keyFrameTime = 0;
    self.aliPlayer.delegate = self;
    self.aliPlayer.playerView = self.playerView;
    [self addSubview:self.playerView];
    [self addSubview:self.coverImageView];
    
    self.controlView.delegate = self;
   // [self.controlView updateViewWithPlayerState:self.aliPlayer.playerState isScreenLocked:self.isScreenLocked fixedPortrait:self.isProtrait];
    [self addSubview:self.controlView];

    self.moreView.delegate = self;
    [self addSubview:self.moreView];
    
    self.popLayer.delegate = self;
    [self addSubview:self.popLayer];
    [self addSubview:self.loadingView];
    [self addSubview:self.qualityLoadingView];
    [self addSubview:self.thumbnailView];
}

- (AliyunLog *)playerViewLog {
    if (!_playerViewLog) {
        _playerViewLog = [[AliyunLog alloc] init];
        _playerViewLog.isPrintLog = NO;
    }
    return _playerViewLog;
}

- (void)changeSpeed:(NSNotification *)noti {
    CGFloat speed =  [noti.object floatValue];
    self.aliPlayer.rate = speed;
}

#pragma mark - 指定初始化方法
- (instancetype)initWithFrame:(CGRect)frame andSkin:(AliyunVodPlayerViewSkin)skin {
    self = [super initWithFrame:frame];
    if (self) {
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(changeSpeed:) name:@"PlayerWillChangeSpeed" object:nil];
    
        if ([AliyunUtil isInterfaceOrientationPortrait]){
            self.saveFrame = frame;
        }else{
            self.saveFrame = CGRectZero;
        }
        self.mProgressCanUpdate = YES;
        //设置view
        [self initView];
        //加载控件皮肤
        self.viewSkin = skin;
        //屏幕旋转通知
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDeviceOrientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil
         ];
        
        //网络状态判定
        _reachability = [AliyunReachability reachabilityForInternetConnection];
        [_reachability startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged)
                                                     name:AliyunPVReachabilityChangedNotification
                                                   object:nil];
        //存储第一次触发saas
        NSString *str =   [[NSUserDefaults standardUserDefaults] objectForKey:@"aliyunVodPlayerFirstOpen"];
        if (!str) {
            [[NSUserDefaults standardUserDefaults] setValue:@"aliyun_saas_first_open" forKey:@"aliyunVodPlayerFirstOpen"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    return self;
}

#pragma mark - layoutSubviews
- (void)layoutSubviews {
    [super layoutSubviews];
    float width = self.bounds.size.width;
    float height = self.bounds.size.height;
    self.playerView.frame = self.bounds;
    
    self.coverImageView.frame= self.bounds;
    //self.coverImageView.frame = CGRectZero;
    self.controlView.frame = self.bounds;
    self.moreView.frame = self.bounds;
    self.guideView.frame =  self.bounds;
    self.popLayer.frame = self.bounds;
    self.popLayer.center = CGPointMake(width/2, height/2);
    
    float x = (self.bounds.size.width -  AlilyunViewLoadingViewWidth)/2;
    float y = (self.bounds.size.height - AlilyunViewLoadingViewHeight)/2;
    self.qualityLoadingView.frame = self.loadingView.frame = CGRectMake(x, y, AlilyunViewLoadingViewWidth, AlilyunViewLoadingViewHeight);
    self.thumbnailView.frame = CGRectMake(width/2-80, height/2-60, 160, 120);
}

#pragma mark - 网络状态改变
- (void)reachabilityChanged {
    [self networkChangedToShowPopView];
}

//网络状态判定
- (BOOL)networkChangedToShowPopView {
    BOOL ret = NO;
    switch ([self.reachability currentReachabilityStatus]) {
        case AliyunPVNetworkStatusNotReachable://由播放器底层判断是否有网络
            break;
        case AliyunPVNetworkStatusReachableViaWiFi:
            break;
        case AliyunPVNetworkStatusReachableViaWWAN: {
            if ([self.localSource isFileUrl]) {
                return NO;
            }
            if (self.aliPlayer.autoPlay) {
                self.aliPlayer.autoPlay = NO;
            }
            [self pause];
            [self unlockScreen];
            [self.popLayer showPopViewWithCode:ALYPVPlayerPopCodeUseMobileNetwork popMsg:nil];
            [_loadingView dismiss];
            [self.qualityLoadingView dismiss];
            NSLog(@"播放器展示4G提醒");
            ret = YES;
        }
            break;
        default:
            break;
    }
    return ret;
}

#pragma mark - 屏幕旋转
- (void)handleDeviceOrientationDidChange:(UIInterfaceOrientation)interfaceOrientation {
    UIDevice *device = [UIDevice currentDevice] ;
    if (self.isScreenLocked) {
        return;
    }
    
    switch (device.orientation) {
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown:
        case UIDeviceOrientationPortraitUpsideDown:
            break;
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight: {
            // self.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            // 影响X变成全面屏的问题
            NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:@"aliyunVodPlayerFirstOpen"];
            if ([str isEqualToString:@"aliyun_saas_first_open"]) {
                [[NSUserDefaults standardUserDefaults] setValue:@"aliyun_saas_no_first_open" forKey:@"aliyunVodPlayerFirstOpen"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self addSubview:self.guideView];
            }
            
            if (self.delegate &&[self.delegate respondsToSelector:@selector(aliyunVodPlayerView:fullScreen:)]) {
                [self.delegate aliyunVodPlayerView:self fullScreen:YES];
            }
        }
            break;
        case UIDeviceOrientationPortrait: {
            if (self.saveFrame.origin.x == 0 && self.saveFrame.origin.y==0 && self.saveFrame.size.width == 0 && self.saveFrame.size.height == 0) {
                //开始时全屏展示，self.saveFrame = CGRectZero, 旋转竖屏时做以下默认处理
                CGRect tempFrame = self.frame ;
                tempFrame.size.width = self.frame.size.height;
                tempFrame.size.height = self.frame.size.height* 9/16;
                self.frame = tempFrame;
            }else {
                self.frame = self.saveFrame;
            }
            //2018-6-28 cai
            BOOL isFullScreen = YES;
            if (self.frame.size.width > self.frame.size.height) {
                isFullScreen = NO;
            }
            if (self.delegate &&[self.delegate respondsToSelector:@selector(aliyunVodPlayerView:fullScreen:)]) {
                [self.delegate aliyunVodPlayerView:self fullScreen:isFullScreen];
            }
            [self.guideView removeFromSuperview];
        }
            break;
        default:
            break;
    }
}

#pragma mark - dealloc
- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    if (_aliPlayer) {
        [self releasePlayer];
    }
}

- (void)releasePlayer {
    [_aliPlayer stop];
    [_aliPlayer destroy];
}

#pragma mark - 封面设置
- (void)setCoverUrl:(NSURL *)coverUrl {
    _coverUrl = coverUrl;
    if (_coverImageView && _coverUrl) {
        [self.coverImageView sd_setImageWithURL:coverUrl placeholderImage:nil options:0 progress:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            self.coverImageView.hidden = NO;
        }];
    }
}

#pragma mark - 自动播放
- (void)setAutoPlay:(BOOL)autoPlay {
    [self.aliPlayer setAutoPlay:autoPlay];
}

#pragma mark - 循环播放
- (void)setCirclePlay:(BOOL)circlePlay {
    self.aliPlayer.loop = circlePlay;
}

- (BOOL)circlePlay {
    return self.aliPlayer.loop;
}

#pragma mark - 设置绝对竖屏
- (void)setFixedPortrait:(BOOL)fixedPortrait {
    _fixedPortrait = fixedPortrait;
    if(fixedPortrait){
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    }else{
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDeviceOrientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil
         ];
    }
}

#pragma mark - 打印日志
- (void)setPrintLog:(BOOL)printLog {
    if (self.playerViewLog) {
        self.playerViewLog.isPrintLog = printLog;
    }
}

/****************推荐播放方式*******************/
- (void)playDataSourcePropertySetEmpty {
    //保证仅存其中一种播放参数
    self.localSource = nil;
    self.playAuthModel = nil;
    self.stsModel = nil;
    self.mpsModel = nil;
}

#pragma mark - 播放器开始播放入口
- (void)playViewPrepareWithURL:(NSURL *)url {
    
    void(^startPlayVideo)(void) = ^{
        [self playDataSourcePropertySetEmpty];
        self.localSource = [[AliyunLocalSource alloc] init];
        self.localSource.url = url;
        
        self.playMethod = ALYPVPlayMethodUrl;
        self.controlView.playMethod = ALYPVPlayMethodUrl;
        
        if ([self networkChangedToShowPopView]) {
            return;
        }
        
        self.urlSource = [[AVPUrlSource alloc]urlWithString:url.absoluteString];
        [self.aliPlayer setUrlSource:self.urlSource];
        self.localSource.url =nil;
        
        AVPConfig *config = [self.aliPlayer getConfig];
        if (url.absoluteString.length > 4 && [[url.absoluteString substringToIndex:4] isEqualToString:@"artp"]) {
            config.maxDelayTime = 100;
        }else {
            config.maxDelayTime = 5000;
        }
        [self.aliPlayer setConfig:config];
        
        [_loadingView show];
        [self.aliPlayer prepare];
       
        NSLog(@"播放器prepareWithURL");
    };
      [self addAdditionalSettingWithBlock:startPlayVideo];
}

- (void)playViewPrepareWithLocalURL:(NSURL *)url {
    void(^startPlayVideo)(void) = ^{
        [self playDataSourcePropertySetEmpty];
        self.localSource = [[AliyunLocalSource alloc] init];
        self.localSource.url = url;
        
        self.playMethod = ALYPVPlayMethodUrl; //本界面本地url播放和url播放统一处理
        self.controlView.playMethod = ALYPVPlayMethodLocal;
        [_loadingView show];
        self.urlSource = [[AVPUrlSource alloc]init];
        self.urlSource.playerUrl = url;
        [self.aliPlayer setUrlSource:self.urlSource];
        [self.aliPlayer prepare];
    };
     [self addAdditionalSettingWithBlock:startPlayVideo];
}

#pragma mark - vid+playauth
- (void)playViewPrepareWithVid:(NSString *)vid playAuth : (NSString *)playAuth {
    
    void(^startPlayVideo)(void) = ^{
        [self playDataSourcePropertySetEmpty];
        self.playAuthModel = [[AliyunPlayAuthModel alloc] init];
        self.playAuthModel.videoId = vid;
        self.playAuthModel.playAuth = playAuth;
        
        self.playMethod = ALYPVPlayMethodPlayAuth;
        self.controlView.playMethod = ALYPVPlayMethodPlayAuth;
        if ([self networkChangedToShowPopView]) {
            return;
        }
        
        [_loadingView show];
        _authSource = [[AVPVidAuthSource alloc]initWithVid:vid playAuth:playAuth region:@""];
        [self.aliPlayer setAuthSource:_authSource];
        [self.aliPlayer prepare];
    
        NSLog(@"播放器playAuth"); };
    [self addAdditionalSettingWithBlock:startPlayVideo];
}

- (void)addAdditionalSettingWithBlock:(void(^)(void))startPlayVideo {
    AVPConfig *config = [self.aliPlayer getConfig];
    config.enableSEI = YES;
    [self.aliPlayer setConfig:config];
    [self.controlView setButtonEnnable:YES];
    
    // 初始化进度条,把上一条播放视频的进度条 设置为0
    [self.controlView updateProgressWithCurrentTime:0 durationTime:self.aliPlayer.duration];
    startPlayVideo();
    [self start];
}

//找到当前view的Controller
- (UIViewController *)findSuperViewController:(UIView *)view {
    UIResponder *responder = view;
    // 循环获取下一个响应者,直到响应者是一个UIViewController类的一个对象为止,然后返回该对象.
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

#pragma mark - 临时ak
- (void)playViewPrepareWithVid:(NSString *)vid
                   accessKeyId:(NSString *)accessKeyId
               accessKeySecret:(NSString *)accessKeySecret
                 securityToken:(NSString *)securityToken {
    
    void(^startPlayVideo)(void) = ^{
        [self playDataSourcePropertySetEmpty];
        self.stsModel = [[AliyunSTSModel alloc] init];
        self.stsModel.videoId = vid;
        self.stsModel.accessKeyId = accessKeyId;
        self.stsModel.accessSecret = accessKeySecret;
        self.stsModel.ststoken = securityToken;
        self.playMethod = ALYPVPlayMethodSTS;
        self.controlView.playMethod = ALYPVPlayMethodSTS;
        if ([self networkChangedToShowPopView]) {
            return;
        }
        
        [_loadingView show];
        
        _stsSource = [[AVPVidStsSource alloc]initWithVid:vid accessKeyId:accessKeyId accessKeySecret:accessKeySecret securityToken:securityToken region:@"cn-shanghai"];
        [self.aliPlayer setUrlSource:nil];
        [self.aliPlayer setStsSource:_stsSource];
        [self.aliPlayer prepare];
       
        NSLog(@"播放器securityToken");
    };
   
     [self addAdditionalSettingWithBlock:startPlayVideo];
}

#pragma mark - 媒体处理
- (void)playViewPrepareWithVid:(NSString *)vid
                     accessId : (NSString *)accessId
                 accessSecret : (NSString *)accessSecret
                     stsToken : (NSString *)stsToken
                     autoInfo : (NSString *)autoInfo
                       region : (NSString *)region
                   playDomain : (NSString *)playDomain
                mtsHlsUriToken:(NSString *)mtsHlsUriToken {
    void(^startPlayVideo)(void) = ^{
        self.playMethod = ALYPVPlayMethodMPS;
        self.controlView.playMethod = ALYPVPlayMethodMPS;
        [self playDataSourcePropertySetEmpty];
        self.mpsModel = [[AliyunMPSModel alloc] init];
        self.mpsModel.videoId = vid;
        self.mpsModel.accessKey = accessId;
        self.mpsModel.accessSecret = accessSecret;
        self.mpsModel.stsToken = stsToken;
        self.mpsModel.authInfo = autoInfo;
        self.mpsModel.region = region;
        self.mpsModel.playDomain = playDomain;
        self.mpsModel.hlsUriToken = mtsHlsUriToken;
        
        if ([self networkChangedToShowPopView]) {
            return;
        }
        
        [_loadingView show];
        
        _mpsSource = [[AVPVidMpsSource alloc]initWithVid:vid accId:accessId accSecret:accessSecret stsToken:stsToken authInfo:autoInfo region:region playDomain:playDomain mtsHlsUriToken:mtsHlsUriToken];
        [self.aliPlayer setMpsSource:_mpsSource];
        [self.aliPlayer prepare];
        [self start];
        
        NSLog(@"播放器mtsHlsUriToken");
    };
    
    [self addAdditionalSettingWithBlock:startPlayVideo];
}

/*******************************************/
#pragma mark - playManagerAction

- (void)pause {
    [self.aliPlayer pause];
    _currentPlayStatus = AVPStatusPaused; // 快速的前后台切换时，播放器状态的变化不能及时传过来
    NSLog(@"播放器pause");
}

- (void)resume {
    [self.aliPlayer start];
     _currentPlayStatus = AVPStatusStarted;
    NSLog(@"播放器resume");
}

- (void)start {
    [self.aliPlayer start];
    _currentPlayStatus = AVPStatusStarted;
}

- (void)stop {
    [self.aliPlayer stop];
    NSLog(@"播放器stop");
}

- (void)replay {
    [self start];
    NSLog(@"播放器replay");
}

- (void)reset {
    [self.aliPlayer reset];
    self.aliPlayer.playerView = self.playerView;
    NSLog(@"播放器reset");
}

- (void)destroyPlayer {
    [_reachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AliyunPVReachabilityChangedNotification object:self.aliPlayer];
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    if (_aliPlayer) {
        [_aliPlayer destroy];
        _aliPlayer = nil;
    }
    //开启休眠
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

#pragma mark - 播放器当前状态
- (AVPStatus)playerViewState {
    return _currentPlayStatus;
}

#pragma mark - 媒体信息
- (AVPMediaInfo *)getAliyunMediaInfo {
    return  [self.aliPlayer getMediaInfo];
}

#pragma mark - AVPDelegate

-(void)onPlayerEvent:(AliPlayer*)player eventType:(AVPEventType)eventType {
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(aliyunVodPlayerView:happen:)]){
        [self.delegate aliyunVodPlayerView:self happen:eventType];
    }
    
    switch (eventType) {
        case AVPEventPrepareDone: {
            self.mProgressCanUpdate = YES;
            [self.loadingView dismiss];
            self.popLayer.hidden = YES;
            AVPTrackInfo * info = [player getCurrentTrack:AVPTRACK_TYPE_SAAS_VOD];
            _currentTrackInfo = info;
            [self.controlView setBottomViewTrackInfo:info];
            
            if (self.playMethod == ALYPVPlayMethodUrl) {
                [self updateControlLayerDataWithMediaInfo:nil];
            }else{
                [self updateControlLayerDataWithMediaInfo:[player getMediaInfo]];
            }
        }
            break;
        case AVPEventFirstRenderedStart: {
            [self.loadingView dismiss];
            self.popLayer.hidden = YES;
            [self.controlView setEnableGesture:YES];
            //开启常亮状态
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            //隐藏封面
            if (self.coverImageView) {
                self.coverImageView.hidden = YES;
                NSLog(@"播放器:首帧加载完成封面隐藏");
            }
        }
            break;
        case AVPEventCompletion: {
            if (self.delegate && [self.delegate respondsToSelector:@selector(onFinishWithAliyunVodPlayerView:)]) {
                [self.delegate onFinishWithAliyunVodPlayerView:self];
            }
            [self unlockScreen];
        }
            break;
        case AVPEventLoadingStart:
            [self.loadingView show];
            break;
        case AVPEventLoadingEnd:
            [self.loadingView dismiss];
            break;
        case AVPEventSeekEnd:{
            self.mProgressCanUpdate = YES;
            [self resume];
            NSLog(@"seekDone");
        }
            break;
        case AVPEventLoopingStart:
            break;
        default:
            break;
    }
}

- (void)onError:(AliPlayer*)player errorModel:(AVPErrorModel *)errorModel {
    //取消屏幕锁定旋转状态
    [self unlockScreen];
    //关闭loading动画
    [_loadingView dismiss];
    
    //根据错误信息，展示popLayer界面
    [self showPopLayerWithErrorModel:errorModel];
    
    NSLog(@" errorCode:%lu errorMessage:%@",(unsigned long)errorModel.code,errorModel.message);
}

- (void)onCurrentPositionUpdate:(AliPlayer*)player position:(int64_t)position {
    
    NSTimeInterval currentTime = position;
    NSTimeInterval durationTime = self.aliPlayer.duration;
    self.saveCurrentTime = currentTime/1000;
    if(_mProgressCanUpdate == YES){
        if (self.keyFrameTime >0 && position < self.keyFrameTime) {
            // 屏蔽关键帧问题
            return;
        }
        [self.controlView updateProgressWithCurrentTime:currentTime durationTime:durationTime];
        self.keyFrameTime = 0;
    }
}

/**
 @brief 视频缓存位置回调
 @param player 播放器player指针
 @param position 视频当前缓存位置
 */
- (void)onBufferedPositionUpdate:(AliPlayer*)player position:(int64_t)position {
    self.controlView.loadTimeProgress = (CGFloat)position/player.duration;
}

/**
 @brief 获取track信息回调
 @param player 播放器player指针
 @param info track流信息数组
 @see AVPTrackInfo
 */
- (void)onTrackReady:(AliPlayer*)player info:(NSArray<AVPTrackInfo*>*)info {
    AVPMediaInfo* mediaInfo = [player getMediaInfo];
    if ((nil != mediaInfo.thumbnails) && (0 < [mediaInfo.thumbnails count])) {
        [player setThumbnailUrl:[mediaInfo.thumbnails objectAtIndex:0].URL];
        self.trackHasThumbnai = YES;
    }else {
        self.trackHasThumbnai = NO;
    }
}

/**
 @brief track切换完成回调
 @param player 播放器player指针
 @param info 切换后的信息 参考AVPTrackInfo
 @see AVPTrackInfo
 */
- (void)onTrackChanged:(AliPlayer*)player info:(AVPTrackInfo*)info {
    //选中切换
    NSLog(@"%@",info.trackDefinition);
    [self.controlView setBottomViewTrackInfo:info];
    NSString *showString = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"已为你切换至", nil),NSLocalizedString(info.trackDefinition, nil) ];
    [MBProgressHUD showMessage:showString inView:self];
}

/**
 @brief 字幕显示回调
 @param player 播放器player指针
 @param index 字幕显示的索引号
 @param subtitle 字幕显示的字符串
 */
- (void)onSubtitleShow:(AliPlayer*)player index:(int)index subtitle:(NSString *)subtitle {}

/**
 @brief 字幕隐藏回调
 @param player 播放器player指针
 @param index 字幕显示的索引号
 */
- (void)onSubtitleHide:(AliPlayer*)player index:(int)index {}

/**
 @brief 播放器状态改变回调
 @param player 播放器player指针
 @param oldStatus 老的播放器状态 参考AVPStatus
 @param newStatus 新的播放器状态 参考AVPStatus
 @see AVPStatus
 */
- (void)onPlayerStatusChanged:(AliPlayer*)player oldStatus:(AVPStatus)oldStatus newStatus:(AVPStatus)newStatus {
    
    _currentPlayStatus = newStatus;
    NSString *playStatusString = @"other";
    if (newStatus == AVPStatusPaused) {
        playStatusString = NSLocalizedString(@"暂停", nil);
    }
    if (newStatus == AVPStatusStarted) {
        playStatusString = NSLocalizedString(@"播放", nil);
    }
    NSLog(@"播放器状态更新：%@",playStatusString);
    //更新UI状态
    [self.controlView updateViewWithPlayerState:_currentPlayStatus isScreenLocked:self.isScreenLocked fixedPortrait:self.isProtrait];
}

- (void)onCaptureScreen:(AliPlayer*)player image:(AVPImage*)image {}

- (void)onGetThumbnailSuc:(int64_t)positionMs fromPos:(int64_t)fromPos toPos:(int64_t)toPos image:(id)image {
    if (self.progressIsTouchDown) {
        self.thumbnailView.time = positionMs;
        self.thumbnailView.thumbnailImage = (UIImage *)image;
        self.thumbnailView.hidden = NO;
    }
}

- (void)onSEIData:(AliPlayer*)player type:(int)type data:(NSString *)data {
    NSLog(@"SEI:type:%d data:%@",type,data);
}

- (void)onGetThumbnailFailed:(int64_t)positionMs {
    NSLog(@"获取缩略图失败");
}

#pragma mark - popdelegate
- (void)showPopViewWithType:(ALYPVErrorType)type {
    self.popLayer.hidden = YES;
    switch (type) {
        case ALYPVErrorTypeReplay: {
            //重播
            [self.aliPlayer seekToTime:self.saveCurrentTime*1000 seekMode:self.seekMode];
            [self start];
        }
            break;
        case ALYPVErrorTypeRetry: {
            [self retry];
        }
            break;
        case ALYPVErrorTypePause: {
            [self updatePlayDataReplayWithPlayMethod:self.playMethod];
        }
            break;
        case ALYPVErrorTypeStsExpired: {
            if ([self.delegate respondsToSelector:@selector(onSecurityTokenExpiredWithAliyunVodPlayerView:)]) {
                [self.delegate onSecurityTokenExpiredWithAliyunVodPlayerView:self];
            }
        }
            break;
        default:
            break;
    }
}

- (void)retry {
    [self stop];
    
    //重试播放
    if ([self networkChangedToShowPopView]) {
        return;
    }
    [self.aliPlayer prepare];
    [self start];
}

/*
 * 功能 ：播放器
 * 参数 ：playMethod 播放方式
 */
- (void)updatePlayDataReplayWithPlayMethod:(ALYPVPlayMethod) playMethod {
    
    if (self.playerViewState ==AVPStatusPaused) {
        [self resume];
        return;
    }
    
    _urlSource = [[AVPUrlSource alloc]init];
    _urlSource.playerUrl = self.localSource.url;
    
    _stsSource = [[AVPVidStsSource alloc]initWithVid:self.stsModel.videoId accessKeyId:self.stsModel.accessKeyId accessKeySecret:self.stsModel.accessSecret securityToken:self.stsModel.ststoken region:@""];
    _mpsSource = [[AVPVidMpsSource alloc]initWithVid:self.mpsModel.videoId accId:self.mpsModel.accessKey accSecret:self.mpsModel.accessSecret stsToken:self.mpsModel.stsToken authInfo:self.mpsModel.stsToken region:self.mpsModel.region playDomain:self.mpsModel.playDomain mtsHlsUriToken:self.mpsModel.hlsUriToken];
    
    _authSource = [[AVPVidAuthSource alloc]initWithVid:self.playAuthModel.videoId playAuth:self.playAuthModel.playAuth region:@""];
    
    switch (playMethod) {
        case ALYPVPlayMethodUrl: {
            [self.aliPlayer setUrlSource:_urlSource];
        }
            break;
        case ALYPVPlayMethodMPS: {
            [self.aliPlayer setMpsSource:_mpsSource];
        }
            break;
        case ALYPVPlayMethodPlayAuth: {
            [self.aliPlayer setAuthSource:_authSource];
        }
            break;
        case ALYPVPlayMethodSTS: {
            [self.aliPlayer setStsSource:_stsSource];
        }
            break;
        default:
            break;
    }
    [self.aliPlayer prepare];
    [self start];
}

- (void)onBackClickedWithAlPVPopLayer:(AliyunPlayerViewPopLayer *)popLayer {
    if(self.delegate && [self.delegate respondsToSelector:@selector(onBackViewClickWithAliyunVodPlayerView:)]){
        [self.delegate onBackViewClickWithAliyunVodPlayerView:self];
    }else{
        [self stop];
    }
}

#pragma mark - 暂不开放该接口
- (void)setTitle:(NSString *)title {
    self.currentMediaTitle = title;
}

#pragma mark - loading动画
- (void)loadAnimation {
    CATransition *animation = [CATransition animation];
    animation.type = kCATransitionFade;
    animation.duration = 0.5;
    [self.layer addAnimation:animation forKey:nil];
}

//取消屏幕锁定旋转状态
- (void)unlockScreen{
    //弹出错误窗口时 取消锁屏。
    if (self.delegate &&[self.delegate respondsToSelector:@selector(aliyunVodPlayerView:lockScreen:)]) {
        if (self.isScreenLocked == YES||self.fixedPortrait) {
            [self.delegate aliyunVodPlayerView:self lockScreen:NO];
            //弹出错误窗口时 取消锁屏。
            [self.controlView cancelLockScreenWithIsScreenLocked:self.isScreenLocked fixedPortrait:self.fixedPortrait];
            self.isScreenLocked = NO;
        }
    }
}

/**
 * 功能：声音调节,调用系统MPVolumeView类实现，并非视频声音;volume(0~1.0)
 */
- (void)setVolume:(float)volume {
    [self.aliPlayer setVolume:volume];
}

- (BOOL)getPopLayerIsHidden {
    return self.popLayer.hidden;
}

#pragma mark - 设置提示语
- (void)setPlayFinishDescribe:(NSString *)des {
    [AliyunUtil setPlayFinishTips:des];
}

- (void)setNetTimeOutDescribe:(NSString *)des {
    [AliyunUtil setNetworkTimeoutTips:des];
}

- (void)setNoNetDescribe:(NSString *)des {
    [AliyunUtil setNetworkUnreachableTips:des];
}
- (void)setLoaddataErrorDescribe:(NSString *)des {
    [AliyunUtil setLoadingDataErrorTips:des];
}
- (void)setUseWanNetDescribe:(NSString *)des {
    [AliyunUtil setSwitchToMobileNetworkTips:des];
}

#pragma mark - public method

//更新封面图片
- (void)updateCoverWithCoverUrl:(NSString *)coverUrl {
    //以用户设置的为先，标题和封面,用户在控制台设置coverurl地址
    if (_coverImageView && _coverUrl) {
        [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:coverUrl]];
    }
}

//更新controlLayer界面ui数据
- (void)updateControlLayerDataWithMediaInfo:(AVPMediaInfo *)mediaInfo {
    //以用户设置的为先，标题和封面,用户在控制台设置coverurl地址
    if (!self.coverUrl && mediaInfo.coverURL && mediaInfo.coverURL.length>0) {
        [self updateCoverWithCoverUrl:mediaInfo.coverURL];
    }
    //设置数据
    self.controlView.videoInfo = mediaInfo;
    //标题, 未播放URL 做备用判定
    if (!self.currentMediaTitle) {
        if (mediaInfo.title && mediaInfo.title.length>0) {
            self.controlView.title = mediaInfo.title;
        }else if(self.localSource.url){
            NSArray *ary = [[self.localSource.url absoluteString] componentsSeparatedByString:@"/"];
            self.controlView.title = ary.lastObject;
        }
    }else{
        self.controlView.title = self.currentMediaTitle;
    }
}

//根据错误信息，展示popLayer界面
- (void)showPopLayerWithErrorModel:(AVPErrorModel *)errorModel {
    NSString *errorShowMsg = [NSString stringWithFormat:@"%@\n错误码:%d",errorModel.message,(int)errorModel.code];
    if (errorModel.code == ERROR_SERVER_POP_UNKNOWN) {
        if ([self.delegate respondsToSelector:@selector(onSecurityTokenExpiredWithAliyunVodPlayerView:)]) {
            [self.delegate onSecurityTokenExpiredWithAliyunVodPlayerView:self];
        }else {
            [self.popLayer showPopViewWithCode:ALYPVPlayerPopCodeSecurityTokenExpired popMsg:errorShowMsg];
        }
    }else {
        [self.popLayer showPopViewWithCode:ALYPVPlayerPopCodeServerError popMsg:errorShowMsg];
    }
    [self unlockScreen];
}

#pragma mark - AliyunControlViewDelegate
- (void)onBackViewClickWithAliyunControlView:(AliyunPlayerViewControlView *)controlView {
    if(self.delegate && [self.delegate respondsToSelector:@selector(onBackViewClickWithAliyunVodPlayerView:)]){
         [self.delegate onBackViewClickWithAliyunVodPlayerView:self];
    } else {
        [self stop];
    }
}

- (void)onDownloadButtonClickWithAliyunControlView:(AliyunPlayerViewControlView *)controlViewP {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onDownloadButtonClickWithAliyunVodPlayerView:)]) {
        [self.delegate onDownloadButtonClickWithAliyunVodPlayerView:self];
    }
}

- (void)onClickedPlayButtonWithAliyunControlView:(AliyunPlayerViewControlView *)controlView {
    AVPStatus state = [self playerViewState];
    if (state == AVPStatusStarted){
        [self pause];
    }else if (state == AVPStatusPrepared){
        [self start];
    }else if(state == AVPStatusPaused || state == AVPStatusStopped){
        [self resume];
    }
}

- (void)onClickedfullScreenButtonWithAliyunControlView:(AliyunPlayerViewControlView *)controlView {
    if(self.fixedPortrait){
        
        controlView.lockButton.hidden = self.isProtrait;
        
        if(!self.isProtrait){
            self.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            self.isProtrait = YES;
        }else{
            self.frame = self.saveFrame;
            self.isProtrait = NO;
        }
        
        if (self.delegate &&[self.delegate respondsToSelector:@selector(aliyunVodPlayerView:fullScreen:)]) {
            [self.delegate aliyunVodPlayerView:self fullScreen:self.isProtrait];
        }
    }else{
        if(self.isScreenLocked){
            return;
        }
        [AliyunUtil setFullOrHalfScreen];
    }
    controlView.isProtrait = self.isProtrait;
    [self setNeedsLayout];
}

- (void)aliyunControlView:(AliyunPlayerViewControlView *)controlView dragProgressSliderValue:(float)progressValue event:(UIControlEvents)event {
    
    NSInteger totalTime = 0;
    totalTime = self.aliPlayer.duration;
    
    switch (event) {
        case UIControlEventTouchDown: {
            
            self.progressIsTouchDown = YES;
            [self.controlView updateCurrentTime:progressValue*totalTime durationTime:totalTime];
            _touchDownProgressValue = [self.controlView.bottomView getSliderValue] ;
        }
            break;
        case UIControlEventValueChanged: {
            self.mProgressCanUpdate = NO;
            //更新UI上的当前时间
            
            if (self.trackHasThumbnai) {
                [self.aliPlayer getThumbnail:progressValue*totalTime];
            }
            [self.controlView updateCurrentTime:progressValue*totalTime durationTime:totalTime];
        }
            break;
        case UIControlEventTouchUpInside: {
            
            self.progressIsTouchDown = NO;
            self.thumbnailView.hidden = YES;
            
            [self.aliPlayer seekToTime:progressValue*self.aliPlayer.duration seekMode:self.seekMode];
            
            NSLog(@"t播放器测试：TouchUpInside 跳转到%.1f",progressValue*self.aliPlayer.duration);
            AVPStatus state = [self playerViewState];
            if (state == AVPStatusPaused) {
                [self start];
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //在播放器回调的方法里，防止sdk异常不进行seekdone的回调，在3秒后增加处理，防止ui一直异常
                self.mProgressCanUpdate = YES;
            });
        }
            break;
        case UIControlEventTouchUpOutside:{
            
            self.progressIsTouchDown = NO;
            self.thumbnailView.hidden = YES;
            [self.aliPlayer seekToTime:progressValue*self.aliPlayer.duration seekMode:self.seekMode];
            
            NSLog(@"t播放器测试：TouchUpOutside 跳转到%.1f",progressValue*self.aliPlayer.duration);
            AVPStatus state = [self playerViewState];
            if (state == AVPStatusPaused) {
                [self start];
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //在播放器回调的方法里，防止sdk异常不进行seekdone的回调，在3秒后增加处理，防止ui一直异常
                self.mProgressCanUpdate = YES;
            });
        }
            break;
            //点击事件
        case UIControlEventTouchDownRepeat:{
            
            self.mProgressCanUpdate = NO;
            NSLog(@"UIControlEventTouchDownRepeat::%f",progressValue);
            
            [self.aliPlayer seekToTime:progressValue*self.aliPlayer.duration seekMode:self.seekMode];
            
            NSLog(@"t播放器测试：DownRepeat跳转到%.1f",progressValue*self.aliPlayer.duration);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //在播放器回调的方法里，防止sdk异常不进行seekdone的回调，在3秒后增加处理，防止ui一直异常
                self.mProgressCanUpdate = YES;
            });
        }
            break;
        default:  self.mProgressCanUpdate = YES;
            break;
    }
}

- (void)aliyunControlView:(AliyunPlayerViewControlView *)controlView qualityListViewOnItemClick:(int)index{
    //暂停状态切换清晰度

    if(_currentPlayStatus == AVPStatusPaused){
        [self start];;
    }
    //切换清晰度
     [self.aliPlayer selectTrack:index];
}

#pragma mark - controlViewDelegate
- (void)onLockButtonClickedWithAliyunControlView:(AliyunPlayerViewControlView *)controlView{
    controlView.lockButton.selected = !controlView.lockButton.isSelected;
    self.isScreenLocked =controlView.lockButton.selected;
    //锁屏判定
    [controlView lockScreenWithIsScreenLocked:self.isScreenLocked fixedPortrait:self.fixedPortrait];
    if (self.delegate &&[self.delegate respondsToSelector:@selector(aliyunVodPlayerView:lockScreen:)]) {
        BOOL lScreen = self.isScreenLocked;
        if (self.isProtrait) {
            lScreen = YES;
        }
        [self.delegate aliyunVodPlayerView:self lockScreen:lScreen];
    }
}

- (void)onSpeedViewClickedWithAliyunControlView:(AliyunPlayerViewControlView *)controlView {
    [self.moreView showSpeedViewMoveInAnimate];
}

#pragma mark AliyunViewMoreViewDelegate
- (void)aliyunViewMoreView:(AliyunViewMoreView *)moreView clickedDownloadBtn:(UIButton *)downloadBtn{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onDownloadButtonClickWithAliyunVodPlayerView:)]) {
        [self.delegate onDownloadButtonClickWithAliyunVodPlayerView:self];
    }
}

- (void)aliyunViewMoreView:(AliyunViewMoreView *)moreView clickedAirPlayBtn:(UIButton *)airPlayBtn{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onClickedAirPlayButtonWithVodPlayerView:)]) {
        [self.delegate onClickedAirPlayButtonWithVodPlayerView:self];
    }
}

- (void)aliyunViewMoreView:(AliyunViewMoreView *)moreView clickedBarrageBtn:(UIButton *)barrageBtn{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onClickedBarrageBtnWithVodPlayerView:)]) {
        [self.delegate onClickedBarrageBtnWithVodPlayerView:self];
    }
}

- (void)aliyunViewMoreView:(AliyunViewMoreView *)moreView speedChanged:(float)speedValue{}

#pragma mark - Custom

- (void)setUIStatusToReplay{
    [self.popLayer showPopViewWithCode:ALYPVPlayerPopCodeUseMobileNetwork  popMsg:NSLocalizedString(@"视频播放完成" , nil)];
}

@end





