//
//  ViewController.m
//  ReachabilityDemo
//
//  Created by taobaichi on 16/8/2.
//  Copyright © 2016年 taobaichi. All rights reserved.
//

#import "ViewController.h"

#import "Reachability.h"

#import "AFNetworkReachabilityManager.h"

#import <arpa/inet.h>
@interface ViewController ()
{
      NSURL*  mSourceURL;
}
@property (nonatomic, strong) Reachability *conn;



- (IBAction)ReachabilityDemo:(UIButton *)sender;
- (IBAction)AFNetworkReachabilityManagerDemo:(UIButton *)sender;

- (IBAction)socketDemo:(UIButton *)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    mSourceURL = [NSURL URLWithString:@"www.baidu.com"];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)ReachabilityDemo:(UIButton *)sender {
    
    
    
    //add network notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStateChange) name:kReachabilityChangedNotification object:nil];
    self.conn = [Reachability reachabilityForInternetConnection];
    [self.conn startNotifier];
    
}

#pragma mark ----Reachability的网络监测
- (void)networkStateChange
{
    //网络流判断网络状态
    if (mSourceURL && ![mSourceURL isFileURL]) {
        [self checkNetworkState];
    }
}

- (void)checkNetworkState
{
    // 1.检测wifi状态
    Reachability *wifi = [Reachability reachabilityForLocalWiFi];
    
    // 2.检测手机是否能上网络(WIFI\3G\2.5G)
    Reachability *conn = [Reachability reachabilityForInternetConnection];
    
  
    
    // 3.判断网络状态
    // 两种检测:路由与服务器是否可达  三种状态:手机流量联网、WiFi联网、没有联网
    if ([wifi currentReachabilityStatus] == ReachableViaWiFi) { // 有wifi
        NSLog(@"有wifi");
        
    } else if ([conn currentReachabilityStatus] == ReachableViaWWAN) { // 没有使用wifi, 使用手机自带网络进行上网
        NSLog(@"使用手机自带网络进行上网");
    
        
    } else { // 没有网络
         [self performSelector:@selector(appReachabilityChangedConfirm) withObject:nil afterDelay:15];
        NSLog(@"没有网络");
    }

    
}

/// 再次检测网络，如果还是断开，则视为网络已经断开
- (void)appReachabilityChangedConfirm {
   
    
    // 2.检测手机是否能上网络(WIFI\3G\2.5G)
    Reachability *conn = [Reachability reachabilityForInternetConnection];
    
    if ([conn currentReachabilityStatus] == NotReachable) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"网络中断" message:@"请检查网络" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelBtn = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            UIAlertAction *okBtn = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:cancelBtn];
            [alert addAction:okBtn];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
 
    
    
}

#pragma mark ----AFNetworking 检查网络
- (IBAction)AFNetworkReachabilityManagerDemo:(UIButton *)sender {
    
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        // 一共有四种状态
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"AFNetworkReachability Not Reachable");
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                NSLog(@"AFNetworkReachability Reachable via WWAN");
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"AFNetworkReachability Reachable via WiFi");
                break;
            case AFNetworkReachabilityStatusUnknown:
            default:
                NSLog(@"AFNetworkReachability Unknown");
                break;
        }
    }];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
        [[NSRunLoop currentRunLoop] run];
    });
}

#pragma mark ----socket
- (IBAction)socketDemo:(UIButton *)sender {
    
    // socket编程，建立链接时，如果网络不好会阻塞程序，因此不要在主线程调用
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self socketReachabilityTest];
    });
}


/// 服务器可达返回true
- (BOOL)socketReachabilityTest {
    // 客户端 AF_INET:ipv4  SOCK_STREAM:TCP链接
    int socketNumber = socket(AF_INET, SOCK_STREAM, 0);
    
    // 配置服务器端套接字
    struct sockaddr_in serverAddress;
    // 设置服务器ipv4
    serverAddress.sin_family = AF_INET;
    // 百度的ip
    serverAddress.sin_addr.s_addr = inet_addr("202.108.22.5");
    // 设置端口号，HTTP默认80端口
    serverAddress.sin_port = htons(80);
    if (connect(socketNumber, (const struct sockaddr *)&serverAddress, sizeof(serverAddress)) == 0) {
        close(socketNumber);
        return true;
    }
    close(socketNumber);;
    return false;
}


/// 取消通知
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

@end
