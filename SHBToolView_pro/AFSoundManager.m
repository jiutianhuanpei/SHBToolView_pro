//
//  AFSoundManager.m
//  AFSoundManager-Demo
//
//  Created by Alvaro Franco on 4/16/14.
//  Copyright (c) 2014 AlvaroFranco. All rights reserved.
//

#import "AFSoundManager.h"

@interface AFSoundManager ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) int type;
@property (nonatomic) int status;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVAudioRecorder *recorder;

@end

@implementation AFSoundManager

+(instancetype)sharedManager {
    
    static AFSoundManager *soundManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        soundManager = [[self alloc]init];
    });
    
    return soundManager;
}

-(void)startPlayingLocalFilePath:(NSString *)path andBlock:(progressBlock)block {
    
//    NSString *filePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle]resourcePath], name];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    
    self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:fileURL error:&error];
    [self.audioPlayer play];
    
    __block int percentage = 0;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 block:^{
        
        if (percentage != 100) {
            
            percentage = (int)((self.audioPlayer.currentTime * 100)/self.audioPlayer.duration);
            int timeRemaining = self.audioPlayer.duration - self.audioPlayer.currentTime;
            
            block(percentage, self.audioPlayer.currentTime, timeRemaining, error, NO);
        } else {
            
            int timeRemaining = self.audioPlayer.duration - self.audioPlayer.currentTime;

            block(100, self.audioPlayer.currentTime, timeRemaining, error, YES);
            
            [_timer invalidate];
        }
    } repeats:YES];
}

-(void)startStreamingRemoteAudioFromURL:(NSString *)url andBlock:(progressBlock)block {
    
    NSURL *streamingURL = [NSURL URLWithString:url];
    NSError *error = nil;
    
    self.player = [[AVPlayer alloc]initWithURL:streamingURL];
    [self.player play];
    
    if (!error) {
    
        __block int percentage = 0;
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 block:^{
            
            if (percentage != 100) {
                
                percentage = (int)((CMTimeGetSeconds(self.player.currentItem.currentTime) * 100)/CMTimeGetSeconds(self.player.currentItem.duration));
                int timeRemaining = CMTimeGetSeconds(self.player.currentItem.duration) - CMTimeGetSeconds(self.player.currentItem.currentTime);
                
                block(percentage, CMTimeGetSeconds(self.player.currentItem.currentTime), timeRemaining, error, NO);
            } else {
                
                int timeRemaining = CMTimeGetSeconds(self.player.currentItem.duration) - CMTimeGetSeconds(self.player.currentItem.currentTime);
                
                block(100, CMTimeGetSeconds(self.player.currentItem.currentTime), timeRemaining, error, YES);
                
                [_timer invalidate];
            }
        } repeats:YES];
    } else {
        
        block(0, 0, 0, error, YES);
        [self.audioPlayer stop];
    }
    
}

-(NSDictionary *)retrieveInfoForCurrentPlaying {
    
    if (self.audioPlayer.url) {
        
        NSArray *parts = [self.audioPlayer.url.absoluteString componentsSeparatedByString:@"/"];
        NSString *filename = [parts objectAtIndex:[parts count]-1];
        
        NSDictionary *info = @{@"name": filename, @"duration": [NSNumber numberWithInt:self.audioPlayer.duration], @"elapsed time": [NSNumber numberWithInt:self.audioPlayer.currentTime], @"remaining time": [NSNumber numberWithInt:(self.audioPlayer.duration - self.audioPlayer.currentTime)], @"volume": [NSNumber numberWithFloat:self.audioPlayer.volume]};
        
        return info;
    } else {
        return nil;
    }
}

-(void)pause {
    [self.audioPlayer pause];
    [self.player pause];
    [_timer pauseTimer];
}

-(void)resume {
    [self.audioPlayer play];
    [self.player play];
    [_timer resumeTimer];
}

-(void)stop {
    [self.audioPlayer stop];
    self.player = nil;
    [_timer pauseTimer];
}

-(void)restart {
    [self.audioPlayer setCurrentTime:0];
    
    int32_t timeScale = self.player.currentItem.asset.duration.timescale;
    [self.player seekToTime:CMTimeMake(0.000000, timeScale)];
}

-(void)moveToSecond:(int)second {
    [self.audioPlayer setCurrentTime:second];
    
    int32_t timeScale = self.player.currentItem.asset.duration.timescale;
    [self.player seekToTime:CMTimeMakeWithSeconds((Float64)second, timeScale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

-(void)moveToSection:(CGFloat)section {
    int audioPlayerSection = self.audioPlayer.duration * section;
    [self.audioPlayer setCurrentTime:audioPlayerSection];
    
    int32_t timeScale = self.player.currentItem.asset.duration.timescale;
    Float64 playerSection = CMTimeGetSeconds(self.player.currentItem.duration) * section;
    [self.player seekToTime:CMTimeMakeWithSeconds(playerSection, timeScale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

-(void)changeSpeedToRate:(CGFloat)rate {
    self.audioPlayer.rate = rate;
    self.player.rate = rate;
}

-(void)changeVolumeToValue:(CGFloat)volume {
    self.audioPlayer.volume = volume;
    self.player.volume = volume;
}

-(void)startRecordingAudioWithFilePath:(NSString *)name shouldStopAtSecond:(NSTimeInterval)second {
    
//    self.recorder = [[AVAudioRecorder alloc]initWithURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@.%@", [NSHomeDirectory() stringByAppendingString:@"/Documents"], name, extension]] settings:nil error:nil];
    self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:name] settings:nil error:nil];
    
    if (second == 0 && !second) {
        [self.recorder record];
    } else {
        [self.recorder recordForDuration:second];
    }
}

-(void)pauseRecording {
    
    if ([self.recorder isRecording]) {
        [self.recorder pause];
    }
}

-(void)resumeRecording {
    
    if (![self.recorder isRecording]) {
        [self.recorder record];
    }
}

-(void)stopAndSaveRecording {
    [self.recorder stop];
}

-(void)deleteRecording {
    [self.recorder deleteRecording];
}

-(NSInteger)timeRecorded {
    return [self.recorder currentTime];
}

-(BOOL)areHeadphonesConnected {
    
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance]currentRoute];
        
    BOOL headphonesLocated = NO;
    
    for (AVAudioSessionPortDescription *portDescription in route.outputs) {
        
        headphonesLocated |= ([portDescription.portType isEqualToString:AVAudioSessionPortHeadphones]);
    }
    
    return headphonesLocated;
}

-(void)forceOutputToDefaultDevice {
    
    [AFAudioRouter initAudioSessionRouting];
    [AFAudioRouter switchToDefaultHardware];
}

-(void)forceOutputToBuiltInSpeakers {
    
    [AFAudioRouter initAudioSessionRouting];
    [AFAudioRouter forceOutputToBuiltInSpeakers];
}

@end

@implementation NSTimer (Blocks)

+(id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats {
    
    void (^block)() = [inBlock copy];
    id ret = [self scheduledTimerWithTimeInterval:inTimeInterval target:self selector:@selector(executeSimpleBlock:) userInfo:block repeats:inRepeats];
    
    return ret;
}

+(id)timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats {
    
    void (^block)() = [inBlock copy];
    id ret = [self timerWithTimeInterval:inTimeInterval target:self selector:@selector(executeSimpleBlock:) userInfo:block repeats:inRepeats];
    
    return ret;
}

+(void)executeSimpleBlock:(NSTimer *)inTimer {
    
    if ([inTimer userInfo]) {
        void (^block)() = (void (^)())[inTimer userInfo];
        block();
    }
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
