//
//  AlivcVideoPlayerListsTableViewCell.m
//  AliyunVideoClient_Entrance
//
//  Created by 王凯 on 2018/5/18.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "AlivcVideoPlayerListsTableViewCell.h"
#import "AliyunUtil.h"
#import "AlivcVideoPlayListModel.h"
#import "SDWebImageDownloader.h"
#import "SDImageCache.h"
#import "UIImageView+WebCache.h"

@interface AlivcVideoPlayerListsTableViewCell()
@property (nonatomic, strong) UIImageView *leftImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@end

@implementation AlivcVideoPlayerListsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:self.leftImageView];
        [self.leftImageView addSubview:self.durationLabel];
        [self.contentView addSubview:self.titleLabel];
    }
    return self;
}

-  (UIImageView *)leftImageView{
    if (!_leftImageView) {
        _leftImageView = [[UIImageView alloc] init];
        _leftImageView.backgroundColor = [UIColor blackColor];
//        _leftImageView.image = [UIImage imageNamed:@"avcPromptSuccess"];
    }
    return _leftImageView;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        [_titleLabel setNumberOfLines:0];
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        UIFont* font = [UIFont systemFontOfSize:14];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = font;
//        _titleLabel.text = @"1234567890-=234567890-dfghjkl;'cvgbhjnklm;,.xtcfvgbhljn;lkm;l,;cvbnjasdfasdfasdf123456";
    }
    return _titleLabel;
}

- (UILabel *)durationLabel{
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
//        [_durationLabel setNumberOfLines:0];
        _durationLabel.lineBreakMode = NSLineBreakByWordWrapping;
        UIFont* font = [UIFont systemFontOfSize:10];
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = font;
        _durationLabel.textAlignment = NSTextAlignmentRight;
        _durationLabel.backgroundColor = [UIColor blackColor];
//        _durationLabel.hidden = YES;
    }
    return _durationLabel;
}


- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat height = self.contentView.bounds.size.height;
    
    self.leftImageView.frame = CGRectMake(15,(height - 135/2)/2, 120, 135/2);
    self.durationLabel.frame = CGRectMake(self.leftImageView.frame.size.width-34-4, self.leftImageView.frame.size.height-14-4, 34, 14);
    [self.durationLabel sizeToFit];
    self.durationLabel.center = CGPointMake(self.leftImageView.frame.size.width-4-self.durationLabel.frame.size.width/2, self.leftImageView.frame.size.height-4-self.durationLabel.frame.size.height/2);
    self.titleLabel.frame = CGRectMake(self.leftImageView.frame.origin.x+self.leftImageView.frame.size.width+10, self.leftImageView.frame.origin.y, width - (self.leftImageView.frame.origin.x+self.leftImageView.frame.size.width)-15 - 10, 135/2);
    
}


- (void)setModel:(AlivcVideoPlayListModel *)model{
    self.titleLabel.text = model.title;
    self.durationLabel.text = [AliyunUtil timeformatFromSeconds:model.duration *1000];
    
    [self.leftImageView sd_setImageWithURL:[NSURL URLWithString:model.coverURL] placeholderImage:nil options:SDWebImageAllowInvalidSSLCertificates completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (error) { NSLog(@"%@",error); }
    }];
}

- (void)downloadImage:(NSString *)imageURL {
    // 利用 SDWebImage 框架提供的功能下载图片
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:imageURL] options:SDWebImageDownloaderUseNSURLCache progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {

    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        [[SDImageCache sharedImageCache] storeImage:image forKey:imageURL toDisk:YES completion:^{
            if ([NSThread isMainThread]) {
                if ([_delegate respondsToSelector:@selector(refreshTabelViewWithCell:)]) {
                    [_delegate refreshTabelViewWithCell:self];
                }
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([_delegate respondsToSelector:@selector(refreshTabelViewWithCell:)]) {
                        [_delegate refreshTabelViewWithCell:self];
                    }
                });
            }
        }];
    }];
}


@end
