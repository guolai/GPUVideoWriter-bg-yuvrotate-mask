//
//  SSZGPUContext.m
//  SimpleVideoFileFilter
//
//  Created by HaiboZhu on 2020/3/19.
//  Copyright © 2020 Cell Phone. All rights reserved.
//

#import "SSZGPUContext.h"


@interface SSZGPUContext (){
    CVOpenGLESTextureCacheRef _coreVideoTextureCache;
}
@property (nonatomic, strong, readwrite) EAGLContext *glContext;
@end

@implementation SSZGPUContext

+ (SSZGPUContext *)shareInstance {
    static SSZGPUContext *_sszGpuContext = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sszGpuContext = [[SSZGPUContext alloc] init];
    });
    return _sszGpuContext;
}

- (instancetype)init {
    if(self = [super init]) {
        [self createGLContext];
    }
    return self;
}

- (void)createGLContext {
    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!self.glContext)
        self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (![EAGLContext setCurrentContext:self.glContext]) {
        NSLog(@"set currentContext failed");
    }
    glDisable(GL_DEPTH_TEST);
    
    CVReturn error = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glContext, NULL, &_coreVideoTextureCache);
    if (error) {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", error);
    }
}

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache {
    return _coreVideoTextureCache;
}

- (void)purgeAllUnassignedFramebuffers{
    CVOpenGLESTextureCacheFlush(_coreVideoTextureCache, 0);
}

@end
