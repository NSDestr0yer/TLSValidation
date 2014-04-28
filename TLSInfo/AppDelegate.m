//
//  AppDelegate.m
//  TLSInfo
//
//  Created by Collin B Stuart on 2014-04-28.
//  Copyright (c) 2014 CollinBStuart. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

void ParseResponse(CFHTTPMessageRef response, SecTrustRef trust)
{
    SecTrustResultType trustResult;
    
    if ((errSecSuccess == SecTrustEvaluate(trust, &trustResult)) && (trustResult == kSecTrustResultUnspecified))
    {
        CFShow(CFSTR("Evaluate Succeeded!"));
    }
    else
    {
        CFShow(CFSTR("Evaluate Failed."));
    }
    
    if (trust)
    {
        CFRelease(trust);
    }
    if (response)
    {
        CFRelease(response);
    }
}

static void ReadStreamCallBack(CFReadStreamRef readStream, CFStreamEventType type, void *clientCallBackInfo)
{
    
    //append data as we receive it
    CFMutableDataRef responseBytes = CFDataCreateMutable(kCFAllocatorDefault, 0);
    CFIndex numberOfBytesRead = 0;
    do
    {
        UInt8 buf[1024];
        numberOfBytesRead = CFReadStreamRead(readStream, buf, sizeof(buf));
        if (numberOfBytesRead > 0)
        {
            CFDataAppendBytes(responseBytes, buf, numberOfBytesRead);
        }
    } while (numberOfBytesRead > 0);
    
    //package appended data into a response object
    CFHTTPMessageRef response = (CFHTTPMessageRef)CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPResponseHeader);
    
    if (responseBytes)
    {
        if (response)
        {
            CFHTTPMessageSetBody(response, responseBytes);
        }
        CFRelease(responseBytes);
    }
    
    SecTrustRef trust = NULL;
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    CFArrayRef sslArray = CFReadStreamCopyProperty(readStream, kCFStreamPropertySSLPeerCertificates);
    
    CFShow(CFSTR("SSL Array:"));
    CFShow(sslArray);
    
    if (sslArray)
    {
        if (CFArrayGetCount(sslArray))
        {
            SecTrustCreateWithCertificates(sslArray, policy, &trust);
            CFShow(CFSTR("\nPolicy is:"));
            CFShow(policy);
        }
        CFRelease(sslArray);
    }
    CFRelease(policy);
	
    //close and cleanup
    CFReadStreamClose(readStream);
    CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFRelease(readStream);
    
    ParseResponse(response, trust);
}

void TLSRequest()
{
    CFURLRef theURL = CFURLCreateWithString(kCFAllocatorDefault, CFSTR("https://httpbin.org"), NULL);
    CFHTTPMessageRef requestMessage = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("GET"), theURL, kCFHTTPVersion1_1);
    CFRelease(theURL);
    
    CFReadStreamRef readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, requestMessage);
    CFRelease(requestMessage);
    
    CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
    CFOptionFlags flags = (kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered);
    CFStreamClientContext context = {0, NULL, NULL, NULL, NULL};
    CFReadStreamSetClient(readStream, flags, ReadStreamCallBack, &context);
    CFReadStreamOpen(readStream);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    TLSRequest();
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
