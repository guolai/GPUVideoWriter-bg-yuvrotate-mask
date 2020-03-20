//
//  SSZOpenGLTools.h
//  SimpleVideoFileFilter
//
//  Created by HaiboZhu on 2020/3/18.
//  Copyright © 2020 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

typedef NS_ENUM(NSUInteger, SSZVideoRotationMode) {
    SSZVideoNoRotation,
    SSZVideoRotateLeft,
    SSZVideoRotateRight,
    SSZVideoFlipVertical,
    SSZVideoFlipHorizonal,
    SSZVideoRotateRightFlipVertical,
    SSZVideoRotateRightFlipHorizontal,
    SSZVideoRotate180
};

struct SSZGPUVector4 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
    GLfloat four;
};
typedef struct SSZGPUVector4 SSZGPUVector4;

struct SSZGPUVector3 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
};
typedef struct SSZGPUVector3 SSZGPUVector3;

struct SSZGPUMatrix4x4 {
    SSZGPUVector4 one;
    SSZGPUVector4 two;
    SSZGPUVector4 three;
    SSZGPUVector4 four;
};
typedef struct SSZGPUMatrix4x4 SSZGPUMatrix4x4;

struct SSZGPUMatrix3x3 {
    SSZGPUVector3 one;
    SSZGPUVector3 two;
    SSZGPUVector3 three;
};
typedef struct SSZGPUMatrix3x3 SSZGPUMatrix3x3;

extern GLfloat *kSSZColorConversion601;
extern GLfloat *kSSZColorConversion601FullRange;
extern GLfloat *kSSZColorConversion709;
extern NSString *const kSSZYUVVideoRangeConversionForRGFragmentShaderString;
extern NSString *const kSSZYUVFullRangeConversionForLAFragmentShaderString;
extern NSString *const kSSZYUVVideoRangeConversionForLAFragmentShaderString;

@interface SSZOpenGLTools : NSObject

+ (GLuint)loadProgram:(NSString *)vertexShaderFilepath withFragmentShaderFilepath:(NSString *)fragmentShaderFilepath;
+ (GLuint)loadProgram:(NSString *)vertexShaderString withFragmentShader:(NSString *)fragmentShaderString;
+ (const GLfloat *)textureCoordinatesForRotation:(SSZVideoRotationMode)rotationMode;
+ (GLuint)createTextureWithImage:(UIImage *)image;
+ (void)loadOrthoMatrix:(GLfloat *)matrix left:(GLfloat)left right:(GLfloat)right bottom:(GLfloat)bottom top:(GLfloat)top near:(GLfloat)near far:(GLfloat)far;
+ (void)convert3DTransform:(CATransform3D *)transform3D toMatrix:(SSZGPUMatrix4x4 *)matrix;

@end

