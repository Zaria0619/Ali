//
//  AVCSeletSharpnessView.h
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/4/18.
//  Copyright © 2018年 Alibaba. All rights reserved.
//  选择清晰度View

#import <UIKit/UIKit.h>
#import "DownloadManager.h"
#import <AliyunPlayer/AliyunPlayer.h>

///**
// 视频质量声明
//
// - AVCVideoQualityHD: 超清
// - AVCVideoQualitySD: 高清
// - AVCVideoQualityLD: 标清
// - AVCVideoQualityFD: 流畅
// */
//typedef NS_ENUM(NSInteger,AVCVideoQuality) {
//    AVCVideoQualityHD,
//    AVCVideoQualitySD,
//    AVCVideoQualityLD,
//    AVCVideoQualityFD,
//};

@class AVCSelectSharpnessView;
//@class AliyunDownloadMediaInfo;

@protocol AVCSelectSharpnessViewDelegate<NSObject>

- (void)selectSharpnessView:(AVCSelectSharpnessView *)view okButtonTouched:(UIButton *)button;

- (void)selectSharpnessView:(AVCSelectSharpnessView *)view cancelButtonTouched:(UIButton *)button;

- (void)selectSharpnessView:(AVCSelectSharpnessView *)view haveSelectedMediaInfo:(AVPTrackInfo *)medioInfo;

- (void)selectSharpnessView:(AVCSelectSharpnessView *)view lookVideoButtonTouched:(UIButton *)button;

@end

@interface AVCSelectSharpnessView : UIView

//唯一初始化方法
- (instancetype)initWithMedias:(NSArray <AVPTrackInfo*>*)mediaInfos source:(DownloadSource *)source;

@property (nonatomic, weak) id <AVCSelectSharpnessViewDelegate> delegate;

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *totalDataLabel;
@property (nonatomic,strong)DownloadSource *downloadSource;

- (void)configWithMedia:(AVPTrackInfo *)media;

- (void)setSelectedMedia:(AVPTrackInfo *)media;

- (void)showInView:(UIView *)view;

- (void)dismiss;

@end
