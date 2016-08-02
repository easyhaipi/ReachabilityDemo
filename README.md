# ReachabilityDemo
iOS网络——检测手机网络状态Reachability
原文链接：http://www.jianshu.com/p/e96bfde21313

一、整体介绍
前面已经介绍了网络访问的NSURLSession、NSURLConnection，还有网页加载有关的webview，基本满足通常的网络相关的开发。
其实在网络开发中还有比较常用的就是网络状态的检测。苹果对需要联网的应用要求很高，就是必须要进行联网检查。另外，当网络发生异常时能够及时提示用户网络已断开，而不是程序问题造成卡顿；当用户观看视频或下载大文件时，提示用户当前的网络状态为移动流量或wifi下，是否继续使用，以避免在用户不知情下产生过多流量资费等等。

网络状态的检测有多种方法，常用的有三种

官方提供的Reachability下载苹果Reachability
AFNetworking附带提供的AFNetworkReachabilityManager，下载AFNetworking
专门的第三方框架，使用比较多的下载第三方框架
以上三种都有一个缺陷，会在本文最后给出解决方案
二、苹果Reachability使用
使用非常简单,将Reachability.h与Reachability.m加入项目中，在要使用的地方包含Reachability.h头文件，示例代码：

#import "Reachability.h"

/  //add network notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStateChange) name:kReachabilityChangedNotification object:nil];
    self.conn = [Reachability reachabilityForInternetConnection];
    [self.conn startNotifier];
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

/// 取消通知
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

三、AFNetworkReachabilityManager使用
直接使用
使用CocoaPods或者直接将AFNetwork下载并添加进项目。如果只是使用AFNetworkReachabilityManager而不适用其它网络功能则只将其.m和.h添加进项目即可。AFNetworkReachabilityManager使用了block的方式，当网络状态发生变化就会调用，且block的调用AFN已经将其限定在主线程下。下面介绍直接使用



#import "AFNetworkReachabilityManager.h"
- (void)afnReachabilityTest {
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

    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}
注：扩展，使用afn请求的时候。使用AFHTTPSessionManager
当使用AFN网络框架时，大多情况下，我们使用AFNetwork时会创建一个网络中间单例类，以防止换网络框架时要改动太多，比如替换之前用的多的ASI，如果有个中间类的话，替换就很简单，只需要修改中间类即可。使用时调用[NetworkTools sharedManager];即可
/// 头文件
#import "AFHTTPSessionManager.h"
@interface NetworkTools : AFHTTPSessionManager
+ (instancetype)sharedManager;
@end
/// .m文件
#import "NetworkTools.h"

@implementation NetworkTools
+ (instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        //#warning 基地址
        //        instance = [[self alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.bing.com"]];
        instance = [[self alloc] init];
    });
    return instance;
}
- (instancetype)init {
    if ((self = [super init])) {
        // 设置超时时间，afn默认是60s
        self.requestSerializer.timeoutInterval = 30;
        // 响应格式添加text/plain
        self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/plain", nil];

        // 监听网络状态,每当网络状态发生变化就会调用此block
        [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusNotReachable:     // 无连线
                    NSLog(@"AFNetworkReachability Not Reachable");
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN: // 手机自带网络
                    NSLog(@"AFNetworkReachability Reachable via WWAN");
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi: // WiFi
                    NSLog(@"AFNetworkReachability Reachable via WiFi");
                    break;
                case AFNetworkReachabilityStatusUnknown:          // 未知网络
                default:
                    NSLog(@"AFNetworkReachability Unknown");
                    break;
            }
        }];
        // 开始监听
        [self.reachabilityManager startMonitoring];
    }
    return self;
}
@end
四、第三方框架使用
这个使用会更方便一点，有block和通知两种方式，且支持多线程，这里不再详细介绍，README.md有使用方法：

- (void)viewDidLoad {
    [super viewDidLoad];
    // Allocate a reachability object
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.bing.com"];

    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach) {
        // keep in mind this is called on a background thread
        // and if you are updating the UI it needs to happen
        // on the main thread, like this:
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"REACHABLE!");
        });
    };

    reach.unreachableBlock = ^(Reachability*reach) {
        NSLog(@"UNREACHABLE!");
    };

    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}
问题解决
三种方式差不多，它们在检测设备是否连接局域网和连接方式时很灵敏，但是不能检测服务器是否可达。因为它们底层都是使用了SCNetworkReachability，SCNetworkReachability发送网络数据包到服务器，但它并不会确认服务器真的收到了此数据包。所以，如果我们想确认是否服务器可达，则需要发送一个真实的网络请求。或者我们使用socket编程，建立一个tcp链接来检测(三次握手成功)，只要链接成功则服务器可达。这样只会发送tcpip的报头，数据量最小。如果网络环境差，connect函数会阻塞(可以尝试select函数)，所以最后不要在主线程下，调用示例代码，示例如下：

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
