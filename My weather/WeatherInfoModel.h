//
//  WeatherInfoModel.h
//  My weather
//
//  Created by Martin on 15/12/2.
//  Copyright © 2015年 Martin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLDictionary/XMLDictionary.h"
typedef void (^updataWeatherdata)(NSDictionary *weatherInfoToday,NSDictionary *enviroment,NSMutableArray *recentWeatherInfo);

@interface WeatherInfoModel : NSObject<NSXMLParserDelegate>
- (NSString *) translateCityNameToCityCode:(NSString *) cityName cityDetialName:(NSString *)cityDetialName;

- (void) parserXML:(NSMutableData *)data;

- (void) saveWeatherDataToPlist:(NSDictionary *)weatherDataDictionary FromMain:(BOOL) isFromMain;


@property (nonatomic,copy)updataWeatherdata updataTemperature;

@end
