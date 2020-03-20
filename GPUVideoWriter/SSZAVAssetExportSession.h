//
//  SSZAVAssetExportSession.h
//  SimpleVideoFileFilter
//
//  Created by HaiboZhu on 2020/3/19.
//  Copyright © 2020 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SSZVideoRenderFilter.h"

@interface SSZAVAssetExportSession : NSObject
typedef void(^SSZAVAssetExportProgressBlock)(CGFloat progress);
typedef BOOL(^SSZAVAssetExportHandleSamplebufferBlock)(SSZAVAssetExportSession *exportSession, CMSampleBufferRef sampleBuffer, AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor);

@property (nonatomic, copy) SSZAVAssetExportProgressBlock exportProgressBlock;
@property (nonatomic, copy) SSZAVAssetExportHandleSamplebufferBlock exportHandleSampleBufferBlock;

@property (nonatomic, strong, readonly) AVAsset *asset;
@property (nonatomic, copy) AVVideoComposition *videoComposition;
@property (nonatomic, copy) AVAudioMix *audioMix;
@property (nonatomic, copy) NSString *outputFileType;
@property (nonatomic, copy) NSURL *outputURL;
@property (nonatomic, copy) NSDictionary *videoInputSettings;
@property (nonatomic, copy) NSDictionary *videoSettings;
@property (nonatomic, copy) NSDictionary *audioSettings;
@property (nonatomic, assign) CMTimeRange timeRange;
@property (nonatomic, assign) BOOL shouldOptimizeForNetworkUse;
@property (nonatomic, copy) NSArray *metadata;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, assign, readonly) float progress;
@property (nonatomic, assign, readonly) AVAssetExportSessionStatus status;
@property (nonatomic, strong, readonly) SSZVideoRenderFilter *videoRenderFilter;
@property (nonatomic, assign, readonly) CMTime lastSamplePresentationTime;
@property (nonatomic, assign, readonly) CGSize videoSize;


+ (id)exportSessionWithAsset:(AVAsset *)asset;
- (id)initWithAsset:(AVAsset *)asset;


- (void)exportAsynchronouslyWithCompletionHandler:(void (^)(SSZAVAssetExportSession *))handler;
- (void)cancelExport;
@end

