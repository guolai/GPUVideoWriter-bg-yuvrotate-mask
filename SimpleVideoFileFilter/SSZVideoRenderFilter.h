//
//  SSZVideoRenderFilter.h
//  SimpleVideoFileFilter
//
//  Created by HaiboZhu on 2020/3/18.
//  Copyright © 2020 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "SSZOpenGLTools.h"
#import "SSZGPUFrameBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface SSZVideoRenderFilter : NSObject
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferInput;
@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, assign) CGAffineTransform affineTransform;
@property (nonatomic, assign) CATransform3D transform3D;
@property (nonatomic, assign) BOOL ignoreAspectRatio;
@property (nonatomic, strong) UIImage *bgImage;
@property (nonatomic, strong) UIImage *maskImage;
//@property (nonatomic, assign) SSZVideoRotationMode inputRotation;
@property (nonatomic, assign, readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;


- (CVPixelBufferRef)renderVideo:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
