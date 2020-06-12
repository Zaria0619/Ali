//
//  AlivcPlayListsView.h
//  AliyunVideoClient_Entrance
//
//  Created by 王凯 on 2018/5/18.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AliyunPrivateDefine.h"

@class AlivcPlayListsView;
@class AlivcVideoPlayListModel;
@protocol AlivcPlayListsViewDelegate <NSObject>

//选中的播放model
- (void)alivcPlayListsView:(AlivcPlayListsView *)playListsView didSelectModel:(AlivcVideoPlayListModel *)listModel;

- (void)alivcPlayListsView:(AlivcPlayListsView *)playListsView playSettingButtonTouched:(UIButton *)buton;

@end

@interface AlivcPlayListsView : UIView
@property(nonatomic, weak) id<AlivcPlayListsViewDelegate>delegate;
@property (nonatomic, copy) NSArray<AlivcVideoPlayListModel*> *dataAry;

//@property (nonatomic, assign) AliyunOlympicPlayStyle playStyle;

- (void)playNextMediaVideo;

- (void)refreshLoad;

@end
