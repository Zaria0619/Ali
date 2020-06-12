//
//  AVC_VP_VideoPlayViewController.h
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/4/11.
//  Copyright © 2018年 Alibaba. All rights reserved.
//  播放界面

#import "AVC_VP_BaseViewController.h"

@class AVCVideoConfig;

@interface AVC_VP_VideoPlayViewController : AVC_VP_BaseViewController

/**
 播放视频的配置
 */
@property (nonatomic, strong) AVCVideoConfig *config;

/**
 视频配置已经更新
 */
- (void)configChanged;

@end
