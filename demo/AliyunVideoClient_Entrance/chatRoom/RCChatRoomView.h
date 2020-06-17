//
//  RCChatRoomView.h
//  NiuLiving
//
//  Created by liyan on 2020/4/8.
//  Copyright © 2020 PILI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCCRGiftListView.h"
#import "RCCRLiveModel.h"
#import "RCCRInputBarControl.h"
#import "RCCRGiftNumberLabel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCChatRoomView : UIView 

/*!
 消息列表CollectionView和输入框都在这个view里
 */
@property(nonatomic, strong) UIView *messageContentView;

/*!
 会话页面的CollectionView
 */
@property(nonatomic, strong) UICollectionView *conversationMessageCollectionView;

/**
 输入工具栏
 */
@property(nonatomic,strong) RCCRInputBarControl *inputBar;



/**
 底部按钮容器，底部的四个按钮都添加在此view上
 */
@property(nonatomic, strong) UIView *bottomBtnContentView;

/**
 *  评论按钮
 */
@property(nonatomic,strong)UIButton *commentBtn;

/**
 *  弹幕消息按钮
 */
@property(nonatomic,strong)UIButton *danmakuBtn;

/**
 *  礼物按钮
 */
@property(nonatomic,strong)UIButton *giftBtn;

/**
 礼物列表
 */
@property(nonatomic,strong) RCCRGiftListView *giftListView;

/**
 *  赞按钮
 */
@property(nonatomic,strong)UIButton *praiseBtn;

/**
 处理礼物消息
 */
@property(nonatomic, assign) BOOL forbidGiftAinimation;

/**
 展示礼物动画数字的label
 */
@property(nonatomic,strong) RCCRGiftNumberLabel *giftNumberLbl;

/**
 展示礼物动画的界面
 */
@property(nonatomic,strong) UIView *showGiftView;

/**
 上次点赞按钮点击时间
 */
@property(nonatomic, assign) NSTimeInterval lastClickPraiseTime;

/**
 数据模型
 */
@property(nonatomic, strong) RCCRLiveModel *model;

- (void)sendMessage:(RCMessageContent *)messageContent
        pushContent:(NSString *)pushContent
            success:(void (^)(long messageId))successBlock
              error:(void (^)(RCErrorCode nErrorCode, long messageId))errorBlock;

- (void)alertErrorWithTitle:(NSString *)title message:(NSString *)message ok:(NSString *)ok;

- (instancetype)initWithFrame:(CGRect)frame model:(RCCRLiveModel *)model;

- (void)setDefaultBottomViewStatus;

@end

NS_ASSUME_NONNULL_END
