//
//  AVC_VP_PlaySettingVC.m
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/4/8.
//  Copyright © 2018年 Alibaba. All rights reserved.
//  

#import "AVC_VP_PlaySettingVC.h"
#import "AlivcScanViewController.h"
#import "AVC_VP_VideoPlayViewController.h"
#import "AVCVideoConfig.h"
#import "MBProgressHUD+AlivcHelper.h"
#import "AlivcAppServer.h"
#import "UIImage+AlivcHelper.h"
#import "AVC_VP_VideoPlayViewController.h"

NS_ASSUME_NONNULL_BEGIN


static NSString *defaultUrlString = @"http://player.alicdn.com/video/aliyunmedia.mp4";
static NSString *defaultVidString = @"09cf8b916ecc4613aa4a0044f70a06fd";

/**
 界面状态

 - AVC_VP_PlaySettingVC_PageStateVid: vid状态
 - AVC_VP_PlaySettingVC_PageStateURL: URL状态
 */
typedef NS_ENUM(NSInteger,AVC_VP_PlaySettingVC_PageState){
    AVC_VP_PlaySettingVC_PageStateVid = 0,
    AVC_VP_PlaySettingVC_PageStateURL = 1,
};



@interface AVC_VP_PlaySettingVC ()<UITextFieldDelegate,UITextViewDelegate,AlivcScanViewControllerDelegate>

/**
 选中的蓝色条
 */
@property (weak, nonatomic) IBOutlet UILabel *selectLabel;
@property (weak, nonatomic) IBOutlet UIButton *button_vidPlay;
@property (weak, nonatomic) IBOutlet UIButton *button_URLPlay;
@property (weak, nonatomic) IBOutlet UIButton *button_startPlay;

/**
 展示的vid相关设置的容器视图
 */
@property (weak, nonatomic) IBOutlet UIView *vidShowView;

/**
 展示的URL播放相关设置的容器视图
 */
@property (weak, nonatomic) IBOutlet UIView *URLShowView;

//vid
@property (weak, nonatomic) IBOutlet UILabel *label_vid;
@property (weak, nonatomic) IBOutlet UITextField *textField_vid;

//AccessKeyID
@property (weak, nonatomic) IBOutlet UILabel *label_AccessKeyID;
@property (weak, nonatomic) IBOutlet UITextField *textField_AccessKeyID;

//AccessKeySecret
@property (weak, nonatomic) IBOutlet UILabel *label_AccessKeySecret;
@property (weak, nonatomic) IBOutlet UITextField *textField_AccessKeySecret;

//SecurityToken
@property (weak, nonatomic) IBOutlet UILabel *label_SecurityToken;
@property (weak, nonatomic) IBOutlet UITextView *textView_SecurityToken;

//URL
@property (weak, nonatomic) IBOutlet UILabel *label_URL;
@property (weak, nonatomic) IBOutlet UITextField *textField_URL;
@property (weak, nonatomic) IBOutlet UIButton *buttton_Scan;

//界面状态
@property (assign, nonatomic) AVC_VP_PlaySettingVC_PageState pageState;

/**
 扫描结果
 */
@property (strong, nonatomic, nullable) NSString *scanResult;

@property (weak, nonatomic) IBOutlet UIButton *vidPlayButton;
@property (weak, nonatomic) IBOutlet UIButton *URLPlayButton;
@property (weak, nonatomic) IBOutlet UIButton *startPlayButton;



@end

@implementation AVC_VP_PlaySettingVC

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self configBaseUI];
    
    [self configBaseData];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"ShowPresentView" object:@"1"];
    if (self.enterViewBlock) {
        self.enterViewBlock();
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
     [[NSNotificationCenter defaultCenter]postNotificationName:@"ShowPresentView" object:@"0"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Base Config

- (void)configBaseUI{
    self.navigationController.navigationBar.hidden = false;
    [self setBaseNavigationBar];
    self.navigationItem.title = [@"播放设置" localString];
    
    [self.vidPlayButton setTitle:[@"VID 播放" localString] forState:UIControlStateNormal];
    [self.URLPlayButton setTitle:[@"URL 播放" localString] forState:UIControlStateNormal];
    [self.startPlayButton setTitle:[@"开启播放界面" localString] forState:UIControlStateNormal];
    
    //textField设置
    [self configTextField:self.textField_vid];
    
    [self configTextField:self.textField_AccessKeyID];
    [self configTextField:self.textField_AccessKeySecret];
    [self configTextField:self.textField_URL];
    
    UIColor *placeholderColor = [UIColor colorWithHexString:@"9b9ea0"];
    [self setPlaceholderString:[@"请输入URL" localString] textField:self.textField_URL color:placeholderColor];
    
    //textView
    self.textView_SecurityToken.textColor = [UIColor whiteColor];
    self.textView_SecurityToken.backgroundColor = [UIColor clearColor];
    self.textView_SecurityToken.delegate = self;
    //默认vid
    self.pageState = AVC_VP_PlaySettingVC_PageStateVid;
    //设置默认值
    self.textField_URL.text = defaultUrlString;
    self.textField_vid.text = defaultVidString;
}


/**
 适配基本的数据
 */
- (void)configBaseData{

    [AlivcAppServer getStsDataSucess:^(NSString *accessKeyId, NSString *accessKeySecret, NSString *securityToken) {
        self.textField_AccessKeyID.text = accessKeyId;
        self.textField_AccessKeySecret.text = accessKeySecret;
        self.textView_SecurityToken.text = securityToken;
    } failure:^(NSString * errorString) {
        [MBProgressHUD showMessage:errorString inView:self.view];
    }];
    
}

- (void)setBaseNavigationBar{
    //
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage avc_imageWithColor:[AlivcUIConfig shared].kAVCBackgroundColor] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

- (void)returnAction{
    [self dismissViewControllerAnimated:true completion:^{
        //
        if (self.backBlock) {
            self.backBlock();
        }
        
    }];
}

/**
 配置textField

 @param textField tf
 */
- (void)configTextField:(UITextField *)textField{
    textField.textColor = [UIColor whiteColor];
    textField.backgroundColor = [UIColor clearColor];
    textField.delegate = self;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
}


/**
 配置textField的placeholder

 @param placeholderString 提示字符
 @param textField 输入框
 @param color 提示字符的颜色
 */
- (void)setPlaceholderString:(NSString *)placeholderString textField:(UITextField *)textField color:(UIColor *)color{
    NSMutableAttributedString *placeholder = [[NSMutableAttributedString alloc] initWithString:placeholderString];
    [placeholder addAttribute:NSForegroundColorAttributeName
                        value:color
                        range:NSMakeRange(0, placeholderString.length)];
    [placeholder addAttribute:NSFontAttributeName
                        value:[UIFont boldSystemFontOfSize:14]
                        range:NSMakeRange(0, placeholderString.length)];
    textField.attributedPlaceholder = placeholder;
}

#pragma mark - Custom Method

/**
 刷新界面状态

 @param state 界面状态
 */
- (void)refreshUIWithPageState:(AVC_VP_PlaySettingVC_PageState )state{
    CGFloat targetCx = 0;
    if (state == AVC_VP_PlaySettingVC_PageStateVid) {
        targetCx = CGRectGetMidX(self.button_vidPlay.frame);
        self.vidShowView.hidden = false;
        self.URLShowView.hidden = true;
    }else{
        targetCx = CGRectGetMidX(self.button_URLPlay.frame);
        self.vidShowView.hidden = true;
        self.URLShowView.hidden = false;
    }
    //移动蓝色条
    CGFloat targetCy = CGRectGetMidY(self.selectLabel.frame);
    __block UILabel *weakLabel = self.selectLabel;
    [UIView animateWithDuration:0.6 animations:^{
        weakLabel.center = CGPointMake(targetCx, targetCy);
    }];
}


/**
 所有的键盘放弃第一响应者
 */
- (void)resignAllFirstResponder{
    [self.textField_vid resignFirstResponder];
    [self.textField_AccessKeyID resignFirstResponder];
    [self.textField_AccessKeySecret resignFirstResponder];
    [self.textView_SecurityToken resignFirstResponder];
    [self.textField_URL resignFirstResponder];
}



#pragma mark - Response

/**
 vid播放

 @param sender sender
 */
- (IBAction)vidPlayTouched:(UIButton *)sender {
    self.pageState = AVC_VP_PlaySettingVC_PageStateVid;
    [self refreshUIWithPageState:self.pageState];
    [self resignAllFirstResponder];
}

/**
 URL播放

 @param sender sender
 */
- (IBAction)URLPalyTouched:(UIButton *)sender {
    self.pageState = AVC_VP_PlaySettingVC_PageStateURL;
    [self refreshUIWithPageState:self.pageState];
    [self resignAllFirstResponder];
}

/**
 URL扫描

 @param sender sender
 */
- (IBAction)scanButtonTouched:(id)sender {
    AlivcScanViewController *targetVC = [[AlivcScanViewController alloc]init];
    targetVC.style = [AlivcScanViewController ZhiFuBaoStyle];
    targetVC.isOpenInterestRect = true;
    targetVC.libraryType = SLT_Native;
    targetVC.scanCodeType = SCT_QRCode;
    targetVC.delegate = self;
    [self.navigationController pushViewController:targetVC animated:true];
}

/**
 开启播放界面

 @param sender sender
 */
- (IBAction)startPlayTouched:(id)sender {
    switch (self.pageState) {
        case AVC_VP_PlaySettingVC_PageStateURL:
            [self handleUrlPaly];
            break;
        case AVC_VP_PlaySettingVC_PageStateVid:
            [self handleVipPlay];
            break;
        default:
            break;
    }
}


/**
 处理vip界面下的开启播放
 */
- (void)handleVipPlay{
    NSString *vid = self.textField_vid.text;
    NSString *key = self.textField_AccessKeyID.text;
    NSString *secret = self.textField_AccessKeySecret.text;
    NSString *token = self.textView_SecurityToken.text;
    if (![vid isNotEmpty]) {
        [MBProgressHUD showMessage:[NSString stringWithFormat:@"%@vid",NSLocalizedString(@"请填写", nil)] inView:self.view];
        return;
    }
    if (![key isNotEmpty]) {
        [MBProgressHUD showMessage:[NSString stringWithFormat:@"%@AccessKeyID",NSLocalizedString(@"请填写", nil)] inView:self.view];
        return;
    }
    if (![secret isNotEmpty]) {
        [MBProgressHUD showMessage:[NSString stringWithFormat:@"%@AccessKeySecret",NSLocalizedString(@"请填写", nil)] inView:self.view];
        return;
    }
    if (![token isNotEmpty]) {
        [MBProgressHUD showMessage:[NSString stringWithFormat:@"%@ecurityToken",NSLocalizedString(@"请填写", nil)] inView:self.view];
        return;
    }
    AVCVideoConfig *config = [[AVCVideoConfig alloc]init];
    config.playMethod = AliyunPlayMedthodSTS;
    config.videoId = vid;
    config.stsAccessKeyId = key;
    config.stsAccessSecret = secret;
    config.stsSecurityToken = token;
//    _originVC.config = config;
    
    if (self.setBlock) {
        self.setBlock(config);
    }
    
    [self dismissViewControllerAnimated:true completion:^{
//        [_originVC configChanged];
    }];
}

/**
 处理URL界面下的播放
 */
- (void)handleUrlPaly{
    self.scanResult = self.textField_URL.text;
    if (self.scanResult) {
        AVCVideoConfig *config = [[AVCVideoConfig alloc]init];
        config.playMethod = AliyunPlayMedthodURL;
        config.videoUrl = [NSURL URLWithString:self.scanResult];
//        _originVC.config = config;
        
        if (self.setBlock) {
            self.setBlock(config);
        }
        
        [self dismissViewControllerAnimated:true completion:^{
//            [_originVC configChanged];
        }];
    }else{
        NSLog(@"请先扫描二维码或者填写二维码");
    }
}



#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return true;
}



#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return false;
    }
    return true;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - AVC_VP_ScanDelegate
- (void)scanViewController:(id)vc scanResult:(NSString *)resultString{
    self.textField_URL.text = resultString;
}
@end

NS_ASSUME_NONNULL_END
