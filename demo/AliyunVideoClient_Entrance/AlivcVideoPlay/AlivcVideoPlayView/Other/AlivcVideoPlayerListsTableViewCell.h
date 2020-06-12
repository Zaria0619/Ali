//
//  AlivcVideoPlayerListsTableViewCell.h
//  AliyunVideoClient_Entrance
//
//  Created by 王凯 on 2018/5/18.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AlivcVideoPlayListModel;
@class AlivcVideoPlayerListsTableViewCell;
@protocol AlivcVideoPlayerListsTableViewCellDelegate<NSObject>
- (void)refreshTabelViewWithCell:(AlivcVideoPlayerListsTableViewCell *)cell;
@end


@interface AlivcVideoPlayerListsTableViewCell : UITableViewCell
@property (nonatomic,weak) id<AlivcVideoPlayerListsTableViewCellDelegate>delegate;
- (void)setModel:(AlivcVideoPlayListModel *)model;


@end
