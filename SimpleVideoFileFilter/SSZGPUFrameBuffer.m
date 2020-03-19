//
//  SSZGPUFrameBuffer.m
//  SimpleVideoFileFilter
//
//  Created by HaiboZhu on 2020/3/18.
//  Copyright © 2020 Cell Phone. All rights reserved.
//

#import "SSZGPUFrameBuffer.h"

@interface SSZGPUFrameBuffer () {
    GLuint _framebuffer;
    CVPixelBufferRef _renderTarget;
    CVOpenGLESTextureRef _renderTexture;
    
}
@property (nonatomic, assign) SSZGPUTextureOptions textureOptions;
@property (nonatomic, assign) BOOL bNotUseFrameBuffer;
@property(nonatomic, assign) CGSize size;
@property(nonatomic, assign) GLuint texture;
- (void)generateFramebuffer;
- (void)generateTexture;
- (void)destroyFramebuffer;
@end

@implementation SSZGPUFrameBuffer

- (void)dealloc
{
    [self destroyFramebuffer];
}

- (instancetype)initWithSize:(CGSize)framebufferSize
              textureOptions:(SSZGPUTextureOptions)fboTextureOptions
                 onlyTexture:(BOOL)onlyGenerateTexture {
    if (!(self = [super init])) {
        return nil;
    }
    
    _textureOptions = fboTextureOptions;
    _size = framebufferSize;

    _bNotUseFrameBuffer = onlyGenerateTexture;
    return self;
}

- (instancetype)initWithSize:(CGSize)framebufferSize overriddenTexture:(GLuint)inputTexture {
    if (!(self = [super init])) {
        return nil;
    }

    SSZGPUTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;

    _textureOptions = defaultTextureOptions;
    _size = framebufferSize;
 
    
    _texture = inputTexture;
    
    return self;
}

- (instancetype)initWithSize:(CGSize)framebufferSize {
    SSZGPUTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;

    if (!(self = [self initWithSize:framebufferSize textureOptions:defaultTextureOptions onlyTexture:NO])) {
        return nil;
    }

    return self;
}

#pragma mark - Public

- (void)prepareGPUEvent {
    if (_bNotUseFrameBuffer)  {
      [self generateTexture];
      _framebuffer = 0;
    }  else {
      [self generateFramebuffer];
    }
}

- (CVPixelBufferRef)pixelBuffer {
    return _renderTarget;
}

- (GLuint)texture {
//    NSLog(@"Accessing texture: %d from FB: %@", _texture, self);
    return _texture;
}

- (void)activateFramebuffer {
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glViewport(0, 0, (int)_size.width, (int)_size.height);
}

#pragma mark - Private

- (void)generateTexture {
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _textureOptions.magFilter);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);

}

- (void)generateFramebuffer {

    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);

    CVOpenGLESTextureCacheRef coreVideoTextureCache = self.coreVideoTextureCache;

    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);

    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)_size.width, (int)_size.height, kCVPixelFormatType_32BGRA, attrs, &_renderTarget);
    if (err)
    {
        NSLog(@"FBO size: %f, %f", _size.width, _size.height);
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
    }

    err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, coreVideoTextureCache, _renderTarget,
                                                        NULL, // texture attributes
                                                        GL_TEXTURE_2D,
                                                        _textureOptions.internalFormat, // opengl format
                                                        (int)_size.width,
                                                        (int)_size.height,
                                                        _textureOptions.format, // native iOS format
                                                        _textureOptions.type,
                                                        0,
                                                        &_renderTexture);
    if(err) {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }

    CFRelease(attrs);
    CFRelease(empty);

    glBindTexture(CVOpenGLESTextureGetTarget(_renderTexture), CVOpenGLESTextureGetName(_renderTexture));
    _texture = CVOpenGLESTextureGetName(_renderTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_renderTexture), 0);


    #ifdef SSZFB_DEBUG
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    #endif

    glBindTexture(GL_TEXTURE_2D, 0);

}

- (void)destroyFramebuffer {
    if (_framebuffer)
    {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }


    if (!_bNotUseFrameBuffer) {
        if (_renderTarget) {
            CFRelease(_renderTarget);
            _renderTarget = NULL;
        }
        
        if (_renderTexture) {
            CFRelease(_renderTexture);
            _renderTexture = NULL;
        }
    } else {
         glDeleteTextures(1, &_texture);
        _texture = 0;
    }
}

#pragma mark -
#pragma mark Usage



@end
