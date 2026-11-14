#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OVMSTelemetryFrame : NSObject
@property (nonatomic, readonly) char code;
@property (nonatomic, copy, readonly) NSString *payload;
@property (nonatomic, copy, readonly) NSArray<NSString *> *fields;
+ (nullable instancetype)frameWithDecryptedData:(NSData *)data error:(NSError **)error;
@end

@interface OVMSReconnectPolicy : NSObject
+ (NSTimeInterval)delayForConsecutiveFailureCount:(NSUInteger)failureCount;
@end

NS_ASSUME_NONNULL_END
