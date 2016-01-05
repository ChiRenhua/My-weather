//
//  TodayViewController.h
//  Weather widget
//
//  Created by Martin on 15/12/4.
//  Copyright © 2015年 Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "WeatherInfoModel.h"
#import "WeatherInfoFromNet.h"

@interface TodayViewController : UIViewController<CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager* locationManager;
@end
