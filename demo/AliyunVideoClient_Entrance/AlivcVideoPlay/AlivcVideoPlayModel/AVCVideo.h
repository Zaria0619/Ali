//
//  AVCVideo.h
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/4/18.
//  Copyright © 2018年 Alibaba. All rights reserved.
//  AVCVideoConfig的组合类

#import <Foundation/Foundation.h>
#import "AVCVideoConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVCVideo : NSObject

@property (nonatomic, strong, readonly, nullable) NSString *title;

@property (nonatomic, strong) AVCVideoConfig *videoConfig;

@end
NS_ASSUME_NONNULL_END
