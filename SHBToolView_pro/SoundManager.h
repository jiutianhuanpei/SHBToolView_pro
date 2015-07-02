//
//  SoundManager.h
//  SHBToolView_pro
//
//  Created by 沈红榜 on 15/6/30.
//  Copyright (c) 2015年 沈红榜. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

typedef void (^progressBlock)(int percentage, CGFloat elapsedTime, CGFloat timeRemaining, NSError *error, BOOL finished);

@interface SoundManager : NSObject

+(instancetype)sharedManager;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVAudioRecorder *recorder;

@end


@interface NSTimer (Blocks)

+(id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats;
+(id)timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats;

@end

@interface NSTimer (Control)

-(void)pauseTimer;
-(void)resumeTimer;

@end