//
//  SSZGPUFrameBuffer.h
//  SimpleVideoFileFilter
//
//  Created by HaiboZhu on 2020/3/18.
//  Copyright © 2020 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

#define SSZFB_DEBUG 1

typedef struct SSZGPUTextureOptions {
    GLenum minFilter;
    GLenum magFilter;
    GLenum wrapS;
    GLenum wrapT;
    GLenum internalFormat;
    GLenum format;
    GLenum type;
} SSZGPUTextureOptions;


NS_ASSUME_NONNULL_BEGIN

@interface SSZGPUFrameBuffer : NSObject
@property (nonatomic, assign) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property(nonatomic, assign, readonly) GLuint texture;

- (instancetype)initWithSize:(CGSize)framebufferSize;
- (instancetype)initWithSize:(CGSize)framebufferSize
              textureOptions:(SSZGPUTextureOptions)fboTextureOptions
                 onlyTexture:(BOOL)onlyGenerateTexture;
- (instancetype)initWithSize:(CGSize)framebufferSize overriddenTexture:(GLuint)inputTexture;

- (void)prepareGPUEvent;
- (void)activateFramebuffer;
- (CVPixelBufferRef)pixelBuffer;
@end

NS_ASSUME_NONNULL_END
