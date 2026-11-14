#import "OVMSTelemetryFrame.h"

static NSString * const OVMSTelemetryErrorDomain=@"com.openvehicles.ovms.telemetry";

@interface OVMSTelemetryFrame ()
@property (nonatomic, readwrite) char code;
@property (nonatomic, copy, readwrite) NSString *payload;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *fields;
@end

@implementation OVMSTelemetryFrame
+ (instancetype)frameWithDecryptedData:(NSData *)data error:(NSError **)error
{
  NSString *wire=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  if (!wire || wire.length<6 || ![wire hasPrefix:@"MP-0 "])
    {
    if(error)*error=[NSError errorWithDomain:OVMSTelemetryErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"Malformed OVMS telemetry envelope"}]; return nil;
    }
  unichar code=[wire characterAtIndex:5]; if(code>127){if(error)*error=[NSError errorWithDomain:OVMSTelemetryErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey:@"Invalid OVMS telemetry code"}];return nil;}
  OVMSTelemetryFrame *frame=[[self alloc] init]; frame.code=(char)code; frame.payload=[wire substringFromIndex:6]; frame.fields=[frame.payload componentsSeparatedByString:@","]; return frame;
}
@end

@implementation OVMSReconnectPolicy
+ (NSTimeInterval)delayForConsecutiveFailureCount:(NSUInteger)failureCount
{
  static const NSTimeInterval delays[]={2,5,10,20,40,60}; NSUInteger index=failureCount>0?failureCount-1:0; return delays[MIN(index,(NSUInteger)5)];
}
@end
