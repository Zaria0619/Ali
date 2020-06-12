//
//  AlivcVideoDataBase.m
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/6/13.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "AlivcVideoDataBase.h"
#import "AlivcLocalDatabaseManager.h"

static AlivcVideoDataBase *_DBCtl = nil;


@interface AlivcVideoDataBase()<NSCopying,NSMutableCopying>{
    FMDatabase * _db;
}

@end

@implementation AlivcVideoDataBase

+ (instancetype)shared{
    if (_DBCtl == nil) {
        
        _DBCtl = [[AlivcVideoDataBase alloc] init];
        
        [_DBCtl initDataBase];
    }
    
    return _DBCtl;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    
    if (_DBCtl == nil) {
        
        _DBCtl = [super allocWithZone:zone];
        
    }
    
    return _DBCtl;
    
}

- (id)copy{
    
    return self;
    
}

- (id)mutableCopy{
    
    return self;
    
}

- (id)copyWithZone:(NSZone *)zone{
    
    return self;
    
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    
    return self;
    
}

- (void)initDataBase{
    
    // 实例化FMDataBase对象
    _db = [AlivcLocalDatabaseManager localDatabase];
    
    BOOL openSuccess =  [_db open];
    if (!openSuccess) {
        NSAssert(true, @"Open data base failure");
        return;
    }
    
    // 初始化数据表
    NSString *videoSql = @"CREATE TABLE 'video' ('id' INTEGER PRIMARY KEY AUTOINCREMENT  NOT NULL ,'video_id' VARCHAR(255),'video_status' VARCHAR(255),'video_progress' VARCHAR(255),'video_size' VARCHAR(255),'video_title' VARCHAR(255),'video_imageUrlString' VARCHAR(255),'video_fileName' VARCHAR(255),'video_trackIndex' VARCHAR(255),'video_format' VARCHAR(255),'video_imageData' BLOB)";
 
    
    @try {
        [_db executeUpdate:videoSql];
    }
    @catch(NSException *exception) {
        [_db rollback];
    }
    @finally {
        [_db close];
    }
}

#pragma mark - Video
- (void)addVideo:(DownloadSource *)video{
    BOOL openSuccess =  [_db open];
    if (!openSuccess) {
        NSAssert(true, @"Open data base failure");
        return;
    }
    
    // sql字符串
    @try {
        FMResultSet *res = [_db executeQuery:@"SELECT * FROM video WHERE video_id = ? and video_trackIndex = ?",video.vid,video.video_trackIndex];
        
        while ([res next]) {
            return;//防止重复添加
        }
        [_db executeUpdate:@"INSERT INTO video(video_id,video_status,video_progress,video_size,video_title,video_imageUrlString,video_fileName,video_trackIndex,video_format,video_imageData)VALUES(?,?,?,?,?,?,?,?,?,?)",video.vid,video.video_status,video.video_percent,video.totalDataString,video.title,video.coverURL,video.fileName,video.video_trackIndex,video.format,video.video_imageData];
    }
    @catch(NSException *exception) {
        [_db rollback];
    }
    @finally {
        [_db close];
    }
}

- (BOOL)deleteVideo:(DownloadSource *)video{
    BOOL openSuccess =  [_db open];
    if (!openSuccess) {
        NSAssert(true, @"Open data base failure");
        return false;
    }
    
    // sql字符串
    @try {
        [_db executeUpdate:@"DELETE FROM video WHERE video_id = ? and video_trackIndex = ? and video_format = ?",video.vid,video.video_trackIndex,video.format];
    }
    @catch(NSException *exception) {
        [_db rollback];
         return false;
    }
    @finally {
        [_db close];
        return true;
    }
   
}

- (BOOL)updateVideo:(DownloadSource *)video{
    BOOL openSuccess =  [_db open];
    if (!openSuccess) {
        NSAssert(true, @"Open data base failure");
        return false;
    }
    
    // sql字符串
    @try {
        [_db executeUpdate:@"UPDATE 'video' SET video_progress = ?  WHERE video_id = ? and video_trackIndex = ? and video_format = ?",video.video_percent,video.vid,video.video_trackIndex,video.format];
    }
    @catch(NSException *exception) {
        [_db rollback];
        return false;
    }
    @finally {
        [_db close];
        return true;
    }

}

- (NSArray <DownloadSource *>*)getAllVideo{
    
    NSMutableArray *resultArray = [[NSMutableArray alloc]init];
    BOOL openSuccess =  [_db open];
    if (!openSuccess) {
        NSAssert(true, @"Open data base failure");
        return [NSArray array];
    }
    
    @try {
       FMResultSet *res = [_db executeQuery:@"SELECT * FROM video"];
        while ([res next]) {
            DownloadSource *video = [AlivcVideoDataBase videoWithResultSet:res];
            [resultArray addObject:video];
        }
        return (NSArray *)resultArray;
    }
    @catch(NSException *exception) {
        [_db rollback];
    }
    @finally {
        [_db close];
    }
    return [NSArray array];
}

+ (DownloadSource *)videoWithResultSet:(FMResultSet *)res{
    DownloadSource *video = [[DownloadSource alloc]init];
    video.vid = [res stringForColumn:@"video_id"];
    video.video_status = @([[res stringForColumn:@"video_status"]integerValue]);
    video.video_percent  = @([[res stringForColumn:@"video_progress"]integerValue]);
    video.videoSize = @([[res stringForColumn:@"video_size"] integerValue]);
    video.title = [res stringForColumn:@"video_title"];
    video.coverURL = [res stringForColumn:@"video_imageUrlString"];
    video.fileName = [res stringForColumn:@"video_fileName"];
    video.video_trackIndex = @([[res stringForColumn:@"video_trackIndex"] integerValue]);
    video.format = [res stringForColumn:@"video_format"];
    video.video_imageData = [res dataForColumn:@"video_imageData"];
    return video;
}
@end
