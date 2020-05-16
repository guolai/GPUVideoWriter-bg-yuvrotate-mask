

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomVideoCompositing : NSObject <AVVideoCompositing>

@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *sourcePixelBufferAttributes;
@property (nonatomic, strong) NSDictionary<NSString *, id> *requiredPixelBufferAttributesForRenderContext;

@end

NS_ASSUME_NONNULL_END
