//
//  Utils.m
//  CribnV3
//
//  Created by Barthoomew on 5/28/15.
//  Copyright (c) 2015 Barthoomew. All rights reserved.
//

#import "Utils.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "lame.h"


void coverToMPEG4(NSURL *path, void(^finished)(NSURL*)) {
    NSString *_mp4Path = nil;
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:path options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:AVAssetExportPreset640x480]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc ] initWithAsset:avAsset presetName:AVAssetExportPreset640x480];
        
        NSDateFormatter* formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
        NSString *path = [NSString stringWithFormat:@"/%@.mp4", [formater stringFromDate:[NSDate date]]];
        _mp4Path = [NSTemporaryDirectory() stringByAppendingPathComponent:path];
        exportSession.outputURL = [NSURL fileURLWithPath:_mp4Path];
        exportSession.shouldOptimizeForNetworkUse = true;
        exportSession.outputFileType = AVFileTypeMPEG4;
        NSURL *url = [NSURL fileURLWithPath:_mp4Path];
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusCompleted:
                    finished(url);
                    break;
                default:
                    finished(nil);
                    break;
            }
        }];
    }
}

void coverToMPEG4FromAVAsset(AVAsset *asset, void(^finished)(NSURL*)) {
    NSString *_mp4Quality = AVAssetExportPresetMediumQuality;
    NSString *_mp4Path = nil;
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    if ([compatiblePresets containsObject:_mp4Quality]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc ] initWithAsset:asset presetName:_mp4Quality];
        NSDateFormatter* formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
        NSString *path = [NSString stringWithFormat:@"/%@.mp4", [formater stringFromDate:[NSDate date]]];
        _mp4Path = [NSTemporaryDirectory() stringByAppendingPathComponent:path];
        exportSession.outputURL = [NSURL fileURLWithPath:_mp4Path];
        exportSession.shouldOptimizeForNetworkUse = true;
        exportSession.outputFileType = AVFileTypeMPEG4;
        NSURL *url = [NSURL fileURLWithPath:_mp4Path];
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusCompleted:
                    finished(url);
                    break;
                default:
                    finished(nil);
                    break;
            }
        }];
    }
}

void coverToMP3(NSURL *path,void(^finished)(NSURL*mp3Url)) {
    NSURL  *mp3FilePath = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"record.mp3"]];
    @try {
        int read, write;
        FILE *pcm = fopen([path fileSystemRepresentation], "rb");
        fseek(pcm, 4*1024, SEEK_CUR);
        FILE *mp3 = fopen([mp3FilePath fileSystemRepresentation], "wb");
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 11025.0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        finished(nil);
    }
    @finally {
        finished(mp3FilePath);
    }
}
