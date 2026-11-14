#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OVMSCommandResponse : NSObject
@property (nonatomic, readonly) NSInteger command;
@property (nonatomic, readonly) NSInteger resultCode;
@property (nonatomic, copy, readonly) NSArray<NSString *> *fields;
@property (nonatomic, copy, readonly) NSString *payload;
+ (nullable instancetype)responseWithWireText:(NSString *)wireText error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
