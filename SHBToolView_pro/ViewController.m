//
//  ViewController.m
//  SHBToolView_pro
//
//  Created by 沈红榜 on 15/6/29.
//  Copyright (c) 2015年 沈红榜. All rights reserved.
//

#import "ViewController.h"
#import "SHBToolView.h"
#import "Utils.h"
#import <SVProgressHUD.h>
@interface ViewController ()<SHBToolViewDelegate>

@end

@implementation ViewController {
    UITextView *_textView;
    SHBToolView *_toolView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.title = @"SHBToolView_pro";
    
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(20, 100, CGRectGetWidth(self.view.frame) - 40, 100)];
    _textView.layer.borderColor = [UIColor grayColor].CGColor;
    _textView.layer.borderWidth = 1;
    [self.view addSubview:_textView];
//    [_textView becomeFirstResponder];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:tap];
    
    
    _toolView = [[SHBToolView alloc] initWithFrame:CGRectZero];
    _toolView.delegate = self;
    [self.view addSubview:_toolView];
    [_toolView setShow:NO animation:YES];
    
    [_toolView setItems:@[
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"keyboard"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(clickedToolBar:)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]
                          ] animated:YES];
    
    __weak typeof(self) SHB = self;
    _toolView.recordFile = ^(NSString *recordFile) {
        NSLog(@"录音文件：%@", recordFile);
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{  //  耗时 开线程
            
            coverToMP3([NSURL URLWithString:recordFile], ^(NSURL *mp3Url) {
                
                dispatch_async(dispatch_get_main_queue(), ^{    // 更新UI 要回主线程
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"录音文件路径：%@\nmp3文件路径：%@",recordFile , mp3Url] preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                        
                    }]];
                    [SVProgressHUD dismiss];
                    [SHB presentViewController:alert animated:YES completion:nil];
                });
            });
            
        });
    };
}

- (void)shbToolViewCancel {
    NSLog(@"cancel外");
}

- (void)shbToolViewSure {
    NSLog(@"sure外");
}

- (void)shbToolViewCenter {
    NSLog(@"center外");
}


- (void)clickedToolBar:(UIBarButtonItem *)item {
    if (_toolView.show) {
        [_toolView setShow:YES animation:YES];
    } else {
        [self.view endEditing:YES];
        [_toolView setShow:NO animation:YES];
    }
    
    
}

- (void)tap:(UITapGestureRecognizer *)tap {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
