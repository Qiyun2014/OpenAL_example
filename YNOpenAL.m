//
//  YNOpenAL.m
//  GoPro_Demo
//
//  Created by qiyun on 17/1/7.
//  Copyright © 2017年 qiyun. All rights reserved.
//

#import "YNOpenAL.h"

@implementation YNOpenAL

- (id)init{
    
    if (self == [super init]) {
        
        // get device
        _alcDevice = alcOpenDevice("Device Name");
        
        if (alcGetError(_alcDevice) != ALC_TRUE) {
            
            perror("create device failed... \n");
            return NULL;
        }
        
        // create context
        _alcContext = alcCreateContext(_alcDevice, 0);
        
        // authentication
        if (alcMakeContextCurrent(_alcContext) != ALC_TRUE) {
            
            perror("create context failed... \n");
            return NULL;
        }
        
        // data params
        _soundDictionary = [[NSMutableDictionary alloc] init];
        _bufferStorageArray = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)playAudioWithPath:(NSString *)filePath{
    
    [self readDataFromFile:[self getFileIDFromFilePath:filePath]];
    
    [_bufferStorageArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        //play
        [self audioSourceWithBufferID:[obj intValue] sourceKey:@"com.audioKey.douyu"];
        alSourcePlay([obj unsignedIntValue]);
    }];
}


- (void)pause{
    
    [_bufferStorageArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        // pause
        alSourcePause([obj unsignedIntValue]);
    }];
}


- (void)rewind{
    
    [_bufferStorageArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        // rewind
        alSourceRewind([obj unsignedIntValue]);
    }];
}


- (void)stop{
    
    [_bufferStorageArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        // stop
        alSourceStop([obj unsignedIntValue]);
        
        if ((idx - 1) == _bufferStorageArray.count) {
            
            [_bufferStorageArray removeAllObjects];
            [_soundDictionary removeAllObjects];
        }
    }];
}


- (void)cleanUpOpenAL
{
    // delete the sources
    for (NSNumber* sourceNumber in [_soundDictionary allValues])
    {
        unsigned int sourceID = [sourceNumber unsignedIntValue];
        alDeleteSources(1, &sourceID);
    }
    
    [_soundDictionary removeAllObjects];
    
    // delete the buffers
    for (NSNumber* bufferNumber in _bufferStorageArray)
    {
        unsigned int bufferID = [bufferNumber unsignedIntValue];
        alDeleteBuffers(1, &bufferID);
    }
    [_bufferStorageArray removeAllObjects];
    
    // destroy the context
    alcDestroyContext(_alcContext);
    
    // close the device
    alcCloseDevice(_alcDevice);
}


- (AudioFileID)getFileIDFromFilePath:(NSString *)filePath{
    
    // file path, read or write, file type, (id)
    OSStatus status = AudioFileOpenURL((__bridge CFURLRef _Nonnull)([NSURL fileURLWithPath:filePath]), kAudioFileReadWritePermission, (kAudioFileMP3Type | kAudioFileAAC_ADTSType), &(_fileID));
    
    if (status == noErr) {
        
        perror("from path open the audio file failed... \n");
        return NULL;
    }else{
        
        _fileSize = [self getFileLength:_fileID];
    }
    return _fileID;
}


// get file info
- (UInt32)getFileLength:(AudioFileID)fileID{
    
    UInt32 thePropSize = sizeof(UInt64);
    UInt32 outFileSize = 0;
    
    OSStatus status = AudioFileGetProperty(fileID, kAudioFilePropertyAudioDataByteCount, &thePropSize, &outFileSize);
    //status = AudioFileGetPropertyInfo(fileID, kAudioFilePropertyAudioDataByteCount, &outFileSize, kAudioFileReadWritePermission);
    
    if (status == noErr) {
        
        perror("get file size failed... \n");
        return 0;
    }else{
        
        // get data info
        AudioFileGetProperty(fileID, kAudioFilePropertyFileFormat,      &thePropSize, &fileFormat);
        AudioFileGetProperty(fileID, kAudioFilePropertyDataOffset,      &thePropSize, &dataOffSet);
        AudioFileGetProperty(fileID, kAudioFilePropertyDataFormatName,  &thePropSize, &dataFormatName);
        AudioFileGetProperty(fileID, kAudioFilePropertyInfoDictionary,  &thePropSize, &info);
        AudioFileGetProperty(fileID, kAudioFilePropertyReserveDuration, &thePropSize, &duration);
        AudioFileGetProperty(fileID, kAudioFilePropertyBitRate,         &thePropSize, &bitrate);
        AudioFileGetProperty(fileID, kAudioFilePropertySourceBitDepth,  &thePropSize, &bitDepth);
        AudioFileGetProperty(fileID, kAudioFilePropertyAudioTrackCount, &thePropSize, &trackCount);
        AudioFileGetProperty(fileID, kAudioFilePropertyUseAudioTrack,   &thePropSize, &audioTrack);
    }
    return outFileSize;
}


// read file data
- (void *)readDataFromFile:(AudioFileID)fileID{
    
    _outBuffer = malloc(_fileSize * sizeof(UInt32));
    UInt32 ioNumBytes = 0;
    unsigned int   bufferID;

    // Read bytes of audio data from the audio file
    OSStatus status = AudioFileReadBytes(fileID, YES, 0, &ioNumBytes, _outBuffer);
    
    // Close an existing audio file.
    AudioFileClose(fileID);
    
    switch (status) {
            
        case kAudioFileEndOfFileError:
            
            NSLog(@"End of file.");
            break;
            
        case kAudioFileNotOpenError:
            
            NSLog(@"The file is closed.");
            break;
            
        case kAudioFileUnsupportedFileTypeError:
            
            NSLog(@"The file type is not supported.");
            break;
            
        case kAudioFileInvalidFileError:
            
            NSLog(@"The file is malformed, or otherwise not a valid instance of an audio file of its type.");
            break;
            
        default:
            break;
    }
    
    //AudioFileOpenWithCallbacks(<#void * _Nonnull inClientData#>, <#AudioFile_ReadProc  _Nonnull inReadFunc#>, <#AudioFile_WriteProc  _Nullable inWriteFunc#>, <#AudioFile_GetSizeProc  _Nonnull inGetSizeFunc#>, <#AudioFile_SetSizeProc  _Nullable inSetSizeFunc#>, <#AudioFileTypeID inFileTypeHint#>, <#AudioFileID  _Nullable * _Nonnull outAudioFile#>)
    
    // Create Buffer objects
    alGenBuffers(1, &bufferID);
    
    // Specify the data to be copied into a buffer
    alBufferData(bufferID, AL_FORMAT_STEREO16, _outBuffer, _fileSize, 44100);
    
    // store buffer id to array
    [_bufferStorageArray addObject:[NSNumber numberWithInt:bufferID]];
    
    return (status == noErr)?_outBuffer:nil;
}


- (void)audioSourceWithBufferID:(unsigned int)bufferID sourceKey:(NSString *)sourceKey{
    
    unsigned int   sourceID;
    
    // create sources
    alGenSources(1, &sourceID);
    
    // Sources take the PCM data provided in the specified Buffer
    alSourcei(sourceID, AL_BUFFER, bufferID);
    alSourcef(sourceID, AL_PITCH, 1.0f);
    alSourcef(sourceID, AL_GAIN, 1.0f);
    alSourcei(sourceID, AL_LOOPING, AL_TRUE);
    
    // store this for future use
    [_soundDictionary setObject:[NSNumber numberWithUnsignedInt:sourceID] forKey:sourceKey];
    
    // clean up the buffer  if (outData)
    {
        free(_outBuffer);
        _outBuffer = NULL;
    }
}

@end
