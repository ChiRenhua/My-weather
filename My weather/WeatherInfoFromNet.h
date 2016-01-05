//
//  NSObject+WeatherInfoFromNet.h
//  My weather
//
//  Created by Martin on 15/12/2.
//  Copyright © 2015年 Martin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WeatherInfoModel.h"

typedef void (^networkErrorBlock)(NSString *title, NSString *errorMessage);
@interface WeatherInfoFromNet : NSObject<NSURLConnectionDataDelegate>

// 从网络获取天气数据
-(void) getWeatherInfoFromNetWithCityCode:(NSString *)cityCode model:(WeatherInfoModel *)model;
@property (nonatomic,copy)networkErrorBlock errorBlock;

@end
