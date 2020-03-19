#import "SimpleVideoFileFilterViewController.h"
#import "SSZAVAssetExportSession.h"
#import "SSZVideoRenderFilter.h"


@interface SimpleVideoFileFilterViewController ()

@property (nonatomic, strong) AVURLAsset *avAsset;
@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, strong) dispatch_queue_t inputQueue;
@property (nonatomic, strong) CIContext *context;
@property (nonatomic, assign) BOOL bUserCIImage;
@property (nonatomic, strong) UIImage *bgImage;
@property (nonatomic, strong) UIImage *waterMaskImage;

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
    [super viewDidLoad];
}

- (IBAction)btnPressed:(id)sender {
    
//    [self beginCImageWrite];
    [self beginOpenglWrite];
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
    
    SSZVideoRenderFilter *videoRenderFilter = [[SSZVideoRenderFilter alloc] init];
    videoRenderFilter.bgImage = self.bgImage;
    videoRenderFilter.maskImage = self.waterMaskImage;
    videoRenderFilter.videoSize = CGSizeMake(720, 1280);
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    transform = CGAffineTransformRotate(transform, 2);
    videoRenderFilter.affineTransform = transform;
    
    exporter.videoRenderFilter = videoRenderFilter;
    NSDate *date = [NSDate date];
    NSLog(@"视频保存 开始");
    __weak typeof(self) weakself = self;
    exporter.exportProgressBlock = ^(CGFloat progress) {
        __strong typeof(self) strongSelf = weakself;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.progressLabel.text = [NSString stringWithFormat:@"%d%%", (int)(progress * 100)];
        });
    };
//    exporter.exportHandleSampleBufferBlock = ^BOOL(SSZAVAssetExportSession *exportSession, CMSampleBufferRef sampleBuffer, AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor) {
//        exportSession.videoRenderFilter.assetWriterPixelBufferInput = videoPixelBufferAdaptor;
//        CVPixelBufferRef processedPixelBuffer = [exportSession.videoRenderFilter renderVideo:sampleBuffer];
//        BOOL bRet = YES;
//        if (![videoPixelBufferAdaptor appendPixelBuffer:processedPixelBuffer withPresentationTime:exportSession.lastSamplePresentationTime]) {
//            bRet = NO;
//            NSLog(@"error 2222");
//        }
//        return bRet;
//    };
    [exporter exportAsynchronouslyWithCompletionHandler:^(SSZAVAssetExportSession *exportSession){
        if (exporter.error)  {
            NSLog(@"视频保存Asset失败：%@", exporter.error);
        }
       NSLog(@"视频保存 Asset cost time %f", [[NSDate date] timeIntervalSinceDate:date]);
    }];
   
}




- (void)retrievingProgress
{
    self.progressLabel.text = [NSString stringWithFormat:@"%d%%", (int)(movieFile.progress * 100)];
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
    [(GPUImagePixellateFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]];
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
    NSDictionary *properties = @{ AVVideoAverageBitRateKey : @(1500*1024),
                                  AVVideoExpectedSourceFrameRateKey : @(30),
                                  AVVideoMaxKeyFrameIntervalKey : @(30),
                                  AVVideoProfileLevelKey: AVVideoProfileLevelH264High41,
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
    return @{
             AVFormatIDKey: @(kAudioFormatMPEG4AAC),
             AVNumberOfChannelsKey: @2,
             AVSampleRateKey: @44100,
             AVEncoderBitRateKey: @64000,
             };
}

//视频格式
//使用Base Media version 2
+ (NSString *)outputFileType
{
    return AVFileTypeMPEG4;
}




@end
