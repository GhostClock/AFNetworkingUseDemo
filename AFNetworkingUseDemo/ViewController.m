//
//  ViewController.m
//  AFNetworkingUseDemo
//
//  Created by mac on 15/5/20.
//  Copyright (c) 2015年 zhang jian. All rights reserved.
//

#import "ViewController.h"

#import "AFNetworking.h"
#import "UIKit+AFNetworking.h"

@interface ViewController (){
    NSProgress * _progress;
    UIProgressView * _progressView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    //<1>GET请求
    //[self testGetRequest];
    
    //<2>POST请求
    //[self testPostRequest];
    
    //<3>POST文件上传
    //[self testUploadFile];
    
    //<4>文件下载
    //[self testDownloadFile];
    
    //<6>网络状态的检测
    [self testNetworkStatus];
    
    //<7>图片异步加载
    //  SDWebImage  UIImageView+setImageWithURL
    
    //  #import "UIKit+AFNetworking.h"
    //                  UIImageView+setImageWithURL
    
}
-(void)testNetworkStatus
{
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"www.baidu.com"]];
    //给manager设置一个网络状态改变时执行的block
    [manager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        //4种网络状态, Unknown, NotReachable, ReachableViaWWAN,ReachableViaWiFi
        NSDictionary *dict = @{@(-1):@"未知",
                               @(0):@"不可达",
                               @(1):@"蜂窝网络",
                               @(2):@"无线"};
        NSLog(@"当前网络状态是 %@",dict[@(status)]);
    }];
    //开启网络状态监控
    [manager.reachabilityManager startMonitoring];
    
}
-(void)testDownloadFile
{
    NSString *urlString = @"http://a3.pc6.com/hw1/zhihu.pc6.apk";
    
    //AFURLSessionManager
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    //获取下载任务, 默认不会自动启动
    //参数1: 下载请求
    //参数2: 下载进度
    //参数3: 下载后文件地址
    NSString *path = [NSString stringWithFormat:@"%@/Documents/zhihu.apk",NSHomeDirectory()];
    NSProgress * progress =nil;
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        NSLog(@"下载完成, 地址是%@",path);
        
    }];
    //监控progress进度对象中fractionCompleted属性
    //效果:当fractionComleted属性从旧值变为新值，执行self中指定的方法
    [progress addObserver:self forKeyPath:@"fractionComleted"options:NSKeyValueObservingOptionOld context:nil];
    //启动真正的下载过程
    [task resume];
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(10, 40, 300, 20)];
    [self.view addSubview:_progressView];
}
//意义：object中keyPath发生改变了，详细信息在change字典中
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    //获取到改变的值
    double fractionCompleted = [[object valueForKeyPath:keyPath] doubleValue];
    NSLog(@"fractionCompleted = %.2f%%",fractionCompleted * 100);
    //注意1：不需要监听的时候必须取消监听
    _progress= object;
    
    //注意2；KVO的监听的事件处理方法在子线程中执行，修改UI回到主线程执行
    dispatch_async(dispatch_get_main_queue(), ^{
        _progressView.progress = fractionCompleted;
    });
}
-(void)dealloc{
    //取消监听
    [_progress removeObserver:self forKeyPath:@"fractionCompleted"];
    
}
-(void)testUploadFile
{
    NSString *urlString = @"http://quiet.local/posttest/upload.php";
    //数据1:	image
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:urlString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        //告诉AF要上传那个文件
        NSString *path = [[NSBundle mainBundle] pathForResource:@"iRing.jpg" ofType:nil];
        //参数1: 上传文件的地址
        //参数2: 接口中规定的参数名
        //参数3: 上传到服务器上得名字
        //参数4: 文件类型, jpeg图片image/jpeg, png图片image/png
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:path] name:@"image" fileName:@"iRing.jpg" mimeType:@"image/jpeg" error:nil];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *string = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"string = %@",string);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    
    
    
    
}
-(void)testPostRequest
{
    NSString *urlString = @"http://quiet.local/posttest/login.php";
    //数据1:	user
    //数据2:	password
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    //发起POST请求
    [manager POST:urlString parameters:@{@"user":@"quiet",@"password":@"123"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *string = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"string = %@",string);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    
}
-(void)testGetRequest
{
    NSString *urlString = @"http://www.baidu.com";
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    // Code=-1016 "Request failed: unacceptable content-type: text/html"
    //注意: 默认情况认为返回的是json数据, 并且响应头里面内容类型是
    //  application/json
    //  加上下面这句, 返回数据直接就是二进制数据NSData
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:urlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *string = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"string = %@",string);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error = %@",error);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
