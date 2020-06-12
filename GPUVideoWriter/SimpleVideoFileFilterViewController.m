#import "SimpleVideoFileFilterViewController.h"
#import "SSZAVAssetExportSession.h"
#import "SSZVideoRenderFilter.h"
#import <Photos/Photos.h>

@interface SimpleVideoFileFilterViewController ()

@property (nonatomic, strong) AVURLAsset *avAsset;
@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, strong) dispatch_queue_t inputQueue;
@property (nonatomic, strong) CIContext *context;
@property (nonatomic, assign) BOOL bUserCIImage;
@property (nonatomic, strong) UIImage *bgImage;
@property (nonatomic, strong) UIImage *waterMaskImage;
@property (nonatomic, assign) CGFloat angle;

@end


@implementation SimpleVideoFileFilterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}


- (void)viewDidLoad
{
    self.bgImage = [UIImage imageNamed:@"04.jpg"];
    self.waterMaskImage = [UIImage imageNamed:@"icon2.png"];
    self.videoSize = CGSizeMake(720, 1280);
//    self.videoSize = CGSizeMake(360, 640);
    [super viewDidLoad];
}

- (IBAction)btnPressed:(id)sender {
    
//    [self beginCImageWrite];
    if(0) {
        [self beginOpenglWrite];
//        [self beginOpenglWrite2];
    } else {
        [self beginMultiTrackOpenglWrite];
    }

}

- (void)beginCImageWrite {
    self.bUserCIImage = YES;
    _inputQueue = dispatch_queue_create("VideoEncoderInputQueue", DISPATCH_QUEUE_SERIAL);
    EAGLContext *storyEAGLContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    [options setObject:[NSNull null] forKey:kCIContextWorkingColorSpace];
    [options setObject:[NSNull null] forKey:kCIContextOutputColorSpace];
    self.context = [CIContext contextWithEAGLContext:storyEAGLContext options:options];
 
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"IMG3" withExtension:@"MOV"];
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToMovie]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToMovie error:nil];
    }
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    self.avAsset = [[AVURLAsset alloc] initWithURL:sampleURL options:nil];
    NSLog(@"%@", pathToMovie);
    
    SSZAVAssetExportSession *exporter = [[SSZAVAssetExportSession alloc] initWithAsset:self.avAsset];
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.outputURL = movieURL;
    exporter.videoSettings = [SimpleVideoFileFilterViewController videoSettings:self.videoSize];
    exporter.audioSettings = [SimpleVideoFileFilterViewController audioSettings];
    exporter.shouldPassThroughNatureSize = YES;
    NSDate *date = [NSDate date];
    NSLog(@"视频保存 开始");
    __weak typeof(self) weakself = self;
    exporter.exportProgressBlock = ^(CGFloat progress) {
    __strong typeof(self) strongSelf = weakself;
    dispatch_async(dispatch_get_main_queue(), ^{
        strongSelf.progressLabel.text = [NSString stringWithFormat:@"%d%%", (int)(progress * 100)];
    });
    };
    exporter.exportHandleSampleBufferBlock = ^BOOL(SSZAVAssetExportSession *exportSession, CMSampleBufferRef sampleBuffer, AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor) {
    __strong typeof(self) strongSelf = weakself;
    BOOL bRet = YES;
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferRef renderBuffer = NULL;
    CVPixelBufferPoolCreatePixelBuffer(NULL, videoPixelBufferAdaptor.pixelBufferPool, &renderBuffer);
    CIImage *inputImage = [CIImage imageWithCVImageBuffer:pixelBuffer];
    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform"];
    [filter setDefaults];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(M_PI_4)] forKey:kCIInputTransformKey];
    CIImage *outputImage = [filter valueForKey:kCIOutputImageKey];
    CIImage *res = outputImage;

    if (strongSelf.bgImage) {
      CIFilter *filter2 = [CIFilter filterWithName:@"CISourceOverCompositing"];
      [filter2 setValue:outputImage forKey:kCIInputImageKey];
      [filter2 setValue:strongSelf.bgImage forKey:kCIInputBackgroundImageKey];
      CIImage *outputImage2 = [filter2 valueForKey:kCIOutputImageKey];
      res = outputImage2;
    }
    if (strongSelf.waterMaskImage) {
      CIFilter *filter3 = [CIFilter filterWithName:@"CISourceOverCompositing"];
      [filter3 setValue:strongSelf.waterMaskImage forKey:kCIInputImageKey];
      [filter3 setValue:res forKey:kCIInputBackgroundImageKey];
      CIImage *outputImage3 = [filter3 valueForKey:kCIOutputImageKey];
      res = outputImage3;
    }
    [strongSelf.context render:res toCVPixelBuffer:renderBuffer];
    if (![videoPixelBufferAdaptor appendPixelBuffer:renderBuffer withPresentationTime:exportSession.lastSamplePresentationTime])
    {
      bRet = NO;
      NSLog(@"error 111");
    }
    CVPixelBufferRelease(renderBuffer);
    return bRet;
    };
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(SSZAVAssetExportSession *exportSession){
     if (exporter.error)  {
         NSLog(@"视频保存Asset失败：%@", exporter.error);
     }
    NSLog(@"视频保存 Asset cost time %f", [[NSDate date] timeIntervalSinceDate:date]);
    }];
   
}

- (void)beginOpenglWrite {
    self.bUserCIImage = NO;
  
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"IMG3" withExtension:@"MOV"];
//    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"hengping" withExtension:@"mp4"];
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToMovie]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToMovie error:nil];
    }
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    self.avAsset = [[AVURLAsset alloc] initWithURL:sampleURL options:nil];
    NSLog(@"%@", pathToMovie);
    
    SSZAVAssetExportSession *exporter = [[SSZAVAssetExportSession alloc] initWithAsset:self.avAsset];
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.outputURL = movieURL;
    exporter.videoSettings = [SimpleVideoFileFilterViewController videoSettings:self.videoSize];
    exporter.audioSettings = [SimpleVideoFileFilterViewController audioSettings];
    exporter.shouldPassThroughNatureSize = YES;
    self.angle = 45.0;
    NSDate *date = [NSDate date];
    NSLog(@"视频保存 开始");
    __weak typeof(self) weakself = self;
    exporter.exportProgressBlock = ^(CGFloat progress) {
        __strong typeof(self) strongSelf = weakself;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.progressLabel.text = [NSString stringWithFormat:@"%d%%", (int)(progress * 100)];
        });
    };
    exporter.exportHandleSampleBufferBlock = ^BOOL(SSZAVAssetExportSession *exportSession, CMSampleBufferRef sampleBuffer, AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor) {
         __strong typeof(self) strongSelf = weakself;
        exportSession.videoRenderFilter.bgImage = strongSelf.bgImage;
        exportSession.videoRenderFilter.maskImage = strongSelf.waterMaskImage;
        [exportSession.videoRenderFilter updateMaskImageFrame:CGRectMake(strongSelf.videoSize.width - 100, strongSelf.videoSize.height - 100, 50, 50)];
        CGAffineTransform transform = CGAffineTransformIdentity;

//        transform = CGAffineTransformTranslate(transform,   .0, 0.1 * strongSelf.videoSize.height/ (strongSelf.videoSize.width));
//        transform = CGAffineTransformScale(transform, 1.0, 0.8);
//        transform = CGAffineTransformRotate(transform, strongSelf.angle*2.0*M_PI/360.0);
        transform = CGAffineTransformScale(transform, 0.5, 0.5);
        transform = CGAffineTransformRotate(transform, 30*M_PI_2/180.0);
        
        strongSelf.angle += 3.0;
        if(strongSelf.angle > 360) {
            strongSelf.angle = 0.0;
        }
        exportSession.videoRenderFilter.affineTransform = transform;
        exportSession.videoRenderFilter.assetWriterPixelBufferInput = videoPixelBufferAdaptor;
        CVPixelBufferRef processedPixelBuffer = [exportSession.videoRenderFilter renderVideo:sampleBuffer];
        BOOL bRet = YES;
        if (![videoPixelBufferAdaptor appendPixelBuffer:processedPixelBuffer withPresentationTime:exportSession.lastSamplePresentationTime]) {
            bRet = NO;
            NSLog(@"error 2222");
        }
        return bRet;
    };

    [exporter exportAsynchronouslyWithCompletionHandler:^(SSZAVAssetExportSession *exportSession){
        if (exporter.error)  {
            NSLog(@"视频保存Asset失败：%@", exporter.error);
        }
       NSLog(@"视频保存 Asset cost time %f", [[NSDate date] timeIntervalSinceDate:date]);
        __block NSString *localIdentifier = nil;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^(void)
         {
            PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:movieURL];
            request.creationDate = [NSDate date];
            localIdentifier = request.placeholderForCreatedAsset.localIdentifier;
        }
        completionHandler:^(BOOL success, NSError *error)
         {
            dispatch_async(dispatch_get_main_queue(), ^(void)
                           {
                if (error != nil)
                {
                    NSLog(@"[SaveTask] save video failed! error: %@", error);
                }
        
                    NSLog(@"视频保存本地成功");
              
            });
        }];
        
    }];
   
}

- (void)beginOpenglWrite2 {
    self.bUserCIImage = NO;
    
//    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"IMG3" withExtension:@"MOV"];
        NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"hengping" withExtension:@"mp4"];
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie2.mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToMovie]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToMovie error:nil];
    }
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    self.avAsset = [[AVURLAsset alloc] initWithURL:sampleURL options:nil];
    NSLog(@"%@", pathToMovie);
    
    SSZAVAssetExportSession *exporter = [[SSZAVAssetExportSession alloc] initWithAsset:self.avAsset];
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.outputURL = movieURL;
    exporter.videoSettings = [SimpleVideoFileFilterViewController videoSettings:self.videoSize];
    exporter.audioSettings = [SimpleVideoFileFilterViewController audioSettings];
    exporter.shouldPassThroughNatureSize = YES;
    self.angle = 45.0;
    NSDate *date = [NSDate date];
    NSLog(@"视频保存 开始");
    __weak typeof(self) weakself = self;
    exporter.exportProgressBlock = ^(CGFloat progress) {
        __strong typeof(self) strongSelf = weakself;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.progressLabel.text = [NSString stringWithFormat:@"%d%%", (int)(progress * 100)];
        });
    };
    exporter.exportHandleSampleBufferBlock = ^BOOL(SSZAVAssetExportSession *exportSession, CMSampleBufferRef sampleBuffer, AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor) {
        __strong typeof(self) strongSelf = weakself;
        exportSession.videoRenderFilter.bgImage = strongSelf.bgImage;
        exportSession.videoRenderFilter.maskImage = strongSelf.waterMaskImage;
        [exportSession.videoRenderFilter updateMaskImageFrame:CGRectMake(strongSelf.videoSize.width - 100, strongSelf.videoSize.height - 100, 50, 50)];
        CGAffineTransform transform = CGAffineTransformIdentity;
        
        //        transform = CGAffineTransformTranslate(transform,   .0, 0.1 * strongSelf.videoSize.height/ (strongSelf.videoSize.width));
        //        transform = CGAffineTransformScale(transform, 1.0, 0.8);
        //        transform = CGAffineTransformRotate(transform, strongSelf.angle*2.0*M_PI/360.0);
        
        strongSelf.angle += 3.0;
        if(strongSelf.angle > 360) {
            strongSelf.angle = 0.0;
        }
        exportSession.videoRenderFilter.affineTransform = transform;
        exportSession.videoRenderFilter.assetWriterPixelBufferInput = videoPixelBufferAdaptor;
        CVPixelBufferRef processedPixelBuffer = [exportSession.videoRenderFilter renderVideo:sampleBuffer];
        BOOL bRet = YES;
        if (![videoPixelBufferAdaptor appendPixelBuffer:processedPixelBuffer withPresentationTime:exportSession.lastSamplePresentationTime]) {
            bRet = NO;
            NSLog(@"error 2222");
        }
        return bRet;
    };
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(SSZAVAssetExportSession *exportSession){
        if (exporter.error)  {
            NSLog(@"视频保存Asset失败：%@", exporter.error);
        }
        NSLog(@"视频保存 Asset cost time %f", [[NSDate date] timeIntervalSinceDate:date]);
        __block NSString *localIdentifier = nil;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^(void)
         {
            PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:movieURL];
            request.creationDate = [NSDate date];
            localIdentifier = request.placeholderForCreatedAsset.localIdentifier;
        }
                                          completionHandler:^(BOOL success, NSError *error)
         {
            dispatch_async(dispatch_get_main_queue(), ^(void)
                           {
                if (error != nil)
                {
                    NSLog(@"[SaveTask] save video failed! error: %@", error);
                }
                
                NSLog(@"视频保存本地成功");
                
            });
        }];
        
    }];
    
}

- (void)beginMultiTrackOpenglWrite {
    self.bUserCIImage = NO;
    
    
    
    NSURL *sampleURL1 = [[NSBundle mainBundle] URLForResource:@"douyin1" withExtension:@"mp4"];
    AVURLAsset *videoAsset1 = [[AVURLAsset alloc] initWithURL:sampleURL1 options:nil];
    NSURL *sampleURL2 = [[NSBundle mainBundle] URLForResource:@"douyin2" withExtension:@"mp4"];
    AVURLAsset *videoAsset2 = [[AVURLAsset alloc] initWithURL:sampleURL2 options:nil];
    NSURL *sampleURL3 = [[NSBundle mainBundle] URLForResource:@"hengping" withExtension:@"mp4"];
    AVURLAsset *videoAsset3 = [[AVURLAsset alloc] initWithURL:sampleURL3 options:nil];
    NSURL *sampleURL4 = [[NSBundle mainBundle] URLForResource:@"douyin3" withExtension:@"mp4"];
    AVURLAsset *videoAsset4 = [[AVURLAsset alloc] initWithURL:sampleURL4 options:nil];
//
////
//    NSURL *sampleURL1 = [[NSBundle mainBundle] URLForResource:@"douyin" withExtension:@"mp4"];
//    AVURLAsset *videoAsset1 = [[AVURLAsset alloc] initWithURL:sampleURL1 options:nil];
//    NSURL *sampleURL2 = [[NSBundle mainBundle] URLForResource:@"testvideo3" withExtension:@"mp4"];
//    AVURLAsset *videoAsset2 = [[AVURLAsset alloc] initWithURL:sampleURL2 options:nil];
//
    AVMutableComposition *compostion = [AVMutableComposition composition];
    NSMutableArray *multiArray = [NSMutableArray arrayWithCapacity:2];
    [multiArray addObject:videoAsset1];
    [multiArray addObject:videoAsset2];
    [multiArray addObject:videoAsset3];
    [multiArray addObject:videoAsset4];
    CMTime videoStarttime = kCMTimeZero;
    CMTime audioStarttime = kCMTimeZero;
    for (int i = 0; i < multiArray.count; i++) {
        AVURLAsset *sourceAsset = [multiArray objectAtIndex:i];
        AVAssetTrack *videoTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        AVAssetTrack *audioTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        AVMutableCompositionTrack *compositionVideoTrack = [compostion addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *compositionAudioTrack = [compostion addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        NSError *error = nil;
        CMTimeRange videoTimerange = videoTrack.timeRange;
        CMTimeRange audioTimerange = audioTrack.timeRange;
        
//        if(i == 0) {
//            videoTimerange  = CMTimeRangeMake(CMTimeMake(2.0 * 100, 100), CMTimeMake(8*100, 100));
//            audioTimerange  = CMTimeRangeMake(CMTimeMake(2.0 * 100, 100), CMTimeMake(8*100, 100));
//        } else if (i == 1) {
//            videoTimerange  = CMTimeRangeMake(CMTimeMake(5.0 * 100, 100), CMTimeMake(5*100, 100));
//            audioTimerange  = CMTimeRangeMake(CMTimeMake(5.0 * 100, 100), CMTimeMake(5*100, 100));
//            videoStarttime = CMTimeMake(8 * 100, 100);
//            audioStarttime = CMTimeMake(8 * 100, 100);

//        }
        [compositionVideoTrack insertTimeRange:videoTimerange ofTrack:videoTrack atTime:videoStarttime error:&error];
        [compositionAudioTrack insertTimeRange:audioTimerange ofTrack:audioTrack atTime:audioStarttime error:&error];
        videoStarttime = CMTimeAdd(videoStarttime, videoTimerange.duration);
        audioStarttime = CMTimeAdd(audioStarttime, audioTimerange.duration);
    }
    self.avAsset = compostion;
    
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToMovie]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToMovie error:nil];
    }
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
   
    
    
    NSLog(@"%@", pathToMovie);
    
    SSZAVAssetExportSession *exporter = [[SSZAVAssetExportSession alloc] initWithAsset:self.avAsset];
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.outputURL = movieURL;
    exporter.videoSettings = [SimpleVideoFileFilterViewController videoSettings:self.videoSize];
    exporter.audioSettings = [SimpleVideoFileFilterViewController audioSettings];
    exporter.shouldPassThroughNatureSize = YES;
    self.angle = 45.0;
    NSDate *date = [NSDate date];
    NSLog(@"视频保存 开始");
    __weak typeof(self) weakself = self;
    exporter.exportProgressBlock = ^(CGFloat progress) {
        __strong typeof(self) strongSelf = weakself;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.progressLabel.text = [NSString stringWithFormat:@"%d%%", (int)(progress * 100)];
        });
    };
    exporter.exportHandleSampleBufferBlock = ^BOOL(SSZAVAssetExportSession *exportSession, CMSampleBufferRef sampleBuffer, AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor) {
        __strong typeof(self) strongSelf = weakself;
        exportSession.videoRenderFilter.bgImage = strongSelf.bgImage;
        exportSession.videoRenderFilter.maskImage = strongSelf.waterMaskImage;
        [exportSession.videoRenderFilter updateMaskImageFrame:CGRectMake(strongSelf.videoSize.width - 100, strongSelf.videoSize.height - 100, 50, 50)];
        CGAffineTransform transform = CGAffineTransformIdentity;

        //        transform = CGAffineTransformTranslate(transform,   .0, 0.1 * strongSelf.videoSize.height/ (strongSelf.videoSize.width));
        //        transform = CGAffineTransformScale(transform, 1.0, 0.8);
        //        transform = CGAffineTransformRotate(transform, strongSelf.angle*2.0*M_PI/360.0);

        strongSelf.angle += 3.0;
        if(strongSelf.angle > 360) {
            strongSelf.angle = 0.0;
        }
        exportSession.videoRenderFilter.affineTransform = transform;
        exportSession.videoRenderFilter.assetWriterPixelBufferInput = videoPixelBufferAdaptor;
        CVPixelBufferRef processedPixelBuffer = [exportSession.videoRenderFilter renderVideo:sampleBuffer];
        BOOL bRet = YES;
        if (![videoPixelBufferAdaptor appendPixelBuffer:processedPixelBuffer withPresentationTime:exportSession.lastSamplePresentationTime]) {
            bRet = NO;
            NSLog(@"error 2222");
        }
        return bRet;
    };

    [exporter exportAsynchronouslyWithCompletionHandler:^(SSZAVAssetExportSession *exportSession){
        if (exporter.error)  {
            NSLog(@"视频保存Asset失败：%@", exporter.error);
        }
        NSLog(@"视频保存 Asset cost time %f", [[NSDate date] timeIntervalSinceDate:date]);
        __block NSString *localIdentifier = nil;
//        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^(void)
//         {
//            PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:movieURL];
//            request.creationDate = [NSDate date];
//            localIdentifier = request.placeholderForCreatedAsset.localIdentifier;
//        }
//                                          completionHandler:^(BOOL success, NSError *error)
//         {
//            dispatch_async(dispatch_get_main_queue(), ^(void)
//                           {
//                if (error != nil)
//                {
//                    NSLog(@"[SaveTask] save video failed! error: %@", error);
//                }
//
//                NSLog(@"视频保存本地成功");
//
//            });
//        }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self beginMultiTrackOpenglWrite];
        });
    }];
  
}


- (void)retrievingProgress
{
//    self.progressLabel.text = [NSString stringWithFormat:@"%d%%", (int)(movieFile.progress * 100)];
}

- (void)viewDidUnload
{
    [self setProgressLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)updatePixelWidth:(id)sender
{
//    [(GPUImageUnsharpMaskFilter *)filter setIntensity:[(UISlider *)sender value]];
//    [(GPUImagePixellateFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]];
}

+ (NSDictionary *)videoSettings:(CGSize)size
{
    //    NSInteger bitRate = fmin(size.width * size.height * 6.5f, 4194304); // 限制一下最大512kbps
    //    return @{
    //             AVVideoCodecKey: AVVideoCodecH264,
    //             AVVideoWidthKey: [NSNumber numberWithFloat:size.width],
    //             AVVideoHeightKey: [NSNumber numberWithFloat:size.height],
    //             AVVideoCompressionPropertiesKey: @
    //                 {
    //                 AVVideoAverageBitRateKey: @(bitRate),// @1960000,
    //                 AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel, // AVVideoProfileLevelH264Baseline31,
    //                 AVVideoMaxKeyFrameIntervalKey: @25,
    //                 },
    //             };
    NSDictionary *properties = @{ AVVideoAverageBitRateKey : @(1945748),
                                  AVVideoExpectedSourceFrameRateKey : @(30),
                                  AVVideoMaxKeyFrameIntervalKey : @(250),
                                  AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                                  AVVideoAllowFrameReorderingKey : @(NO)
                                  };
    NSDictionary *videoSettings = @{
                                    AVVideoCodecKey : AVVideoCodecH264,
                                    AVVideoWidthKey : @(size.width),
                                    AVVideoHeightKey : @(size.height),
                                    AVVideoCompressionPropertiesKey : properties
                                    };
    return videoSettings;
}

+ (NSDictionary *)audioSettings
{
    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    NSData *channelLayoutAsData = [NSData dataWithBytes:&acl length:sizeof(acl)];
    
    return @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
             AVSampleRateKey: @(48000),
             AVEncoderBitRateKey: @(128000),
             AVChannelLayoutKey: channelLayoutAsData,
             AVNumberOfChannelsKey: @(2)};
//    return @{
//             AVFormatIDKey: @(kAudioFormatMPEG4AAC),
//             AVNumberOfChannelsKey: @2,
//             AVSampleRateKey: @48000,
//             AVEncoderBitRateKey: @128000,
//             };
}

//视频格式
//使用Base Media version 2
+ (NSString *)outputFileType
{
    return AVFileTypeMPEG4;
}



@end
