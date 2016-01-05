//
//  NSObject+WeatherInfoModel.m
//  My weather
//
//  Created by Martin on 15/12/2.
//  Copyright © 2015年 Martin. All rights reserved.
//

#import "WeatherInfoModel.h"

@implementation WeatherInfoModel
NSDictionary *weatherDicrionary;


- (id)init{
    if (self = [super init]) {
        weatherDicrionary = [[NSDictionary alloc]init];
    }
    return self;
}


// 读取WeatherInfo中的内容，将其转化成字典，然后通过键值对来找到对应的城市code
- (NSString *)translateCityNameToCityCode:(NSString *) cityName cityDetialName:(NSString *)cityDetialName{
    cityDetialName = [cityDetialName substringToIndex:[cityDetialName length]-1];
    cityName = [cityName substringToIndex:[cityName length]-1];
    NSString *plistPath = [[NSBundle mainBundle]pathForResource:@"WeatherInfo" ofType:@"plist"];
    NSMutableDictionary *cityCodeData = [[NSMutableDictionary alloc]initWithContentsOfFile:plistPath];
    NSString * cityCode = [cityCodeData objectForKey:cityDetialName];
    if (!cityCode) {
        cityCode = [cityCodeData objectForKey:cityName];
    }
    return cityCode;
}

// 解析获取到的天气信息
- (void)parserXML:(NSMutableData *)data{
    if (data.length) {
        NSMutableDictionary *weatherInfoNow = [[NSMutableDictionary alloc]init];                // 当天的天气信息
        weatherDicrionary = [NSDictionary dictionaryWithXMLData:data];
        NSString *temperature = [weatherDicrionary objectForKey:@"wendu"];
        NSString *fengli = [weatherDicrionary objectForKey:@"fengli"];
        NSString *shidu = [weatherDicrionary objectForKey:@"shidu"];
        NSString *fengxiang = [weatherDicrionary objectForKey:@"fengxiang"];
        NSString *sunRise = [weatherDicrionary objectForKey:@"sunrise_1"];
        NSString *sunset = [weatherDicrionary objectForKey:@"sunset_1"];
        [weatherInfoNow setValue:temperature forKey:@"wendu"];
        [weatherInfoNow setValue:fengli forKey:@"fengli"];
        [weatherInfoNow setValue:shidu forKey:@"shidu"];
        [weatherInfoNow setValue:fengxiang forKey:@"fengxiang"];
        [weatherInfoNow setValue:sunRise forKey:@"sunrise"];
        [weatherInfoNow setValue:sunset forKey:@"sunset"];
        
        
//        判断是否是夜晚
        NSString *timeNow = [self getCurrentTime];
        int timeNowHour = [[timeNow substringToIndex:2] intValue];
        int timeNowMinuts = [[timeNow substringFromIndex:3] intValue];
        int sunRiseHour = [[sunRise substringToIndex:2] intValue];
        int sunRiseMinuts = [[sunRise substringFromIndex:3] intValue];
        int sunsetHour = [[sunset substringToIndex:2] intValue];
        int sunsetMinuts = [[sunset substringFromIndex:3] intValue];
        NSString * dayOrNight;
        
        int a = (timeNowHour * 60 + timeNowMinuts) - (sunsetHour * 60 + sunsetMinuts);
        int b = (timeNowHour * 60 + timeNowMinuts) - (sunRiseHour * 60 + sunRiseMinuts);
        if ((a > 0) || (b < 0)) {
            dayOrNight = @"night";
        }else{
            dayOrNight = @"day";
        }
        [weatherInfoNow setValue:dayOrNight forKey:@"dayOrNight"];
        
        
        
        NSDictionary *environment = [weatherDicrionary objectForKey:@"environment"];
        NSMutableArray *recentWeather = [[weatherDicrionary objectForKey:@"forecast"]objectForKey:@"weather"];
        NSLog(@"temperature:%@,%@,%@,%@,%@,%@,%@",temperature,fengli,shidu,fengxiang,sunRise,sunset,[[recentWeather[0] objectForKey:@"night"] objectForKey:@"type"]);
        _updataTemperature(weatherInfoNow,environment,recentWeather);
        

    }else{
        NSLog(@"error:数据获取失败");
    }
}

// 获取系统时间
- (NSString*)getCurrentTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"HH:mm"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    NSLog(@"time:%@",dateTime);
    return dateTime;
}

// 将当前的天气数据存到plist文件中作为缓存
- (void)saveWeatherDataToPlist:(NSDictionary *)weatherDataDictionary FromMain:(BOOL)isFromMain{
    NSFileManager *fm = [NSFileManager defaultManager];
    //找到Documents文件所在的路径
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //取得第一个Documents文件夹的路径
    NSString *filePath = [path objectAtIndex:0];
    //把TestPlist文件加入
    NSString *plistPath;
    if (isFromMain) {
        plistPath = [filePath stringByAppendingPathComponent:@"weatherDataCache.plist"];
    }else{
        plistPath = [filePath stringByAppendingPathComponent:@"weatherDataCacheWidget.plist"];
    }
    
    //开始创建文件
    [fm createFileAtPath:plistPath contents:nil attributes:nil];
    //把数据写入plist文件
    [weatherDataDictionary writeToFile:plistPath atomically:YES];
}
@end


