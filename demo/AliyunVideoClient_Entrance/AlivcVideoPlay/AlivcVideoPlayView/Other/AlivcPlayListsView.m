//
//  AlivcPlayListsView.m
//  AliyunVideoClient_Entrance
//
//  Created by 王凯 on 2018/5/18.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "AlivcPlayListsView.h"
#import "AlivcVideoPlayerListsTableViewCell.h"
#import "UIColor+AlivcHelper.h"
#import "AlivcVideoPlayManager.h"

#import "SDWebImageDownloader.h"
#import "SDImageCache.h"
#import "AlivcVideoPlayListModel.h"
#import "AliyunUtil.h"

static CGFloat buttonHeight = 50;

@interface AlivcPlayListsView ()<UITableViewDelegate,UITableViewDataSource,AlivcVideoPlayerListsTableViewCellDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL isChangedRow;

@property (nonatomic, strong) UIButton *playSettingButton;
@property (nonatomic, assign) NSInteger tempIndexPathRow;
@end

@implementation AlivcPlayListsView

-(UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        UIView *footview = [[UIView alloc] initWithFrame:CGRectZero];
        _tableView.backgroundColor = [UIColor colorWithHexString:@"1e222d"];
        _tableView.tableFooterView = footview;
    }
    return  _tableView;
}

- (UIButton *)playSettingButton{
    if (!_playSettingButton) {
        _playSettingButton = [[UIButton alloc]init];
        [_playSettingButton addTarget:self action:@selector(playSetting:) forControlEvents:UIControlEventTouchUpInside];
        [_playSettingButton setTitle:NSLocalizedString(@"vid或URL播放" , nil) forState:UIControlStateNormal];
        _playSettingButton.backgroundColor = [UIColor colorWithHexString:@"373d41"];
    }
    return _playSettingButton;
}


- (instancetype)init{
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.isChangedRow = NO;
        [self addSubview:self.tableView];
        self.tempIndexPathRow = 0;
        //底部vid
        [self addSubview:self.playSettingButton];
    }
    return self;
}

- (void)refreshLoad{
    [AlivcVideoPlayManager requestPlayListWithSucess:^(NSArray *ary, long total) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataAry = ary;
            [self.tableView reloadData];
        });
    } failure:^(NSString *failString) {
        
    }];
}

- (void)setDataAry:(NSArray<AlivcVideoPlayListModel *> *)dataAry{
    _dataAry = dataAry;
    if (dataAry.count > 0) {
        [self.tableView reloadData];
    }
}


- (void)layoutSubviews{
    CGRect frame = self.bounds;
    frame.size.height = frame.size.height - buttonHeight;
    self.tableView.frame = frame;
    
    self.playSettingButton.frame = CGRectMake(0, frame.size.height, frame.size.width, buttonHeight);
}


#pragma mark - tableDelegate/datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  self.dataAry.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        if ([cell respondsToSelector:@selector(setSeparatorInset:)])
        {
            [cell setSeparatorInset:UIEdgeInsetsZero];
        }
        if ([cell respondsToSelector:@selector(setLayoutMargins:)])
        {
            [cell setLayoutMargins:UIEdgeInsetsZero];
        }
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *cellIdentifier = @"democell";
    AlivcVideoPlayerListsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];\
    if (!cell) {
        cell = [[AlivcVideoPlayerListsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    AlivcVideoPlayListModel *model = self.dataAry[indexPath.row];
    cell.delegate = self;
    [cell setModel:model];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
    [tableView  setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    cell.backgroundColor = [UIColor colorWithHexString:@"1e222d"];
   
    return cell;
   
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 85.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
//    return 44.0f;
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    if (section == 0) {
//        UIView *headerView = [[UIView alloc]init];
//        headerView.backgroundColor = [UIColor colorWithHexString:@"1e222d"];
//        UILabel *label = [[UILabel alloc]init];
//        label.textColor = [UIColor whiteColor];
//        label.font = [UIFont systemFontOfSize:14];
//        label.frame = CGRectMake(15, 0, tableView.frame.size.width, 44);
//        label.textAlignment = NSTextAlignmentLeft;
//        label.text = @"PlayList";
//        [headerView addSubview:label];
//        return headerView;
//    }
    return nil;
    
}


- (void)repeatDelay{
    self.isChangedRow = false;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    
    if (self.isChangedRow == false) {
        self.isChangedRow = true;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(repeatDelay) object:nil];
        [self performSelector:@selector(repeatDelay) withObject:nil afterDelay:0.5];
        // 在下面实现点击cell需要实现的逻辑就可以了
        self.tempIndexPathRow = indexPath.row;
        if (_delegate && [_delegate respondsToSelector:@selector(alivcPlayListsView:didSelectModel:)]) {
            AlivcVideoPlayListModel *model = self.dataAry[indexPath.row];
            [_delegate alivcPlayListsView:self didSelectModel:model];
        }
        
    }else{
        return;
    }
}

- (void)playSetting:(UIButton *)button{
    if ([self.delegate respondsToSelector:@selector(alivcPlayListsView:playSettingButtonTouched:)]) {
        [self.delegate alivcPlayListsView:self playSettingButtonTouched:button];
    }
}

#pragma mark - AlivcVideoPlayerListsTableViewCellDelegate
- (void)refreshTabelViewWithCell:(AlivcVideoPlayerListsTableViewCell *)cell{

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) {
        return;
    }
    NSArray <NSIndexPath *> *indexPathArray = @[indexPath];
    [self.tableView reloadRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationNone];
}



#pragma mark - publicMethod
- (void)playNextMediaVideo{
    if (self.dataAry && self.dataAry.count > 0) {
        if (self.dataAry.count == 0) {
            //播放当前
            NSLog(@"1");
        }else{
            self.tempIndexPathRow ++;
            if (self.tempIndexPathRow>self.dataAry.count-1) {
                self.tempIndexPathRow = 0;
            }
            [self.tableView reloadData];
            NSIndexPath * indexPath = [NSIndexPath indexPathForRow:self.tempIndexPathRow inSection:0];
            
//            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
