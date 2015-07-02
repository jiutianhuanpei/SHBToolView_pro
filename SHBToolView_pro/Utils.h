//
//  Utils.h
//  CribnV3
//
//  Created by Barthoomew on 5/28/15.
//  Copyright (c) 2015 Barthoomew. All rights reserved.
//

#import <Foundation/Foundation.h>

void coverToMPEG4(NSURL *path,void(^finished)(NSURL*));
void coverToMPEG4FromAVAsset(id asset,void(^finished)(NSURL*));
void coverToMP3(NSURL *path,void(^finished)(NSURL *mp3Url));

