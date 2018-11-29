//
//  ZYNormalUpDateFile.m
//  标准文件上传
//
//  Created by Zy on 2018/11/29.
//  Copyright © 2018 360. All rights reserved.
//

#import "ZYNormalUpDateFile.h"
#import <UIKit/UIKit.h>

@interface ZYNormalUpDateFile ()<NSURLSessionDelegate,NSURLConnectionDelegate>

@end

@implementation ZYNormalUpDateFile

#pragma mark - 文件上传
- (void)uploadRequset:(NSDictionary *)info url:(NSString *)url completed:(ModelPresenterCallback)callback{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"multipart/form-data; boundary=QHADZYCREATUPLOAD" forHTTPHeaderField:@"Content-Type"];
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    // 拼接请求体
    NSMutableData *mudata = [NSMutableData data];
    [info enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            // 普通参数-username
            // 普通参数开始的一个标记
            [mudata appendData:[self stringData:@"--QHADZYCREATUPLOAD\r\n"]];
            // 参数描述
            [mudata appendData:[self stringData:[NSString stringWithFormat:@"Content-Disposition:form-data;name=\"%@\"\r\n",key]]];
            // 参数值
            [mudata appendData:[self stringData:[NSString stringWithFormat:@"\r\n%@\r\n",obj]]];
        }
        if ([obj isKindOfClass:[NSData class]]) {
            // 文件参数-file
            // 文件参数开始的一个标记
            [mudata appendData:[self stringData:@"--QHADZYCREATUPLOAD\r\n"]];
            // 文件参数描述
            [mudata appendData:[self stringData:[NSString stringWithFormat:@"Content-Disposition:form-data;name=\"%@\"\r\n;filename=\"%d.png\"\r\n",key,(int)[NSDate date].timeIntervalSince1970*1000]]];
            // 文件的MINETYPE
            [mudata appendData:[self stringData:@"Content-Type:image/png\r\n"]];
            // 文件内容
            [mudata appendData:[self stringData:@"\r\n"]];
            [mudata appendData:obj];
            [mudata appendData:[self stringData:@"\r\n"]];
            // 参数结束的标识
            [mudata appendData:[self stringData:@"--QHADZYCREATUPLOAD--"]];
        }
    }];
    
    [request setHTTPBody:mudata];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)mudata.length] forHTTPHeaderField:@"Content-Length"];
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 10;
    sessionConfiguration.allowsCellularAccess = YES;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[NSOperationQueue currentQueue]];
    NSURLSessionUploadTask *uploadtask = [session uploadTaskWithRequest:request fromData:mudata completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (callback) {
            NSDictionary *dic = nil;
            if(data.length){
                dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(dic?dic:nil);
            });
        }
        
    }];
    [uploadtask resume];
}
- (NSData *)stringData:(NSString *)string{
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}
- (NSString*)userAgent{
    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    return [webView stringByEvaluatingJavaScriptFromString:
            @"navigator.userAgent"];
}
#pragma mark - 证书校验
- (BOOL)myCustomValidation:(NSURLAuthenticationChallenge *)challenge{
if ([[[challenge protectionSpace] authenticationMethod] isEqualToString: NSURLAuthenticationMethodServerTrust]) {
    SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
    //            NSCAssert(serverTrust != nil, @"serverTrust is nil");
    if(nil == serverTrust)
        return NO; /* failed */
    /**
     *  导入多张CA证书（Certification Authority，支持SSL证书以及自签名的CA）
     */
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"multicrm360" ofType:@"cer"];//证书
    NSData* caCert = [NSData dataWithContentsOfFile:cerPath];
    
    if(nil == caCert)
        return NO; /* failed */
    
    SecCertificateRef caRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)caCert);
    if(nil == caRef)
        return NO; /* failed */
    
    NSArray *caArray = @[(__bridge id)(caRef)];
    
    if(nil == caArray)
        return NO; /* failed */
    
    OSStatus status = SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)caArray);
    // true 代表仅被传入的证书作为锚点，false 允许系统 CA 证书也作为锚点
    SecTrustSetAnchorCertificatesOnly(serverTrust, false);
    
    if(!(errSecSuccess == status))
        return NO; /* failed */
    
    
    return serverTrustIsVaild(serverTrust);
}
return NO;
}
static BOOL serverTrustIsVaild(SecTrustRef trust) {
    BOOL allowConnection = NO;
    // 假设验证结果是无效的
    SecTrustResultType trustResult = kSecTrustResultInvalid;
    // 函数的内部递归地从叶节点证书到根证书的验证
    OSStatus statue = SecTrustEvaluate(trust, &trustResult);
    if (statue == noErr) {
        // kSecTrustResultUnspecified: 系统隐式地信任这个证书
        // kSecTrustResultProceed: 用户加入自己的信任锚点，显式地告诉系统这个证书是值得信任的
        allowConnection = (trustResult == kSecTrustResultProceed
                           || trustResult == kSecTrustResultUnspecified);
    }
    return allowConnection;
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler
{
    // 如果使用默认的处置方式，那么 credential 就会被忽略
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    if ([challenge.protectionSpace.authenticationMethod
         isEqualToString:
         NSURLAuthenticationMethodServerTrust]) {
        
        /* 调用自定义的验证过程 */
        if ([self myCustomValidation:challenge]) {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            if (credential) {
                disposition = NSURLSessionAuthChallengeUseCredential;
            }
        } else {
            /* 无效的话，取消 */
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}
#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    
    if ([[[challenge protectionSpace] authenticationMethod] isEqualToString: NSURLAuthenticationMethodServerTrust]) {
        
        BOOL allowConnect = [self myCustomValidation:challenge];
        
        /* kSecTrustResultUnspecified and kSecTrustResultProceed are success */
        if(!allowConnect){
            return [[challenge sender] cancelAuthenticationChallenge: challenge]; /* failed */
        }else{
            return [[challenge sender] useCredential: [NSURLCredential credentialForTrust:[[challenge protectionSpace] serverTrust]]
                          forAuthenticationChallenge: challenge];
        }
    }
    // Bad dog
    return [[challenge sender] cancelAuthenticationChallenge: challenge];
}

@end
