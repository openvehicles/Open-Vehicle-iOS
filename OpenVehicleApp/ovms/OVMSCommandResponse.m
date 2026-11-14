#import "OVMSCommandResponse.h"

static NSString * const OVMSErrorDomain = @"com.openvehicles.ovms.protocol";

@interface OVMSCommandResponse ()
@property (nonatomic, readwrite) NSInteger command;
@property (nonatomic, readwrite) NSInteger resultCode;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *fields;
@property (nonatomic, copy, readwrite) NSString *payload;
@end

@implementation OVMSCommandResponse

+ (BOOL)parseInteger:(NSString *)text value:(NSInteger *)value
{
  if (text.length == 0) return NO;
  NSScanner *scanner=[NSScanner scannerWithString:text]; long long parsed=0;
  if (![scanner scanLongLong:&parsed] || !scanner.isAtEnd) return NO;
  if (value) *value=(NSInteger)parsed;
  return YES;
}

+ (instancetype)responseWithWireText:(NSString *)wireText error:(NSError **)error
{
  NSString *clean=[wireText stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  NSArray<NSString *> *fields=[clean componentsSeparatedByString:@","];
  NSInteger command=0,resultCode=0;
  if (fields.count < 2 || ![self parseInteger:fields[0] value:&command] || ![self parseInteger:fields[1] value:&resultCode])
    {
    if (error) *error=[NSError errorWithDomain:OVMSErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"Malformed OVMS command response"}];
    return nil;
    }
  OVMSCommandResponse *response=[[self alloc] init]; response.command=command; response.resultCode=resultCode; response.fields=fields;
  response.payload=fields.count>2?[[fields subarrayWithRange:NSMakeRange(2,fields.count-2)] componentsJoinedByString:@","]:@"";
  return response;
}

@end
