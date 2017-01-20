//
//  DrawLines.m
//  My weather
//
//  Created by Renhuachi on 2017/1/20.
//  Copyright © 2017年 Martin. All rights reserved.
//

#import "DrawLines.h"

@implementation DrawLines

+ (UIImage *)getCityLineWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    UIBezierPath *bezierPath = [[UIBezierPath alloc]init];
    bezierPath.lineWidth = 1.0;
    
    [bezierPath moveToPoint:CGPointMake(0, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width * 0.8, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height)];
    [bezierPath stroke];
    
    CGContextDrawPath(currentContext, kCGPathFillStroke);
    UIImage *line = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return line;
}

+ (UIImage *)getTemperatureLineWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    UIBezierPath *bezierPath = [[UIBezierPath alloc]init];
    bezierPath.lineWidth = 1.0;
    [bezierPath moveToPoint:CGPointMake(0, size.height)];
    [bezierPath addLineToPoint:CGPointMake(size.width * 0.2, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width, 0)];
    [bezierPath stroke];
    
    CGContextDrawPath(currentContext, kCGPathFillStroke);
    UIImage *line = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return line;
}

+ (UIImage *)getWeatherInfoLineWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    UIBezierPath *bezierPath = [[UIBezierPath alloc]init];
    bezierPath.lineWidth = 1.0;
    
    bezierPath.lineCapStyle = kCGLineCapRound;
    
    [bezierPath moveToPoint:CGPointMake(0, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width * 0.2, size.height)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height)];
    [bezierPath stroke];
    
    CGContextDrawPath(currentContext, kCGPathFillStroke);
    UIImage *line = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return line;
}

@end
