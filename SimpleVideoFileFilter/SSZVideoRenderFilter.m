//
//  SSZVideoRenderFilter.m
//  SimpleVideoFileFilter
//
//  Created by HaiboZhu on 2020/3/18.
//  Copyright © 2020 Cell Phone. All rights reserved.
//

#import "SSZVideoRenderFilter.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>



NSString *const kSSZVideoRenderVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const kSSZVideoRenderTransformVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform mat4 transformMatrix;
 uniform mat4 orthographicMatrix;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = transformMatrix * vec4(position.xy, 1.0, 1.0) * orthographicMatrix;
     textureCoordinate = inputTextureCoordinate.xy;
 }
);

NSString *const kSSZVideoRenderPassthroughFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);


NSString *const kSSZVideoRenderFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(inputImageTexture, textureCoordinate).r;
     yuv.yz = texture2D(inputImageTexture2, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
);

NSString *const kSSZVideoMaskFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform vec2 maskSize;
 uniform vec2 maskPostion;
 
 vec4 blendColor(in highp vec4 dstColor, in highp vec4 srcColor)
  {
     vec3 vOne = vec3(1.0, 1.0, 1.0);
     vec3 vZero = vec3(0.0, 0.0, 0.0);
     vec3 resultFore = srcColor.rgb + dstColor.rgb * (1.0 - srcColor.a);
     return vec4(resultFore.rgb, 1.0);
 }

 void main()
 {
     vec4 bgColor = texture2D(inputImageTexture, textureCoordinate);
     float width = maskSize.x;
     float height = maskSize.y;
     if(textureCoordinate.x > maskPostion.x && textureCoordinate.x < maskPostion.x + width && textureCoordinate.y > maskPostion.y && textureCoordinate.y < maskPostion.y + height) {
         vec2 uv = textureCoordinate - vec2(maskPostion.x,maskPostion.y);
         vec4 srcColor = texture2D(inputImageTexture2, vec2(uv.x / width , uv.y / height));
         bgColor = blendColor(bgColor, srcColor);
     }
     gl_FragColor = bgColor;
 }
);

NSString *const kSSZVideoRenderFragmentShaderString1111 = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D maskTexture;
 
 uniform mediump mat3 colorConversionMatrix;
 uniform highp float aspectRatio;
 uniform highp float videoScale;
 
 vec4 blendColor(in highp vec4 dstColor, in highp vec4 srcColor)
  {
     vec3 vOne = vec3(1.0, 1.0, 1.0);
     vec3 vZero = vec3(0.0, 0.0, 0.0);
     vec3 resultFore = srcColor.rgb*srcColor.a + dstColor.rgb * (1.0 - srcColor.a);
     return vec4(resultFore.rgb, 1.0);
 }
 
 void main()
 {
     mediump vec3 yuv;
     highp vec3 rgb;
     
     highp vec2 yuvCoordinate = vec2(textureCoordinate.x, ((textureCoordinate.y - 0.5) * aspectRatio) + 0.5) * videoScale;
    
     yuv.x = texture2D(inputImageTexture, textureCoordinate).r;
     yuv.yz = texture2D(inputImageTexture2, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
    
    highp vec4 bgColor = vec4(rgb, 1.0);
    
     highp float width = 0.1;
     highp float height = 0.1;
    if(textureCoordinate.x > 0.85 && textureCoordinate.x < 0.85+width && textureCoordinate.y > 0.05 && textureCoordinate.y < 0.05+height)
    {
        highp vec2 uv = textureCoordinate - vec2(0.85,0.05);
        highp vec4 srcColor = texture2D(maskTexture, vec2(smoothstep(0.0, width, uv.x),smoothstep(height, 0.0, uv.y)));
        bgColor = blendColor(bgColor, srcColor);
    }
    gl_FragColor = bgColor;
 }
);

@interface SSZVideoRenderFilter () {
    
    GLint _normalPositionAttribute;
    GLint _normalTextureCoordinateAttribute;
    GLint _normalInputTextureUniform;
    
    GLint _filterPositionAttribute;
    GLint _filterTextureCoordinateAttribute;
    GLint _filterInputTextureUniform;
    GLint _filterInputTexture2Uniform;
    GLint _yuvConversionMatrixUniform;

    CVOpenGLESTextureCacheRef _coreVideoTextureCache;
    
    const GLfloat *_preferredConversion;
    BOOL _isFullYUVRange;
    int _imageBufferWidth;
    int _imageBufferHeight;
    GLuint _luminanceTexture;
    GLuint _chrominanceTexture;
    
    GLint _transformMatrixUniform;
    GLint _orthographicMatrixUniform;
    SSZGPUMatrix4x4 _orthographicMatrix;
    SSZGPUMatrix4x4 _transformMatrix;
    
    GLint _maskPositionAttribute;
    GLint _maskTextureCoordinateAttribute;
    GLint _maskInputTextureUniform;
    GLint _maskInputTextureUniform2;
    GLint _maskSizeUnform;
    GLint _maskPostionUnform;
    GLfloat _sizeArray[2];
    GLfloat _postionArray[2];
    
}
@property (nonatomic, strong) EAGLContext *eaglContext;
@property (nonatomic, assign) GLuint program;
@property (nonatomic, assign) GLuint maskProgram;
@property (nonatomic, assign) GLuint yuvProgram;
@property (nonatomic, assign) CGFloat widthScale;
@property (nonatomic, assign) CGFloat heightScale;
@property (nonatomic, strong) SSZGPUFrameBuffer *outputFrameBuffer;
@property (nonatomic, strong) SSZGPUFrameBuffer *maskOutputFrameBuffer;
@property (nonatomic, assign) GLuint maskTexture;
@property (nonatomic, assign) GLuint bgTexture;

@end

@implementation SSZVideoRenderFilter

- (void)dealloc {
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    if(_maskProgram) {
       glDeleteProgram(_maskProgram);
        _maskProgram = 0;
    }
    if(_yuvProgram) {
        glDeleteProgram(_yuvProgram);
        _yuvProgram = 0;
    }
    _outputFrameBuffer = nil;
    _maskOutputFrameBuffer = nil;
    if ([EAGLContext currentContext] == _eaglContext) {
        [EAGLContext setCurrentContext:nil];
    }
    if(_maskTexture > 0) {
        glDeleteTextures(1, &_maskTexture);
        _maskTexture = 0;
    }
    if(_bgTexture > 0) {
        glDeleteTextures(1, &_bgTexture);
        _bgTexture = 0;
    }
    
    _eaglContext = nil;
}

- (instancetype)init {
    if(self = [super init]) {
        _widthScale = 1.0;
        _heightScale = 1.0;
//        _inputRotation = SSZVideoNoRotation;
        _isFullYUVRange = YES;
        _preferredConversion = kSSZColorConversion709;
        _videoSize =  CGSizeMake(360, 640);
        [self createGLContext];
        [self linkShaderProgram];
        _transform3D = CATransform3DIdentity;
        
    }
    return self;
}

#pragma mark - Private

- (void)createGLContext {
    self.eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!self.eaglContext)
        self.eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (![EAGLContext setCurrentContext:self.eaglContext]) {
        NSLog(@"set currentContext failed");
    }
    glDisable(GL_DEPTH_TEST);
   
    CVReturn error = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.eaglContext, NULL, &_coreVideoTextureCache);
    if (error) {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", error);
    }
}

- (void)linkShaderProgram {
    
//    GLuint shaderProgram = [SSZOpenGLTools loadProgram:kSSZVideoRenderVertexShaderString withFragmentShader:kSSZVideoRenderFragmentShaderString];
    GLuint shaderProgram = [SSZOpenGLTools loadProgram:kSSZVideoRenderTransformVertexShaderString withFragmentShader:kSSZVideoRenderFragmentShaderString];
    glUseProgram(shaderProgram);
    self.yuvProgram = shaderProgram;
   
    _filterPositionAttribute = glGetAttribLocation(shaderProgram, "position");
    _filterTextureCoordinateAttribute = glGetAttribLocation(shaderProgram, "inputTextureCoordinate");
    _filterInputTextureUniform = glGetUniformLocation(shaderProgram, "inputImageTexture");
    _filterInputTexture2Uniform = glGetUniformLocation(shaderProgram, "inputImageTexture2");
    _yuvConversionMatrixUniform = glGetUniformLocation(shaderProgram, "colorConversionMatrix");
    _transformMatrixUniform = glGetUniformLocation(shaderProgram, "transformMatrix");
    _orthographicMatrixUniform = glGetUniformLocation(shaderProgram, "orthographicMatrix");
    
    shaderProgram = [SSZOpenGLTools loadProgram:kSSZVideoRenderVertexShaderString withFragmentShader:kSSZVideoRenderPassthroughFragmentShaderString];
    glUseProgram(shaderProgram);
    self.program = shaderProgram;
    _normalPositionAttribute = glGetAttribLocation(shaderProgram, "position");
    _normalTextureCoordinateAttribute = glGetAttribLocation(shaderProgram, "inputTextureCoordinate");
    _normalInputTextureUniform = glGetUniformLocation(shaderProgram, "inputImageTexture");
    
    shaderProgram = [SSZOpenGLTools loadProgram:kSSZVideoRenderVertexShaderString withFragmentShader:kSSZVideoMaskFragmentShaderString];
    glUseProgram(shaderProgram);
    self.maskProgram = shaderProgram;
    _maskPositionAttribute = glGetAttribLocation(shaderProgram, "position");
    _maskTextureCoordinateAttribute = glGetAttribLocation(shaderProgram, "inputTextureCoordinate");
    _maskInputTextureUniform = glGetUniformLocation(shaderProgram, "inputImageTexture");
    _maskInputTextureUniform2 = glGetUniformLocation(shaderProgram, "inputImageTexture2");
    _maskSizeUnform = glGetUniformLocation(shaderProgram, "maskSize");
    _maskPostionUnform = glGetUniformLocation(shaderProgram, "maskPostion");
    

 
}

- (void)useAsCurrentContext {
    EAGLContext *imageProcessingContext = self.eaglContext;
    if ([EAGLContext currentContext] != imageProcessingContext) {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
}

- (void)drawMaskFrame {
    if(self.maskTexture <= 0) {
        return;
    }
    if(!_maskOutputFrameBuffer) {
        _maskOutputFrameBuffer = [[SSZGPUFrameBuffer alloc] initWithSize:CGSizeMake(self.videoSize.width, self.videoSize.height)];
        _maskOutputFrameBuffer.coreVideoTextureCache = _coreVideoTextureCache;
        [_maskOutputFrameBuffer prepareGPUEvent];
    }
    
    glUseProgram(self.maskProgram);
    [_maskOutputFrameBuffer activateFramebuffer];
//    glClearColor(0.0, 0.0, 0.0, 1.0);
//    glClear(GL_COLOR_BUFFER_BIT);
    //draw bg
    static const GLfloat normalVertices[] = {
       -1.0f, -1.0f,
       1.0f, -1.0f,
       -1.0f,  1.0f,
       1.0f,  1.0f,
    };

    static const GLfloat normalTextureCoordinates[] = {
       0.0f, 0.0f,
       1.0f, 0.0f,
       0.0f, 1.0f,
       1.0f, 1.0f,
    };

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _outputFrameBuffer.texture);
    glUniform1i(_maskInputTextureUniform, 1);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, self.maskTexture);
    glUniform1i(_maskInputTextureUniform2, 2);
    
    glUniform2fv(_maskSizeUnform, 1, _sizeArray);
    glUniform2fv(_maskPostionUnform, 1, _postionArray);

    glVertexAttribPointer(_maskPositionAttribute, 2, GL_FLOAT, 0, 0, normalVertices);
    glVertexAttribPointer(_maskTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, normalTextureCoordinates);

    glEnableVertexAttribArray(_maskPositionAttribute);
    glEnableVertexAttribArray(_maskTextureCoordinateAttribute);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//    glDisableVertexAttribArray(_normalPositionAttribute);
//    glDisableVertexAttribArray(_normalTextureCoordinateAttribute);
}

- (void)drawMovieFrame {
//    [SSZOpenGLTools loadOrthoMatrix:(GLfloat *)&_orthographicMatrix left:-1.0 right:1.0 bottom:-1.0 top:1.0 near:-1.0 far:1.0];
//    [SSZOpenGLTools convert3DTransform:&_transform3D toMatrix:&_transformMatrix];
//    if(!_outputFrameBuffer) {
//        _outputFrameBuffer = [[SSZGPUFrameBuffer alloc] initWithSize:CGSizeMake(_imageBufferWidth, _imageBufferHeight)];
//        _outputFrameBuffer.coreVideoTextureCache = _coreVideoTextureCache;
//        [_outputFrameBuffer prepareGPUEvent];
//    }
    glUseProgram(self.yuvProgram);
    [_outputFrameBuffer activateFramebuffer];
//   glClearColor(0.0, 0.0, 0.0, 1.0);
//   glClear(GL_COLOR_BUFFER_BIT);
    CGFloat normalizedHeight = self.videoSize.height / self.videoSize.width;

    GLfloat adjustedVertices[] = {
        -1.0f, -normalizedHeight,
        1.0f, -normalizedHeight,
        -1.0f,  normalizedHeight,
        1.0f,  normalizedHeight,
    };
    
//    static const GLfloat squareVertices[] = {
//        -1.0f, -1.0f,
//        1.0f, -1.0f,
//        -1.0f,  1.0f,
//        1.0f,  1.0f,
//    };

    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };

    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, _luminanceTexture);
    glUniform1i(_filterInputTextureUniform, 4);

    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, _chrominanceTexture);
    glUniform1i(_filterInputTexture2Uniform, 5);
    
    glUniformMatrix4fv(_transformMatrixUniform, 1, GL_FALSE, (GLfloat *)&_transformMatrix);
    glUniformMatrix4fv(_orthographicMatrixUniform, 1, GL_FALSE, (GLfloat *)&_orthographicMatrix);
    glUniformMatrix3fv(_yuvConversionMatrixUniform, 1, GL_FALSE, _preferredConversion);
    glVertexAttribPointer(_filterPositionAttribute, 2, GL_FLOAT, 0, 0, adjustedVertices);
    glVertexAttribPointer(_filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glEnableVertexAttribArray(_filterPositionAttribute);
    glEnableVertexAttribArray(_filterTextureCoordinateAttribute);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//    glDisableVertexAttribArray(_filterPositionAttribute);
//    glDisableVertexAttribArray(_filterTextureCoordinateAttribute);
}


#pragma mark - Public

- (CVPixelBufferRef)renderVideo:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef tmpPixelBuffer = nil;
    
    if(!_outputFrameBuffer) {
       _outputFrameBuffer = [[SSZGPUFrameBuffer alloc] initWithSize:CGSizeMake(self.videoSize.width, self.videoSize.height)];
       _outputFrameBuffer.coreVideoTextureCache = _coreVideoTextureCache;
       [_outputFrameBuffer prepareGPUEvent];
    }
  
    if (!_ignoreAspectRatio) {
        [SSZOpenGLTools loadOrthoMatrix:(GLfloat *)&_orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * self.videoSize.height / self.videoSize.width) top:(1.0 * self.videoSize.height / self.videoSize.width) near:-1.0 far:1.0];
    } else {
        [SSZOpenGLTools loadOrthoMatrix:(GLfloat *)&_orthographicMatrix left:-1.0 right:1.0 bottom:-1.0 top:1.0 near:-1.0 far:1.0];
    }
    
    [SSZOpenGLTools convert3DTransform:&_transform3D toMatrix:&_transformMatrix];
    
    glUseProgram(self.program);
    [_outputFrameBuffer activateFramebuffer];
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    //draw bg
    static const GLfloat normalVertices[] = {
       -1.0f, -1.0f,
       1.0f, -1.0f,
       -1.0f,  1.0f,
       1.0f,  1.0f,
    };

    static const GLfloat normalTextureCoordinates[] = {
       0.0f, 0.0f,
       1.0f, 0.0f,
       0.0f, 1.0f,
       1.0f, 1.0f,
    };

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, self.bgTexture);
    glUniform1i(_normalInputTextureUniform, 1);

    glVertexAttribPointer(_normalPositionAttribute, 2, GL_FLOAT, 0, 0, normalVertices);
    glVertexAttribPointer(_normalTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, normalTextureCoordinates);

    glEnableVertexAttribArray(_normalPositionAttribute);
    glEnableVertexAttribArray(_normalTextureCoordinateAttribute);
    
    

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//    glDisableVertexAttribArray(_normalPositionAttribute);
//    glDisableVertexAttribArray(_normalTextureCoordinateAttribute);
    
    //draw yuv
    CVPixelBufferRef movieFrame = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferHeight = (int) CVPixelBufferGetHeight(movieFrame);
    int bufferWidth = (int) CVPixelBufferGetWidth(movieFrame);

    CFTypeRef colorAttachments = CVBufferGetAttachment(movieFrame, kCVImageBufferYCbCrMatrixKey, NULL);
    if (colorAttachments != NULL) {
       if(CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo) {
           if (_isFullYUVRange) {
               _preferredConversion = kSSZColorConversion601FullRange;
           } else {
               _preferredConversion = kSSZColorConversion601;
           }
       } else {
           _preferredConversion = kSSZColorConversion709;
       }
    } else {
       if (_isFullYUVRange) {
           _preferredConversion = kSSZColorConversion601FullRange;
       } else {
           _preferredConversion = kSSZColorConversion601;
       }

    }
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    [self useAsCurrentContext];

    CVOpenGLESTextureRef luminanceTextureRef = NULL;
    CVOpenGLESTextureRef chrominanceTextureRef = NULL;

    if (CVPixelBufferGetPlaneCount(movieFrame) > 0) {// Check for YUV planar inputs to do RGB conversion
       CVPixelBufferLockBaseAddress(movieFrame,0);
       if ( (_imageBufferWidth != bufferWidth) && (_imageBufferHeight != bufferHeight) ) {
           _imageBufferWidth = bufferWidth;
           _imageBufferHeight = bufferHeight;
       }

       CVReturn err;
       // Y-plane
       glActiveTexture(GL_TEXTURE4);
       err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _coreVideoTextureCache, movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);


       if(err) {
           NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
       }


       _luminanceTexture = CVOpenGLESTextureGetName(luminanceTextureRef);

       glBindTexture(GL_TEXTURE_2D, _luminanceTexture);
       glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
       glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

       // UV-plane
       glActiveTexture(GL_TEXTURE5);

       err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _coreVideoTextureCache, movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);

       if (err) {
           NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
       }


       _chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef);

       glBindTexture(GL_TEXTURE_2D, _chrominanceTexture);
       glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
       glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

       [self drawMovieFrame];

       CVPixelBufferUnlockBaseAddress(movieFrame, 0);
       CFRelease(luminanceTextureRef);
       CFRelease(chrominanceTextureRef);
    } else {
       NSLog(@"SSZVideoRenderFilter not handled");
    }
   
    //draw watermask
    [self drawMaskFrame];
    
    if (0) {
       CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
       NSLog(@"Current frame time : %f ms", 1000.0 * currentFrameTime);
    }
    glFinish();
    if(self.maskTexture > 0) {
          tmpPixelBuffer = self.maskOutputFrameBuffer.pixelBuffer;
    } else {
        tmpPixelBuffer = self.outputFrameBuffer.pixelBuffer;
    }
    return tmpPixelBuffer;
}

- (void)setAffineTransform:(CGAffineTransform)newValue {
    self.transform3D = CATransform3DMakeAffineTransform(newValue);
}

- (CGAffineTransform)affineTransform {
    return CATransform3DGetAffineTransform(self.transform3D);
}

- (void)setTransform3D:(CATransform3D)newValue {
    _transform3D = newValue;
}

- (void)setBgImage:(UIImage *)bgImage {
    if(_bgImage == bgImage){
        return;
    }
    _bgImage = bgImage;
    if(_bgTexture > 0) {
        glDeleteTextures(1, &_bgTexture);
    }
    _bgTexture = [SSZOpenGLTools createTextureWithImage:_bgImage];
}

- (void)setMaskImage:(UIImage *)maskImage {
    if(_maskImage == maskImage){
        return;
    }
    _maskImage = maskImage;
    if(_maskTexture > 0) {
        glDeleteTextures(1, &_maskTexture);
    }
    _maskTexture = [SSZOpenGLTools createTextureWithImage:_maskImage];
}

- (void)updateMaskImageFrame:(CGRect)frame {
    _sizeArray[0] = frame.size.width / self.videoSize.width;
    _sizeArray[1] = frame.size.height / self.videoSize.height;
    _postionArray[0] = frame.origin.x / self.videoSize.width;
    _postionArray[1] = frame.origin.y / self.videoSize.height;
}

@end
