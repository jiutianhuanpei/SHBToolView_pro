//
//  SHBToolView.h
//  SHBToolView_pro
//
//  Created by 沈红榜 on 15/6/29.
//  Copyright (c) 2015年 沈红榜. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

/**
 *  音频 回调
 *
 *  @param percentage    播放 百分比
 *  @param elapsedTime   已播放时间
 *  @param timeRemaining 总时间
 *  @param error
 *  @param finished      是否播放完毕
 */
typedef void (^progressBlock)(NSTimeInterval currentTime, NSTimeInterval duration, NSError *error, BOOL finished);

typedef NS_ENUM(NSInteger, SHBToolViewState) {
    SHBToolViewDefault,
    SHBToolViewRecord,
    SHBToolViewStop,
    SHBToolViewPlay,
    SHBToolViewPause,
};

@protocol SHBToolViewDelegate <NSObject>

- (void)shbToolViewCancel;
- (void)shbToolViewSure;
- (void)shbToolViewCenter;

@end

@interface SHBToolView : UIView

/**
 *  录音文件地址
 */
@property (nonatomic, copy) void(^recordFile)(NSString *path);


/**
 *  弹出（YES）
 */
@property (nonatomic, assign, readonly) BOOL show;

@property (nonatomic, assign) id<SHBToolViewDelegate> delegate;

/**
 *  是否录音了， yes录了
 */
@property (nonatomic, assign, readonly) BOOL isUsing;

/**
 *  是否可以录音
 */
@property (nonatomic, assign) BOOL canRecord;

/**
 *  录音权限
 */
@property (nonatomic, assign) BOOL access;

/**
 *  设置 toolview 上的 item
 *
 *  @param items    UIBarButtonItem
 *  @param animated
 */
- (void)setItems:(NSArray *)items animated:(BOOL)animated;


- (void)setShow:(BOOL)show animation:(BOOL)animation;


@end

@interface NSTimer (Control)

+(id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats;
-(void)pauseTimer;
-(void)resumeTimer;

@end

