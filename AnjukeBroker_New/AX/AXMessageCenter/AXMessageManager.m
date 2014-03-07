//
//  AIFMessageManager.m
//  AVDemo
//
//  Created by 孟 智 on 1/22/14.
//  Copyright (c) 2014 孟 智. All rights reserved.
//

#import "AXMessageManager.h"
static NSString *kAIFMessageRegisteToServerUri = @"/register"; //eg. GET /register/{deviceId}/{userId}/
static NSString *kAIFMessageConnectToHeartBeatServerUri = @"/ping"; //eg. GET /ping/{deviceId}/{userId}/
static NSString *kAIFMessageStopAlivingConnectionUri = @"/quit"; //eg. GET /quit/{deviceId}/{userId}/


static NSString *kAIFMessagePushMessageByUidUri = @"/sendMessageByUid"; //eg. POST /sendMessageByUid/{userId}   {body}
static NSString *kAIFMessagePushMessageByDeviceIdUri = @"/sendMessageByDeviceId"; //eg. POST /sendMessageByDeviceId/{deviceId} {body}
NSTimeInterval const kAIFRegisteDefaultConnectionRetryTimeout = 10;

@interface AXMessageManager ()
@property (nonatomic,strong) NSString *deviceId;
@property (nonatomic,strong) NSString *userId;
@property (nonatomic,strong) NSString *host;
@property (nonatomic,strong) NSString *port;
@property (nonatomic,strong) NSString *appName;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic,strong) ASIHTTPRequest *registerRequest;
@property (nonatomic,strong) ASIHTTPRequest *heartBeatRequest;
@property (nonatomic,strong) ASIHTTPRequest *cancelAlivingConnection;
@property (nonatomic,strong) ASIFormDataRequest *pushRequest;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic, strong) NSString *machineName;
@property (nonatomic, strong) NSString *startTime;
@property (nonatomic) BOOL isFirstPONG;
@property (nonatomic) BOOL shouldSendHeartPong;
@property (nonatomic) NSInteger tryCount;

@end

@implementation AXMessageManager

- (id)init
{
    self = [super init];
    if (self) {
        self.isFirstPONG = YES;
        self.shouldSendHeartPong = YES;
    }
    return self;
}

- (void)dealloc
{
    [self.timer invalidate];
}
- (void)bindServerHost:(NSString *)host port:(NSString *)port appName:(NSString *)appName timeout:(NSTimeInterval)timeout
{
    self.host = host;
    self.port = port;
    self.appName = appName;
    self.timeout = timeout;
    self.tryCount = 0;
}

- (void)cancelKeepAlivingConnection
{
    NSString *cancelUrl = [NSString stringWithFormat:@"https://%@:%@%@/%@/%@/%@",self.host,self.port,kAIFMessageStopAlivingConnectionUri,self.deviceId,self.appName, self.userId];
    DLog(@"CANACLE URL IS ====== %@",cancelUrl);
    self.cancelAlivingConnection = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:cancelUrl]];
    [self.cancelAlivingConnection setValidatesSecureCertificate:NO];
    self.cancelAlivingConnection.delegate = self;
    self.cancelAlivingConnection.tag = AIF_MESSAGE_REQUEST_TYPE_TAG_CANCEL_ALIVING_CONNECTION;
    [self.cancelAlivingConnection startAsynchronous];
    
}

- (void)registerDevices:(NSString *)deviceId userId:(NSString *)userId
{
    if (self.registerStatus == AIF_MESSAGE_REQUEST_REGISTER_STARTED) {
        //        NSLog(@"AIF_MESSAGE_REQUEST_REGISTER_STARTED");
        return;
    }
    
    self.deviceId = deviceId;
    self.userId = userId;
    
    NSString *registerUrlString = [NSString stringWithFormat:@"https://%@:%@%@/%@/%@/%@/",self.host,self.port,kAIFMessageRegisteToServerUri,self.deviceId,self.appName,self.userId];
    NSURL *registerUrl = [NSURL URLWithString:registerUrlString];
    NSLog(@"registerUrl is %@", registerUrl);
    self.registerRequest = [ASIHTTPRequest requestWithURL:registerUrl];
    self.registerRequest.tag = AIF_MESSAGE_REQUEST_TYPE_TAG_REGISTER;
    [self.registerRequest setValidatesSecureCertificate:NO];
    self.registerRequest.delegate = self;
    self.registerRequest.timeOutSeconds = self.timeout;
    [self.registerRequest startAsynchronous];
}

- (void)heartBeatWithDevices
{
    NSString *heartBeatUrlString = [NSString stringWithFormat:@"https://%@:%@%@/%@/%@/%@",self.host,self.port,kAIFMessageConnectToHeartBeatServerUri,self.deviceId,self.appName,self.userId];
    //    NSLog(@"[%@ %@]:%@ => %@ ",NSStringFromClass([self class]),NSStringFromSelector(_cmd),@"heartBeatUrlString",heartBeatUrlString);
    NSURL *heartBeatUrl = [NSURL URLWithString:heartBeatUrlString];
    self.heartBeatRequest = [ASIHTTPRequest requestWithURL:heartBeatUrl];
    self.heartBeatRequest.delegate = self;
    [self.heartBeatRequest setValidatesSecureCertificate:NO];
    self.heartBeatRequest.tag = AIF_MESSAGE_REQUEST_TYPE_TAG_HEARTBEAT;
    [self.heartBeatRequest startAsynchronous];
}


- (void)heartBeatWithDevices:(NSString *)deviceId userId:(NSString *)userId
{
    
    NSString *heartBeatUrlString = [NSString stringWithFormat:@"https://%@:%@%@/%@/%@/%@",self.host,self.port,kAIFMessageConnectToHeartBeatServerUri,self.deviceId,self.appName,self.userId];
    //    NSLog(@"[%@ %@]:%@ => %@ ",NSStringFromClass([self class]),NSStringFromSelector(_cmd),@"heartBeatUrlString",heartBeatUrlString);
    NSURL *heartBeatUrl = [NSURL URLWithString:heartBeatUrlString];
    self.heartBeatRequest = [ASIHTTPRequest requestWithURL:heartBeatUrl];
    self.heartBeatRequest.delegate = self;
    [self.heartBeatRequest setValidatesSecureCertificate:NO];
    self.heartBeatRequest.tag = AIF_MESSAGE_REQUEST_TYPE_TAG_HEARTBEAT;
    [self.heartBeatRequest startAsynchronous];
}

- (void)sendMessageToUid:(NSString *)uid message:(NSString *)message
{
    if ([uid isEqualToString:@""]) {
        uid = @"0";
    }
    NSString *sendMessageUrlString = [NSString stringWithFormat:@"https://%@:%@%@/%@",self.host,self.port,kAIFMessagePushMessageByUidUri,uid];
    NSURL *sendMessageUrl = [NSURL URLWithString:sendMessageUrlString];
    self.pushRequest = [ASIFormDataRequest requestWithURL:sendMessageUrl];
    self.pushRequest.delegate = self;
    self.pushRequest.tag = AIF_MESSAGE_REQUEST_TYPE_TAG_PUSHING;
    [self.pushRequest setValidatesSecureCertificate:NO];
    [self.pushRequest setPostValue:message forKey:@"message"];
    [self.pushRequest startAsynchronous];
}

- (void)sendMessageToDeviceId:(NSString *)deviceId
{
    
}

- (void)cancelRegisterRequest
{
    [self.registerRequest cancel];
}

- (void)cancelPerformRequests
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Private Method
- (void)registerRequestRestart
{
    [self.registerRequest cancel];
    [self registerDevices:self.deviceId userId:self.userId];
}

- (NSInteger)calSleepTime
{
    if (self.tryCount && self.tryCount > 0) {
        return (NSInteger) pow(2, self.tryCount % 8 + 1);
    } else {
        self.tryCount = 0;
        return 0;
    }
}

- (void)resetHeartBeatParams
{
    [self.timer invalidate];
    self.isFirstPONG = YES;
    self.shouldSendHeartPong = YES;
}
#pragma mark - ASIHTTPRequestDelegate Methods
- (void)request:(ASIHTTPRequest *)request didReceiveData:(NSData *)data
{
    if (request.tag == AIF_MESSAGE_REQUEST_TYPE_TAG_REGISTER) {
        self.tryCount = 0;
        if ([self.delegate respondsToSelector:@selector(manager:didRegisterDevice:userId:receivedData:)]) {
            [self.delegate manager:self didRegisterDevice:self.deviceId userId:self.userId receivedData:data];
            if (self.shouldSendHeartPong) {
                self.timer = [NSTimer scheduledTimerWithTimeInterval:300.0f target:self selector:@selector(heartBeatWithDevices) userInfo:nil repeats:YES];
                self.shouldSendHeartPong = NO;
            }
            __autoreleasing NSError *error;
            NSDictionary *receiveDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (receiveDic[@"result"] && receiveDic[@"status"] && receiveDic[@"serverInfo"] && receiveDic[@"serverInfo"][@"machineName"] && receiveDic[@"serverInfo"][@"startTime"]) {
                NSString *mechine = [NSString stringWithFormat:@"%@",receiveDic[@"serverInfo"][@"machineName"]];
                NSString *time = [NSString stringWithFormat:@"%@",receiveDic[@"serverInfo"][@"startTime"]];
                if (self.isFirstPONG) {
                    self.machineName = mechine;
                    self.startTime = time;
                    self.isFirstPONG = NO;
                }
                if (![self.machineName isEqualToString:mechine] || ![self.startTime isEqualToString:time]) {
                    self.machineName = mechine;
                    self.startTime = time;
                    [self cancelRegisterRequest];
                }
            }
        } else {
        }
    }
    
    if(request.tag == AIF_MESSAGE_REQUEST_TYPE_TAG_HEARTBEAT) {
        //In this brace, we can do some expose delegate method
        if ([self.delegate respondsToSelector:@selector(manager:didHeartBeatWithDevice:userId:receivedData:)]) {
            [self.delegate manager:self didHeartBeatWithDevice:self.deviceId userId:self.userId receivedData:data];
        } else {
        }
        
    }
    
    if(request.tag == AIF_MESSAGE_REQUEST_TYPE_TAG_PUSHING) {
    }
    
    if (request.tag == AIF_MESSAGE_REQUEST_TYPE_TAG_CANCEL_ALIVING_CONNECTION) {
        NSLog(@"CANCLE IS SUCCESS AND FOR ALIVING CONNECTION !!!");
    }
}

- (void)requestStarted:(ASIHTTPRequest *)request
{
    if (request.tag == AIF_MESSAGE_REQUEST_TYPE_TAG_REGISTER) {
        self.registerStatus = AIF_MESSAGE_REQUEST_REGISTER_STARTED;
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    if (request.tag == AIF_MESSAGE_REQUEST_TYPE_TAG_REGISTER) {
        self.registerStatus = AIF_MESSAGE_REQUEST_REGISTER_FINISHED;
        [self resetHeartBeatParams];
    }
    
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    if (request.tag == AIF_MESSAGE_REQUEST_TYPE_TAG_REGISTER) {
        self.registerStatus = AIF_MESSAGE_REQUEST_REGISTER_FAILED;
        [self resetHeartBeatParams];
        if (self.isLinking) {
            [self performSelector:@selector(didRegisterRequestRetry) withObject:nil afterDelay:[self calSleepTime]];
            self.tryCount = self.tryCount + 1;
        }
    }
}

#pragma mark - performSelector
- (void)didRegisterRequestRetry
{
    [self registerDevices:self.deviceId userId:self.userId];
}

@end
