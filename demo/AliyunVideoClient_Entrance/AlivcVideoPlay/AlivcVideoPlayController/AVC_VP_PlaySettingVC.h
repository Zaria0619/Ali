//
//  AVC_VP_PlaySettingVC.h
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/4/8.
//  Copyright © 2018年 Alibaba. All rights reserved.
//  播放设置界面

#import "AlivcKeyboardManageViewController.h"
@class AVCVideoConfig;
typedef void (^PlaySetBlock)(AVCVideoConfig *config);

typedef void (^BackBlock)(void);

typedef void (^EnterViewBlock)(void);

@interface AVC_VP_PlaySettingVC : AlivcKeyboardManageViewController

@property (nonatomic, copy) PlaySetBlock setBlock;

@property (nonatomic, copy) BackBlock backBlock;
@property (nonatomic, copy) EnterViewBlock enterViewBlock;

@end
