//
//  SDKVersionManager.m
//  AliyunVideoClient_Entrance
//
//  Created by 舒毅文 on 2018/11/6.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "SDKVersionManager.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation SDKVersionManager

+ (void)printAllSDKVersion {

    NSArray *sdkArr = @[@[@"AliRTCSdk.framework", @"AliRtcEngine", @"getSdkVersion", @"+", @"1.1.0"],
                        @[@"AliyunVideoSDKPro.framework", @"AliyunVideoSDKInfo", @"version", @"+", @"3.7.0"],
                        @[@"AlivcInteractiveLiveRoomSDK.framework", @"AlivcInteractiveLiveRoom", @"getSdkVersion", @"+", @"2.0.0"],
                        @[@"AlivcLivePusher.framework", @"AlivcLivePusher", @"getSDKVersion", @"-", @"3.3.7"],
                        @[@"AliyunVodPlayerSDK.framework", @"AliyunVodPlayer", @"getSDKVersion", @"-", @"3.4.8"],
                        @[@"AliyunPlayerSDK.framework", @"AliVcMediaPlayer", @"getSDKVersion", @"-", @"3.4.8"]];
    NSMutableArray * resArr = [NSMutableArray array];
    for (NSArray *subArr in sdkArr) {
        Class class = NSClassFromString(subArr[1]);
        SEL sel = sel_registerName([subArr[2] UTF8String]);
        if ([subArr[3] isEqualToString:@"+"]) {
            if ([class respondsToSelector:sel]) {
                NSString *version = objc_msgSend(class, sel);
                [resArr addObject:@[subArr[0], version, subArr[4]]];
            }
        } else if ([subArr[3] isEqualToString:@"-"]) {
            SEL selAlloc = @selector(alloc);
            SEL selInit = @selector(init);
            NSObject *ins = objc_msgSend(objc_msgSend(class, selAlloc), selInit);
            if ([ins respondsToSelector:sel]) {
                NSString *version = objc_msgSend(ins, sel);
                [resArr addObject:@[subArr[0], version, subArr[4]]];
            }
        }
    }
    
    NSLog(@"------------------------------------------------------------------------------------");
    NSLog(@"| %-40s | %-15s | %-8s | %-8s |", [@"SDK_Name" UTF8String], [@"Current" UTF8String], [@"Expect" UTF8String], [@"Result" UTF8String]);
    NSLog(@"------------------------------------------------------------------------------------");
    for (NSArray *subArr in resArr) {
        NSString *sdkName = subArr[0];
        NSString *sdkCurrentVersion = subArr[1];
        NSString *sdkNeedVersion = subArr[2];
        NSString *showStr = @"";
        if ([sdkCurrentVersion containsString:sdkNeedVersion]) {
            showStr = @"OK";
        } else {
            showStr = @"ERROR";
        }
        NSLog(@"| %-40s | %-15s | %-8s | %-8s |", [sdkName UTF8String], [sdkCurrentVersion UTF8String], [sdkNeedVersion UTF8String], [showStr UTF8String]);
        NSLog(@"------------------------------------------------------------------------------------");
        
    }
    
}

@end
