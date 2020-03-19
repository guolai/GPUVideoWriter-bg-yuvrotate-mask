//
//  SSZGPUContext.h
//  SimpleVideoFileFilter
//
//  Created by HaiboZhu on 2020/3/19.
//  Copyright © 2020 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSZGPUContext : NSObject
@property (nonatomic, strong, readonly) EAGLContext *glContext;
@property (nonatomic, assign, readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
+ (SSZGPUContext *)shareInstance;
- (void)purgeAllUnassignedFramebuffers;
@end

NS_ASSUME_NONNULL_END
