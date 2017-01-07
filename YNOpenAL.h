//
//  YNOpenAL.h
//  GoPro_Demo
//
//  Created by qiyun on 17/1/7.
//  Copyright © 2017年 qiyun. All rights reserved.
//  apple example <https://developer.apple.com/library/content/samplecode/MusicCube/Listings/Classes_MyOpenALSupport_h.html>

#import <Foundation/Foundation.h>
#import <OpenAL/OpenAL.h>
#import <AudioToolbox/AudioToolbox.h>

@interface YNOpenAL : NSObject{
    
    ALCcontext  *_alcContext;
    ALCdevice   *_alcDevice;
    AudioFileID _fileID;
    UInt32      _fileSize;
    
    NSMutableArray          *_bufferStorageArray;
    NSMutableDictionary     *_soundDictionary;
    
    void    *_outBuffer;
    
    @private
    void    *fileFormat;            // file format
    void    *dataOffSet;            // data offset
    void    *dataFormatName;        // format name
    void    *info;                  // file info , a dictionary
    void    *duration;
    void    *bitrate;
    void    *bitDepth;
    void    *trackCount;
    void    *audioTrack;
}

- (void)playAudioWithPath:(NSString *)filePath;
- (void)pause;
- (void)rewind;
- (void)stop;
- (void)cleanUpOpenAL;

@end
