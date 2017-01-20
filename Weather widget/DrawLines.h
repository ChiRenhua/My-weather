//
//  DrawLines.h
//  My weather
//
//  Created by Renhuachi on 2017/1/20.
//  Copyright © 2017年 Martin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DrawLines : NSObject

+ (UIImage *)getCityLineWithSize:(CGSize)size;
+ (UIImage *)getTemperatureLineWithSize:(CGSize)size;
+ (UIImage *)getWeatherInfoLineWithSize:(CGSize)size;

@end
