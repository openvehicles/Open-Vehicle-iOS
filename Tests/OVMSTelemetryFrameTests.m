#import <Foundation/Foundation.h>
#import "OVMSTelemetryFrame.h"

static void require(BOOL condition,NSString *message){if(!condition){NSLog(@"FAIL: %@",message);exit(1);}}
int main(int argc,const char *argv[]){@autoreleasepool{
  require(argc==2,@"fixture path is required");NSData *json=[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];NSArray *fixtures=[NSJSONSerialization JSONObjectWithData:json options:0 error:nil];require(fixtures.count>0,@"fixtures must load");
  for(NSDictionary *fixture in fixtures){NSData *wire=[fixture[@"wire"] dataUsingEncoding:NSUTF8StringEncoding];NSError *error=nil;OVMSTelemetryFrame *frame=[OVMSTelemetryFrame frameWithDecryptedData:wire error:&error];require(frame!=nil,error.localizedDescription);require(frame.code==[fixture[@"code"] characterAtIndex:0],@"code mismatch");require(frame.fields.count==[fixture[@"fields"] unsignedIntegerValue],@"field count mismatch");}
  for(NSString *wire in @[@"",@"MP-0",@"MP-1 S50,K",@"not a packet"])require([OVMSTelemetryFrame frameWithDecryptedData:[wire dataUsingEncoding:NSUTF8StringEncoding] error:nil]==nil,@"malformed frame accepted");
  NSArray *expected=@[@2,@5,@10,@20,@40,@60,@60];for(NSUInteger i=0;i<expected.count;i++)require([OVMSReconnectPolicy delayForConsecutiveFailureCount:i+1]==[expected[i] doubleValue],@"reconnect delay mismatch");
  NSLog(@"PASS: telemetry envelopes and bounded reconnect backoff");
}return 0;}
