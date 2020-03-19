//
//  SSZOpenGLTools.m
//  SimpleVideoFileFilter
//
//  Created by HaiboZhu on 2020/3/18.
//  Copyright © 2020 Cell Phone. All rights reserved.
//

#import "SSZOpenGLTools.h"
#import <GLKit/GLKit.h>

// BT.601, which is the standard for SDTV.
GLfloat kSSZColorConversion601Default[] = {
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0,
};

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
GLfloat kSSZColorConversion601FullRangeDefault[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

// BT.709, which is the standard for HDTV.
GLfloat kSSZColorConversion709Default[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};


GLfloat *kSSZColorConversion601 = kSSZColorConversion601Default;
GLfloat *kSSZColorConversion601FullRange = kSSZColorConversion601FullRangeDefault;
GLfloat *kSSZColorConversion709 = kSSZColorConversion709Default;

NSString *const kSSZYUVVideoRangeConversionForRGFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).rg - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );


NSString *const kSSZYUVFullRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );

NSString *const kSSZYUVVideoRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r - (16.0/255.0);
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );



@implementation SSZOpenGLTools

+ (GLuint)loadShaderProgram:(GLenum)type withFilepath:(NSString *)shaderFilepath
{
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderFilepath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString)
    {
        NSLog(@"Error: loading shader file:%@  %@",shaderFilepath,error.localizedDescription);
        return 0;
    }
    return [self loadShader:type withString:shaderString];
}

+ (GLuint)loadShader:(GLenum)type withString:(NSString *)shaderString
{
    GLuint shader = glCreateShader(type);
    if (shader == 0)
    {
        NSLog(@"Error: failed to create shader.");
        return 0;
    }
    // Load the shader soure (加载着色器源码)
    const char *shaderStringUTF8 = [shaderString UTF8String];
    // 要编译的着色器对象作为第一个参数，第二个参数指定了传递的源码字符串数量，第三个着色器是顶点的真正的源码，第四个设置为NULL；
    glShaderSource(shader, 1, &shaderStringUTF8, NULL);
    // 编译着色器
    glCompileShader(shader);
    
    // 检查编译是否成功
    GLint success;
    GLchar infoLog[512];
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        GLint infolen;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infolen);
        
        if (infolen > 1)
        {
            char *infolog = malloc(sizeof(char) * infolen);
            glGetShaderInfoLog(shader, infolen, NULL, infoLog);
            NSLog(@"compile faile,error:%s",infoLog);
            free(infolog);
        }
        
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}


/**
 创建顶点着色器和片段着色器
 
 @param vertexShaderFilepath 顶点着色器路径
 @param fragmentShaderFilepath 片段着色器路径
 @return 链接成功后的着色器程序
 */
+ (GLuint)loadProgram:(NSString *)vertexShaderFilepath withFragmentShaderFilepath:(NSString *)fragmentShaderFilepath
{
    // Create vertexShader (创建顶点着色器)
    GLuint vertexShader = [self loadShaderProgram:GL_VERTEX_SHADER withFilepath:vertexShaderFilepath];
    if (vertexShader == 0)
        return 0;
    
    // Create fragmentShader (创建片段着色器)
    GLuint fragmentShader = [self loadShaderProgram:GL_FRAGMENT_SHADER withFilepath:fragmentShaderFilepath];
    if (fragmentShader == 0)
    {
        glDeleteShader(vertexShader);
        return 0;
    }
    
    // Create the program object (创建着色器程序)
    GLuint shaderProgram = glCreateProgram();
    if (shaderProgram == 0)
        return 0;
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    // Link the program (链接着色器程序)
    glLinkProgram(shaderProgram);
    
    // Check the link status (检查是否链接成功)
    GLint linked;
    GLchar infoLog[512];
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &linked);
    if (!linked)
    {
        glGetProgramInfoLog(shaderProgram, 512, NULL, infoLog);
        glDeleteProgram(shaderProgram);
        NSLog(@"Link shaderProgram failed");
        return 0;
    }
    
    // Free up no longer needed shader resources (释放不再需要的着色器资源)
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return shaderProgram;
}
+ (GLuint)loadProgram:(NSString *)vertexShaderString withFragmentShader:(NSString *)fragmentShaderString {
    // Create vertexShader
    GLuint vertexShader = [self loadShader:GL_VERTEX_SHADER withString:vertexShaderString];
    if (vertexShader == 0)
        return 0;
    
    // Create fragmentShader
    GLuint fragmentShader = [self loadShader:GL_FRAGMENT_SHADER withString:fragmentShaderString];
    if (fragmentShader == 0) {
        glDeleteShader(vertexShader);
        return 0;
    }
    
    // Create the program object
    GLuint shaderProgram = glCreateProgram();
    if (shaderProgram == 0)
        return 0;
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    // Link the program
    glLinkProgram(shaderProgram);
    
    // Check the link status
    GLint linked;
    GLchar infoLog[512];
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &linked);
    if (!linked) {
        glGetProgramInfoLog(shaderProgram, 512, NULL, infoLog);
        glDeleteProgram(shaderProgram);
        NSLog(@"Link shaderProgram failed");
        return 0;
    }
    
    // Free up no longer needed shader resources
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return shaderProgram;
}

+ (const GLfloat *)textureCoordinatesForRotation:(SSZVideoRotationMode)rotationMode {
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };

    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };

    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };

    switch(rotationMode)
    {
        case SSZVideoNoRotation: return noRotationTextureCoordinates;
        case SSZVideoRotateLeft: return rotateLeftTextureCoordinates;
        case SSZVideoRotateRight: return rotateRightTextureCoordinates;
        case SSZVideoFlipVertical: return verticalFlipTextureCoordinates;
        case SSZVideoFlipHorizonal: return horizontalFlipTextureCoordinates;
        case SSZVideoRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case SSZVideoRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case SSZVideoRotate180: return rotate180TextureCoordinates;
    }
}

+ (GLuint)createTextureWithImage:(UIImage *)inputImage {
    NSError *error = nil;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:inputImage.CGImage options:nil error:&error];
    if (error) {
//        NSAssert(NO, @"load image failed...%@",*error);
        NSLog(@"error : %@",error);
        
        int width = roundf(CGImageGetWidth(inputImage.CGImage));
        int height = roundf(CGImageGetHeight(inputImage.CGImage));
        
        UIGraphicsBeginImageContext(CGSizeMake(width, height));
        [[UIImage imageWithCGImage:inputImage.CGImage] drawInRect:CGRectMake(0, 0, width, height)];
        UIImage *imageref = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        textureInfo = [GLKTextureLoader textureWithCGImage:imageref.CGImage options:nil error:&error];
    }
    
    return textureInfo.name;
}

+ (void)loadOrthoMatrix:(GLfloat *)matrix left:(GLfloat)left right:(GLfloat)right bottom:(GLfloat)bottom top:(GLfloat)top near:(GLfloat)near far:(GLfloat)far {
    GLfloat r_l = right - left;
    GLfloat t_b = top - bottom;
    GLfloat f_n = far - near;
    GLfloat tx = - (right + left) / (right - left);
    GLfloat ty = - (top + bottom) / (top - bottom);
    GLfloat tz = - (far + near) / (far - near);
    
    float scale = 2.0f;
//    if (_anchorTopLeft) {
//        scale = 4.0f;
//        tx=-1.0f;
//        ty=-1.0f;
//    }
    
    matrix[0] = scale / r_l;
    matrix[1] = 0.0f;
    matrix[2] = 0.0f;
    matrix[3] = tx;
    
    matrix[4] = 0.0f;
    matrix[5] = scale / t_b;
    matrix[6] = 0.0f;
    matrix[7] = ty;
    
    matrix[8] = 0.0f;
    matrix[9] = 0.0f;
    matrix[10] = scale / f_n;
    matrix[11] = tz;
    
    matrix[12] = 0.0f;
    matrix[13] = 0.0f;
    matrix[14] = 0.0f;
    matrix[15] = 1.0f;
}

+ (void)convert3DTransform:(CATransform3D *)transform3D toMatrix:(SSZGPUMatrix4x4 *)matrix {
    //    struct CATransform3D
    //    {
    //        CGFloat m11, m12, m13, m14;
    //        CGFloat m21, m22, m23, m24;
    //        CGFloat m31, m32, m33, m34;
    //        CGFloat m41, m42, m43, m44;
    //    };
    
    GLfloat *mappedMatrix = (GLfloat *)matrix;
    
    mappedMatrix[0] = (GLfloat)transform3D->m11;
    mappedMatrix[1] = (GLfloat)transform3D->m12;
    mappedMatrix[2] = (GLfloat)transform3D->m13;
    mappedMatrix[3] = (GLfloat)transform3D->m14;
    mappedMatrix[4] = (GLfloat)transform3D->m21;
    mappedMatrix[5] = (GLfloat)transform3D->m22;
    mappedMatrix[6] = (GLfloat)transform3D->m23;
    mappedMatrix[7] = (GLfloat)transform3D->m24;
    mappedMatrix[8] = (GLfloat)transform3D->m31;
    mappedMatrix[9] = (GLfloat)transform3D->m32;
    mappedMatrix[10] = (GLfloat)transform3D->m33;
    mappedMatrix[11] = (GLfloat)transform3D->m34;
    mappedMatrix[12] = (GLfloat)transform3D->m41;
    mappedMatrix[13] = (GLfloat)transform3D->m42;
    mappedMatrix[14] = (GLfloat)transform3D->m43;
    mappedMatrix[15] = (GLfloat)transform3D->m44;
}

@end
