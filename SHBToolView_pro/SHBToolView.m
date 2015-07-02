//
//  SHBToolView.m
//  SHBToolView_pro
//
//  Created by 沈红榜 on 15/6/29.
//  Copyright (c) 2015年 沈红榜. All rights reserved.
//

#import "SHBToolView.h"
#import <HexColor.h>
//#import "AFSoundManager.h"
#import <DACircularProgressView.h>

#define ANGEL(x) (2 * M_PI * x) - M_PI / 2.

@interface SHBToolView ()<AVAudioPlayerDelegate>

/**
 *  toolView 状态
 */
@property (nonatomic, assign) SHBToolViewState toolViewState;

@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation SHBToolView {
    UIToolbar *_toolBar;
    UILabel *_label;
    UIButton *_centerBtn;
    UIButton *_cancelBtn;
    UIButton *_achieveBtn;
    
    NSArray *_images;
    
    DACircularProgressView *_progress;
    
    // 数据
    BOOL _isLayout;
    BOOL first;
    CGFloat keyboardH;
    
    // 约束
    NSMutableArray *_constraints;
    NSLayoutConstraint *_bottomPadding;
    
    // 声音
    NSString *_recordPath;
    
    NSTimeInterval _recordTime;
    
    NSDateFormatter *_formatter;
    
    NSTimer *_recordTimer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _isLayout = NO;
        first = NO;
        _constraints = [NSMutableArray array];
        _isUsing = NO;
        
        _images = @[@"baiYuan", @"luzhi", @"lu", @"start"];
        
        _toolBar = [[UIToolbar alloc] initWithFrame:CGRectZero];
        _toolBar.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_toolBar];
        //        CGFloat height = 196;
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [UIColor colorWithRed:0.886 green:0.886 blue:0.922 alpha:1.000];
        [self addSubview:view];
        
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        _label.text = @"点击录音";
        _label.textColor = [UIColor grayColor];
        _label.font = [UIFont systemFontOfSize:13];
        [self addSubview:_label];
        
        
        _progress = [[DACircularProgressView alloc] initWithFrame:CGRectZero];
        _progress.translatesAutoresizingMaskIntoConstraints = NO;
        _progress.trackTintColor = [UIColor colorWithHexString:@"d4d4d4"];
        _progress.progressTintColor = [UIColor colorWithRed:0.612 green:0.604 blue:0.745 alpha:1.000];
        _progress.innerTintColor = [UIColor whiteColor];
        _progress.thicknessRatio = 0.05;
        _progress.hidden = YES;
        [self addSubview:_progress];
        
        _centerBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _centerBtn.translatesAutoresizingMaskIntoConstraints = NO;
        _centerBtn.tag = 100;
        _centerBtn.frame = CGRectZero;
        [_centerBtn setBackgroundImage:[UIImage imageNamed:_images[0]] forState:UIControlStateNormal];
        UIImage *playImage = [UIImage imageNamed:_images[1]];
        playImage = [playImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [_centerBtn setImage:playImage forState:UIControlStateNormal];
        [_centerBtn addTarget:self action:@selector(clickedBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_centerBtn];
        
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _cancelBtn.translatesAutoresizingMaskIntoConstraints = NO;
        _cancelBtn.tag = 101;
        _cancelBtn.hidden = YES;
        _cancelBtn.frame = CGRectZero;
        _cancelBtn.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
        _cancelBtn.layer.borderColor = [UIColor colorWithHexString:@"d4d4d4"].CGColor;
        _cancelBtn.backgroundColor = [UIColor colorWithHexString:@"fafafc"];
        [_cancelBtn setTitleColor:[UIColor colorWithHexString:@"adaccb"] forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [_cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(cnToolViewCancel) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_cancelBtn];
        
        _achieveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _achieveBtn.translatesAutoresizingMaskIntoConstraints = NO;
        _achieveBtn.tag = 102;
        _achieveBtn.hidden = YES;
        _achieveBtn.frame = CGRectZero;
        _achieveBtn.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
        _achieveBtn.layer.borderColor = [UIColor colorWithHexString:@"d4d4d4"].CGColor;
        _achieveBtn.backgroundColor = _cancelBtn.backgroundColor;
        _achieveBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [_achieveBtn setTitleColor:[UIColor colorWithHexString:@"adaccb"] forState:UIControlStateNormal];
        [_achieveBtn setTitle:@"完成" forState:UIControlStateNormal];
        [_achieveBtn addTarget:self action:@selector(cnToolViewSure) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_achieveBtn];
        
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_toolBar, view, _label, _centerBtn, _cancelBtn, _achieveBtn, _progress);
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:0];
        [array addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_toolBar(49)][view(196)]" options:0 metrics:nil views:views]];
        [array addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_toolBar]|" options:0 metrics:nil views:views]];
        [array addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view]|" options:0 metrics:nil views:views]];
        [array addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_toolBar]-20-[_label]-10-[_centerBtn(90)]" options:0 metrics:nil views:views]];
        [array addObject:[NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [array addObject:[NSLayoutConstraint constraintWithItem:_centerBtn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:90]];
        [array addObject:[NSLayoutConstraint constraintWithItem:_centerBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        
        
        [array addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"[_progress(94)]" options:0 metrics:nil views:views]];
        [array addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_progress(94)]" options:0 metrics:nil views:views]];
        [array addObject:[NSLayoutConstraint constraintWithItem:_progress attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [array addObject:[NSLayoutConstraint constraintWithItem:_progress attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_centerBtn attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        
        
        
        [array addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_cancelBtn(40)]|" options:0 metrics:nil views:views]];
        [array addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_achieveBtn(_cancelBtn)]|" options:0 metrics:nil views:views]];
        [array addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(-1)-[_cancelBtn]-(-1)-[_achieveBtn(_cancelBtn)]-(-1)-|" options:0 metrics:nil views:views]];
        [self addConstraints:array];
        
        
        // 键盘
        [self registerForKeyboard];
        
        // 声音
        
        _recordPath = [NSTemporaryDirectory() stringByAppendingString:@"myRecord.caf"];
        self.session = [[AVAudioSession alloc] init];
        [self.session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat:@"mm:ss"];
        
    }
    return self;
}

#pragma mark - 点击中间按钮 触发哪个状态
- (void)clickedBtn:(UIButton *)btn {
    switch (_toolViewState) {
        case SHBToolViewDefault: {
            NSLog(@"开始录音");
            if ([_session respondsToSelector:@selector(requestRecordPermission:)]) {
                [_session requestRecordPermission:^(BOOL granted) {
                    _access = granted;
                    if (granted) {
                        _isUsing = YES;
                        self.toolViewState = SHBToolViewRecord;
                        [self.recorder deleteRecording];
                        [self.session setActive:YES error:nil];
                        [self startRecord];
                        _label.text = @"00:00";
                        _recordTimer = [NSTimer scheduledTimerWithTimeInterval:1 block:^{
                            NSString *time = [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:ceil(_recorder.currentTime)]];
                            _label.text = time;
                        } repeats:YES];
                    }
                }];
            }
            break;
        }
        case SHBToolViewRecord: {
            NSLog(@"结束录音");
            self.toolViewState = SHBToolViewStop;
            NSLog(@"cu:%lf", self.recorder.currentTime);
            _recordTime = self.recorder.currentTime;
            [_recordTimer invalidate];
            _recordTimer = nil;
            [self.recorder stop];
            
            break;
        }
        case SHBToolViewStop: {
            NSLog(@"开始播放");
            self.toolViewState = SHBToolViewPlay;
            _label.text = @"00:00";
            _progress.progress = 0;
            [self playLocalFile:nil andBlock:^(NSTimeInterval currentTime, NSTimeInterval duration, NSError *error, BOOL finished) {
                NSLog(@"current: %lf    duration:%lf", currentTime, duration);
                if (finished) {
                    [self setToolViewState:SHBToolViewStop];
                    [_progress setProgress:1 animated:YES];
                }
                NSString *time = [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:ceil(currentTime)]];
                _label.text = time;
                [_progress setProgress:currentTime / duration animated:YES initialDelay:0 withDuration:0.9];
            }];
            
            break;
        }
        case SHBToolViewPlay: {
            NSLog(@"暂停播放");
            self.toolViewState = SHBToolViewPause;
            [self pause];
            break;
        }
        case SHBToolViewPause: {
            NSLog(@"继续播放");
            self.toolViewState = SHBToolViewPlay;
            [self resume];
            break;
        }
        default: {
            break;
        }
    }
    if ([_delegate respondsToSelector:@selector(shbToolViewCenter)]) {
        [_delegate shbToolViewCenter];
    }
}

#pragma mark - 音频 =================================================================

- (void)startRecord {
    [self.session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:11025.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:_recordPath] settings:recordSetting error:nil];
    [self.recorder prepareToRecord];
    
    [self.recorder record];
}

- (void)startPlay {
    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:_recordPath] error:nil];
    [_player prepareToPlay];
    _player.volume = 1;
    _player.delegate = self;
    [_player play];
}

- (void)playLocalFile:(NSString *)filePath andBlock:(progressBlock)block {
    filePath = _recordPath;
    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSError *error = nil;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:_recordPath] error:&error];
    [_player prepareToPlay];
    _player.volume = 1;
    _player.delegate = self;
    [_player play];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(dataTimes:) userInfo:block repeats:YES];
}

- (void)dataTimes:(NSTimer *)time {
    if (time.userInfo) {
        void (^block)(NSTimeInterval, NSTimeInterval, NSError *, BOOL) = (void (^)(NSTimeInterval, NSTimeInterval, NSError *, BOOL))[time userInfo];
        if (ceil(_player.currentTime) >= _player.duration || _player.currentTime == 0) {
            block(_player.duration, _player.duration, nil, YES);
            [time invalidate];
            time = nil;
        } else {
            block(_player.currentTime, _player.duration, nil, NO);
        }
    }
}


- (void)pause {
    [_player pause];
    [_timer pauseTimer];
}

- (void)resume {
    [_player play];
    [_timer resumeTimer];
}

- (void)stop {
    [_player stop];
    [_timer pauseTimer];
}

- (void)restart {
    [self.player setCurrentTime:_player.currentTime];
    
}

#pragma mark - AVAudioPlayerDelegate
//- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
//    [self setToolViewState:CNToolViewStop];
//}

#pragma mark - toolView =================================================================
- (void)cnToolViewCancel {
    _isUsing = NO;
    [self setShow:NO animation:YES];
    if ([_delegate respondsToSelector:@selector(shbToolViewCancel)]) {
        [_delegate shbToolViewCancel];
    }
}

- (void)cnToolViewSure {
    if (_recordFile) {
        _recordFile(_recordPath);
    }
    [self setShow:NO animation:YES];
    if ([_delegate respondsToSelector:@selector(cnToolViewSure)]) {
        [_delegate shbToolViewSure];
    }
}

- (void)setCanRecord:(BOOL)canRecord {
    _canRecord = canRecord;
    if (!_canRecord) {
        [self setShow:NO animation:YES];
    }
}


- (void)setToolViewState:(SHBToolViewState)toolViewState {
    _toolViewState = toolViewState;
    NSLog(@"SHBToolViewState: %d", toolViewState);
    switch (_toolViewState) {
        case SHBToolViewDefault: {
            [_centerBtn setBackgroundImage:[UIImage imageNamed:_images[0]] forState:UIControlStateNormal];
            UIImage *centerImg = [UIImage imageNamed:_images[1]];
            centerImg = [centerImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            [_centerBtn setImage:centerImg forState:UIControlStateNormal];
            _progress.hidden = YES;
            _label.text = @"点击录音";
            break;
        }
        case SHBToolViewRecord: {
            UIImage *lu = [[UIImage imageNamed:_images[2]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            [_centerBtn setImage:lu forState:UIControlStateNormal];
            _cancelBtn.hidden = NO;
            _achieveBtn.hidden = NO;
            
            break;
        }
        case SHBToolViewStop: {
            UIImage *stop = [[UIImage imageNamed:_images[3]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            [_centerBtn setImage:stop forState:UIControlStateNormal];
            break;
        }
        case SHBToolViewPlay: {
            UIImage *play = [[UIImage imageNamed:_images[2]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            [_centerBtn setImage:play forState:UIControlStateNormal];
            _progress.hidden = NO;
            break;
        }
        case SHBToolViewPause: {
            UIImage *pause = [[UIImage imageNamed:_images[3]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            [_centerBtn setImage:pause forState:UIControlStateNormal];
            break;
        }
        default: {
            break;
        }
    }
}




#pragma mark - 加载 view
- (void)layoutSubviews{
    if (_isLayout) {
        return;
    }
    
    _isLayout = YES;
    UIView *view = self.superview;
    
    [view removeConstraints:_constraints];
    [_constraints removeAllObjects];
    
    self.translatesAutoresizingMaskIntoConstraints = false;
    NSDictionary *views = NSDictionaryOfVariableBindings(self);
    
    [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|[self]|" options:0 metrics:nil views:views]];
    [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[self(245)]" options:0 metrics:nil views:views]];
    
    _bottomPadding = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeBottom multiplier:1 constant:196];
    [_constraints addObject:_bottomPadding];
    
    [view addConstraints:_constraints];
}

// toolbar 设置item
- (void)setItems:(NSArray *)items animated:(BOOL)animated {
    [_toolBar setItems:items animated:animated];
}


#pragma mark - 弹出 下去
- (void)setShow:(BOOL)show animation:(BOOL)animation {
    CGFloat finalH = keyboardH ? keyboardH : 196;
    if (first) {
        finalH = keyboardH ? keyboardH : 196;
    } else {
        finalH = 196;
        keyboardH = 196;
    }
    
    if (!show) {
        _show = YES;
        [self setViewHeight:0 animation:animation];
        if (_isUsing) {
            [self recover];
        }
    } else {
        _show = NO;
        [self setViewHeight:finalH animation:animation];
    }
}

- (void)setViewHeight:(CGFloat)height animation:(BOOL)animation {
    _bottomPadding.constant = 196 - height;
    if (animation) {
        [UIView animateWithDuration:0.25 animations:^{
            [self layoutIfNeeded];
        }];
    }
}

#pragma mark - 监控键盘
- (void)registerForKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasHiddin:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification *)notif {
    first = YES;
    NSDictionary *info = [notif userInfo];
    
    NSValue *value = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize size = [value CGRectValue].size;
    keyboardH = keyboardH <= size.height ? size.height : keyboardH;
    
    keyboardH = size.height;
    [self setShow:YES animation:YES];
}

- (void)keyboardWasHiddin:(NSNotification *)notif {
    first = NO;
    [self setShow:NO animation:YES];
}

- (void)removeToolViewObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


- (void)dealloc {
    [self removeToolViewObserver];
}

/**
 *  纯复原 数据UI复原
 */
- (void)recover {
    self.toolViewState = SHBToolViewDefault;
    _cancelBtn.hidden = YES;
    _achieveBtn.hidden = YES;
    [self.recorder stop];
    [self.player stop];
    
    [self.session setActive:NO error:nil];
    self.recorder = nil;
    self.player = nil;
    [_timer invalidate];
    _timer = nil;
    [_recordTimer invalidate];
    _recordTimer = nil;
    _progress.progress = 0;
    _isUsing = NO;
    _label.text = @"点击录音";
}


/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end


@implementation NSTimer (Control)

+(id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats {
    
    void (^block)() = [inBlock copy];
    id ret = [self scheduledTimerWithTimeInterval:inTimeInterval target:self selector:@selector(executeSimpleBlock:) userInfo:block repeats:inRepeats];
    
    return ret;
}

+(void)executeSimpleBlock:(NSTimer *)inTimer {
    
    if ([inTimer userInfo]) {
        void (^block)() = (void (^)())[inTimer userInfo];
        block();
    }
}

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


