//
//  AVCVideoDownloadTCell.m
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/4/11.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "AVCVideoDownloadTCell.h"
#import "AlivcUIConfig.h"
#import "UIImageView+WebCache.h"
@interface AVCVideoDownloadTCell()


@property (weak, nonatomic) IBOutlet UIView *maskView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *besideToLeftConstraint;
@property (weak, nonatomic) IBOutlet UIButton *edutButton;

@property (weak, nonatomic) IBOutlet UIButton *actionButton;

@property (strong, nonatomic) DownloadSource *video;
@end

@implementation AVCVideoDownloadTCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.coverImageView.layer.cornerRadius = 5;
    self.coverImageView.clipsToBounds = true;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configWithSource:(DownloadSource *)downloadSource{
    self.video = downloadSource;
    self.edutButton.selected = self.customSelected;
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.titleLabel.text = downloadSource.title;
    if (downloadSource.coverURL) {
        [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:downloadSource.coverURL]];
    }
//    else if(downloadVideo.coverImageurlString){
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            NSURL *url = [NSURL URLWithString:downloadVideo.coverImageurlString];
//            if (url) {
//                NSData *imageData = [NSData dataWithContentsOfURL:url];
//                if (imageData) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        downloadVideo.video_imageData = imageData;
//                        self.coverImageView.image = [UIImage imageWithData:imageData];
//                    });
//                }
//            }
//        });
//    }
    if (downloadSource.downloadStatus == DownloadTypefinish) {
        self.statusImageView.hidden = true;
        self.downLoadProgressView.hidden = true;
        self.statusLabel.textColor = [UIColor whiteColor];
       
#warning 这里添加数据库修改
        
        if (downloadSource.totalDataString) {
            self.statusLabel.text = downloadSource.totalDataString;
        }
        self.totalDataLabel.hidden = true;
        self.actionButton.hidden = true;
    }else{
        self.statusImageView.hidden = false;
        self.downLoadProgressView.hidden = false;
        self.statusLabel.textColor = [AlivcUIConfig shared].kAVCThemeColor;
        
        #warning 这里添加数据修改
        if (downloadSource.statusString) {
            self.statusLabel.text = downloadSource.statusString;
        }
        self.actionButton.hidden = false;
        self.statusImageView.image = downloadSource.statusImage;
        self.totalDataLabel.hidden = false;
        self.totalDataLabel.text = downloadSource.totalDataString;
    }
    
    
    //progress
    [self.downLoadProgressView setProgressTintColor:[AlivcUIConfig shared].kAVCThemeColor];
    [self.downLoadProgressView setProgress:downloadSource.percent /100.0];
    if (downloadSource.downloadStatus == DownloadTypeLoading) {
        [self.maskView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
        self.maskView.hidden = false;
    }else{
        self.maskView.hidden = true;
    }
    
}

- (void)refreshProgress:(CGFloat)progress{
    [self.downLoadProgressView setProgress:progress];
}

- (IBAction)editButtonTouched:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    self.customSelected = sender.selected;
    if ([self.delegate respondsToSelector:@selector(videoDownTCell:video:selected:)]) {
        [self.delegate videoDownTCell:self video:self.video selected:self.customSelected];
    }
    
}

- (void)setTOEditStyle:(BOOL)isEdit{
     self.edutButton.hidden = !isEdit;
    if (isEdit) {
        self.besideToLeftConstraint.constant = self.edutButton.frame.size.width;
    }else{
        self.besideToLeftConstraint.constant = 0;
    }
}

- (void)setSelectedCustom:(BOOL)selected{
    self.customSelected = selected;
    self.edutButton.selected = selected;
}
- (IBAction)actionButtonTouched:(id)sender {
    if ([self.delegate respondsToSelector:@selector(videoDownTCell:actionButtonTouchedWithVideo:)]) {
        [self.delegate videoDownTCell:self actionButtonTouchedWithVideo:self.video];
    }
}

@end
