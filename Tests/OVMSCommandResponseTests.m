#import <Foundation/Foundation.h>
#import "OVMSCommandResponse.h"

static void require(BOOL condition, NSString *message) { if (!condition) { NSLog(@"FAIL: %@",message); exit(1); } }

int main(int argc, const char *argv[])
{
  @autoreleasepool {
    require(argc==2,@"fixture path is required"); NSData *data=[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]]; require(data!=nil,@"fixture file must load");
    NSArray *fixtures=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]; require([fixtures isKindOfClass:[NSArray class]],@"fixtures must be an array");
    for(NSDictionary *fixture in fixtures){NSError *error=nil;OVMSCommandResponse *response=[OVMSCommandResponse responseWithWireText:fixture[@"wire"] error:&error];require(response!=nil,error.localizedDescription);require(response.command==[fixture[@"command"] integerValue],@"command mismatch");require(response.resultCode==[fixture[@"result"] integerValue],@"result mismatch");require([response.payload isEqualToString:fixture[@"payload"]],@"payload mismatch");}
    NSArray *invalid=@[@"",@"11",@"x,0",@"11,no",@",0"]; for(NSString *wire in invalid) require([OVMSCommandResponse responseWithWireText:wire error:nil]==nil,[NSString stringWithFormat:@"accepted malformed response: %@",wire]);
    NSLog(@"PASS: %lu command response fixtures and %lu malformed cases",(unsigned long)fixtures.count,(unsigned long)invalid.count);
  }
  return 0;
}
