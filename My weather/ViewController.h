//
//  ViewController.h
//  My weather
//
//  Created by Martin on 15/11/27.
//  Copyright © 2015年 Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "WeatherInfoModel.h"
#import "WeatherInfoFromNet.h"
#import "Reachability.h"

@interface ViewController : UIViewController<CLLocationManagerDelegate,UIAlertViewDelegate>
@property (strong, nonatomic) CLLocationManager* locationManager;
- (void)updateWeatherdData;
- (void)loadCacheData;
@end

