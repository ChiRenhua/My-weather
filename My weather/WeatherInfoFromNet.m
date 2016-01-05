//
//  NSObject+WeatherInfoFromNet.m
//  My weather
//
//  Created by Martin on 15/12/2.
//  Copyright © 2015年 Martin. All rights reserved.
//

#import "WeatherInfoFromNet.h"
#define WEATHER_URL @"http://wthrcdn.etouch.cn/WeatherApi?citykey="

@implementation WeatherInfoFromNet{
    NSMutableData *weatherData;
    WeatherInfoModel *wim;
}

- (id)init{
    if (self = [super init]) {
        //一些初始化可以放到这里
        
        
    }
    return self;
}

- (void)getWeatherInfoFromNetWithCityCode:(NSString *)cityCode model:(WeatherInfoModel *)model{
    weatherData = [[NSMutableData alloc]init];
    wim = model;
    NSString *URLString = [WEATHER_URL stringByAppendingString:cityCode];
    NSURL * URL = [NSURL URLWithString:[URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest * request = [[NSURLRequest alloc]initWithURL:URL];
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
}

// 数据全部获取完成后回调，有点延迟
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //  解析获取到的天气数据
    [wim parserXML:weatherData];
}

// 接受到数据时调用，完整的数据可能拆分为多个包发送，每次接受到数据片段都会调用这个方法，所以可以用一个全局的NSMutableData对象，用来把每次的数据拼接在一起。
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [weatherData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    _errorBlock(@"网络错误",@"无法连接到服务器");
}

@end
