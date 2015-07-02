//
//  SoundManager.m
//  SHBToolView_pro
//
//  Created by 沈红榜 on 15/6/30.
//  Copyright (c) 2015年 沈红榜. All rights reserved.
//

#import "SoundManager.h"

@interface SoundManager ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) int type;
@property (nonatomic) int status;

@end

@implementation SoundManager

+(instancetype)sharedManager {
    
    static SoundManager *soundManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        soundManager = [[self alloc] init];
    });
    
    return soundManager;
}

-(void)startPlayingLocalFileWithPath:(NSString *)path andBlock:(progressBlock)block {
    
//    NSString *filePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle]resourcePath], name];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    
    _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:fileURL error:&error];
    [_audioPlayer play];
    
    __block int percentage = 0;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 block:^{
        
        if (percentage != 100) {
            
            percentage = (int)((_audioPlayer.currentTime * 100)/_audioPlayer.duration);
            int timeRemaining = _audioPlayer.duration - _audioPlayer.currentTime;
            
            block(percentage, _audioPlayer.currentTime, timeRemaining, error, NO);
        } else {
            
            int timeRemaining = _audioPlayer.duration - _audioPlayer.currentTime;
            
            block(100, _audioPlayer.currentTime, timeRemaining, error, YES);
            
            [_timer invalidate];
        }
    } repeats:YES];
}

-(NSDictionary *)retrieveInfoForCurrentPlaying {
    
    if (_audioPlayer.url) {
        
        NSArray *parts = [_audioPlayer.url.absoluteString componentsSeparatedByString:@"/"];
        NSString *filename = [parts objectAtIndex:[parts count]-1];
        
        NSDictionary *info = @{@"name": filename, @"duration": [NSNumber numberWithInt:_audioPlayer.duration], @"elapsed time": [NSNumber numberWithInt:_audioPlayer.currentTime], @"remaining time": [NSNumber numberWithInt:(_audioPlayer.duration - _audioPlayer.currentTime)], @"volume": [NSNumber numberWithFloat:_audioPlayer.volume]};
        
        return info;
    } else {
        return nil;
    }
}

-(void)pause {
    [_audioPlayer pause];
    [_player pause];
    [_timer pauseTimer];
}

-(void)resume {
    [_audioPlayer play];
    [_player play];
    [_timer resumeTimer];
}

-(void)stop {
    [_audioPlayer stop];
    _player = nil;
    [_timer pauseTimer];
}

-(void)restart {
    [_audioPlayer setCurrentTime:0];
    
    int32_t timeScale = _player.currentItem.asset.duration.timescale;
    [_player seekToTime:CMTimeMake(0.000000, timeScale)];
}

-(void)moveToSecond:(int)second {
    [_audioPlayer setCurrentTime:second];
    
    int32_t timeScale = _player.currentItem.asset.duration.timescale;
    [_player seekToTime:CMTimeMakeWithSeconds((Float64)second, timeScale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

-(void)moveToSection:(CGFloat)section {
    int audioPlayerSection = _audioPlayer.duration * section;
    [_audioPlayer setCurrentTime:audioPlayerSection];
    
    int32_t timeScale = _player.currentItem.asset.duration.timescale;
    Float64 playerSection = CMTimeGetSeconds(_player.currentItem.duration) * section;
    [_player seekToTime:CMTimeMakeWithSeconds(playerSection, timeScale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

-(void)changeSpeedToRate:(CGFloat)rate {
    _audioPlayer.rate = rate;
    _player.rate = rate;
}

-(void)changeVolumeToValue:(CGFloat)volume {
    _audioPlayer.volume = volume;
    _player.volume = volume;
}


@end


@implementation NSTimer (Control)

static NSString *const NSTimerPauseDate = @"NSTimerPauseDate";
static NSString *const NSTimerPreviousFireDate = @"NSTimerPreviousFireDate";

-(void)pauseTimer {
    
    objc_setAssociatedObject(self, (__bridge const void *)(NSTimerPauseDate), [NSDate date], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, (__bridge const void *)(NSTimerPreviousFireDate), self.fireDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    self.fireDate = [NSDate distantFuture];
}

-(void)resumeTimer {
    
    NSDate *pauseDate = objc_getAssociatedObject(self, (__bridge const void *)NSTimerPauseDate);
    NSDate *previousFireDate = objc_getAssociatedObject(self, (__bridge const void *)NSTimerPreviousFireDate);
    
    const NSTimeInterval pauseTime = -[pauseDate timeIntervalSinceNow];
    self.fireDate = [NSDate dateWithTimeInterval:pauseTime sinceDate:previousFireDate];
}

@end