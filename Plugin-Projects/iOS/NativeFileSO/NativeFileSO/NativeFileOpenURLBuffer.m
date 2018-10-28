//
//  NativeFileOpenURLBuffer.m
//  NativeFileSO
//
//  Created by Keiwan Donyagard on 16.10.18.
//  Copyright © 2018 Keiwan Donyagard. All rights reserved.
//
//

#import "NativeFileOpenURLBuffer.h"

@interface NativeFileOpenURLBuffer () {
    
    NSMutableArray<NSValue *> *_openedFiles;
}

@end

@implementation NativeFileOpenURLBuffer

static NativeFileOpenURLBuffer *_nativeFileOpenURLInstance;
static UnityCallbackFunction _nativeFileSOUnityCallback;

+(void)load {
    _nativeFileOpenURLInstance = [NativeFileOpenURLBuffer new];
}

+(NativeFileOpenURLBuffer *)instance {
    return _nativeFileOpenURLInstance;
}

-(instancetype)init {
    self = [super init];
    if (self) [self reset];
    return self;
}

-(void)reset {
    if (_openedFiles != nil) {
        [_openedFiles removeAllObjects];
    } else {
        _openedFiles = [[NSMutableArray alloc] init];
    }
}

-(void)loadBufferFromURLs:(NSArray<NSURL *> *)URLs {
    
    [_openedFiles removeAllObjects];
    
    for (int i = 0; i < URLs.count; i++) {
        [self addToBufferFromURL:URLs[i]];
    }
    
    if ([_openedFiles count] > 0 && _nativeFileSOUnityCallback) {
        _nativeFileSOUnityCallback();
    }
}

-(void)addToBufferFromURL:(NSURL *)URL {
    
    struct NativeFileSOOpenedFile *openedFile = [self loadFileFromURL:URL];
    NSValue *val = [NSValue valueWithPointer:openedFile];
    //NSValue *val = [NSValue valueWithBytes:&openedFile objCType:@encode(struct NativeFileSOOpenedFile)];
    [_openedFiles addObject:val];
}

-(struct NativeFileSOOpenedFile *)loadFileFromURL:(NSURL *)URL {
    
    NSData *data = [NSData dataWithContentsOfURL:URL];
    NSString *filename = URL.lastPathComponent ? : @"";
    
    struct NativeFileSOOpenedFile *file = malloc(sizeof(struct NativeFileSOOpenedFile));
    
    NSUInteger len = [filename lengthOfBytesUsingEncoding:NSASCIIStringEncoding];
    
    file->filename = malloc(len);
    strncpy((char *)file->filename, [filename UTF8String], len);
    //file.filename = [filename UTF8String];
    file->data = data.bytes;
    file->dataLength = (int)data.length;
    
    NSLog(@"Filename before boxing: %s", filename);
    
    return file;
}

-(void)setCallback:(UnityCallbackFunction) callback {
    _nativeFileSOUnityCallback = callback;
}

-(void)sendCallback {
    if (_nativeFileSOUnityCallback) {
        _nativeFileSOUnityCallback();
    }
}

-(int)getNumberOfOpenedFiles {
    return (int)_openedFiles.count;
}

-(struct NativeFileSOOpenedFile)getOpenedFileAtIndex:(int)index {
    struct NativeFileSOOpenedFile *file = malloc(sizeof(struct NativeFileSOOpenedFile));
    [_openedFiles[index] getValue:file];
    
    //file->filename = "Testname";
    NSLog(@"Filename after unboxing: %s", file->filename);
    return *file;
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    
    [self loadBufferFromURLs:urls];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [self sendCallback];
}

@end
