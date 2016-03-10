//
//  ViewController.m
//  My weather
//
//  Created by Martin on 15/11/27.
//  Copyright © 2015年 Martin. All rights reserved.
//

#import "ViewController.h"
#import "WeatherInfoKit.h"

// 城市信息UILABLE的宽高属性
#define CITY_LABLE_WEIGHT 300
#define CITY_LABEL_HEIGHT 100
#define WEATHER_IMAGE_WEIGHT 150
#define WEATHER_IMAGE_HEIGHT 150

// 错误信息类型
#define ERROR_GET_LOCATION 0
#define ERROR_NET 1
#define ERROR_GET_DATA 2

// 屏幕尺寸
#define SCREEN_BOUNDS [UIScreen mainScreen].bounds

@interface ViewController ()<UIScrollViewDelegate>

@property (strong,nonatomic) UIScrollView *scrollView;

@property (nonatomic,strong) WeatherInfoModel *wim;        // 天气编码类

@property (nonatomic) Reachability *internetReachability;  // 网络连接是否可用
@property (nonatomic) Reachability *wifiReachability;      // wifi是否可用

@end
NSMutableArray *countryData;                               // 用户存储的城市列表

UILabel *cityLable;                                        // 显示城市名
UILabel *cityDetialLabel;                                  // 显示城市二级名称
UILabel *cityTemperatureLable;                             // 显示城市温度
UILabel *weatherInfoLable;                                 // 显示天气状态
UIImageView *weatherImageview;                             // 显示城市天气类型图

// 未来四天的天气状态图
UIImageView *weatherImageview1;
UIImageView *weatherImageview2;
UIImageView *weatherImageview3;
UIImageView *weatherImageview4;

// 未来四天的温度
UILabel *temperatureLable1;
UILabel *temperatureLable2;
UILabel *temperatureLable3;
UILabel *temperatureLable4;

// 未来四天星期数
UILabel *weekLable1;
UILabel *weekLable2;
UILabel *weekLable3;
UILabel *weekLable4;

WeatherInfoFromNet *wdata;                                 // 获取天气信息类

NSString *cityName;                                        // 城市名称
NSString *cityDetialName;                                  // 二级城市名称
NSString *cityCode;                                        // 城市代码

BOOL isGetInfo;                                            // 判断网络请求是否获取到数据
BOOL isNetWork;                                            // 判断当前网络是否在工作

NSMutableDictionary *weatherDataCacheDictionary;  //天气数据缓存

@implementation ViewController

// 在初始化的时候执行某些操作
- (id)init{
    if (self = [super init]) {
        //初始化ScrolleView
        [self initScrolleView];
        
        weatherDataCacheDictionary = [[NSMutableDictionary alloc]init];
        _wim = [[WeatherInfoModel alloc]init];
        __weak typeof(self) weakSelf = self;
        _wim.updataTemperature = ^(NSDictionary *weatherInfoToday,NSDictionary *enviroment,NSMutableArray *recentWeatherInfo){
            NSMutableArray *weekArray = [[NSMutableArray alloc]init];
            [weekArray addObject:weekLable1];
            [weekArray addObject:weekLable2];
            [weekArray addObject:weekLable3];
            [weekArray addObject:weekLable4];
            NSMutableArray *weekTemperatureArray = [[NSMutableArray alloc]init];
            [weekTemperatureArray addObject:temperatureLable1];
            [weekTemperatureArray addObject:temperatureLable2];
            [weekTemperatureArray addObject:temperatureLable3];
            [weekTemperatureArray addObject:temperatureLable4];
            NSMutableArray *weatherTypeImageView = [[NSMutableArray alloc]init];
            [weatherTypeImageView addObject:weatherImageview1];
            [weatherTypeImageView addObject:weatherImageview2];
            [weatherTypeImageView addObject:weatherImageview3];
            [weatherTypeImageView addObject:weatherImageview4];
            
            // 显示当天温度
            cityTemperatureLable.text = [[weatherInfoToday objectForKey:@"wendu"] stringByAppendingString:@"°"];
            // 将当前温度存入缓存
            [weatherDataCacheDictionary setObject:[[weatherInfoToday objectForKey:@"wendu"] stringByAppendingString:@"°"] forKey:@"cityTemperature"];
            // 将dayOrNight存入缓存
            [weatherDataCacheDictionary setObject:[weatherInfoToday objectForKey:@"dayOrNight"] forKey:@"dayOrNight"];
            // 判断白天还是晚上
            if ([[weatherInfoToday objectForKey:@"dayOrNight"] isEqualToString:@"day"]) {
                // 获取当天的天气状态
                NSString *weatherType = [[recentWeatherInfo[0] objectForKey:@"day"] objectForKey:@"type"];
                // 当前的天气类型存入缓存
                [weatherDataCacheDictionary setObject:weatherType forKey:@"weatherType"];
                // 显示当前的天气状态
                [weatherInfoLable setText:weatherType];
                // 加载天气类型图片
                [weakSelf updateWeatherTypePicture:weatherImageview Type:weatherType DayOrNight:@"day"];
                // 为应用添加背景图片
                [weakSelf.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.JPG"]]];
                cityLable.textColor = [UIColor blackColor];
                cityDetialLabel.textColor = [UIColor blackColor];
                cityTemperatureLable.textColor = [UIColor blackColor];
                weatherInfoLable.textColor = [UIColor blackColor];
                weekLable1.textColor = [UIColor blackColor];
                weekLable2.textColor = [UIColor blackColor];
                weekLable3.textColor = [UIColor blackColor];
                weekLable4.textColor = [UIColor blackColor];
            }else{
                // 获取当天的天气状态
                NSString *weatherType = [[recentWeatherInfo[0] objectForKey:@"night"] objectForKey:@"type"];
                // 当前的天气类型存入缓存
                [weatherDataCacheDictionary setObject:weatherType forKey:@"weatherType"];
                // 显示当前的天气状态
                [weatherInfoLable setText:weatherType];
                // 加载天气类型图片
                [weakSelf updateWeatherTypePicture:weatherImageview Type:weatherType DayOrNight:@"night"];
                // 为应用添加背景图片
                [weakSelf.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"night_background.JPG"]]];
                cityLable.textColor = [UIColor whiteColor];
                cityDetialLabel.textColor = [UIColor whiteColor];
                cityTemperatureLable.textColor = [UIColor whiteColor];
                weatherInfoLable.textColor = [UIColor whiteColor];
                weekLable1.textColor = [UIColor whiteColor];
                weekLable2.textColor = [UIColor whiteColor];
                weekLable3.textColor = [UIColor whiteColor];
                weekLable4.textColor = [UIColor whiteColor];
                
            }
            // 加载星期数和温度
            for (NSUInteger i = 1; i<5; i++) {
                NSString *weekTemp = [recentWeatherInfo[i] objectForKey:@"date"];
                NSString *week = [weekTemp substringFromIndex:[weekTemp length]-3];
                NSString *highTemperatureTemp = [recentWeatherInfo[i] objectForKey:@"high"];
                NSString *lowTemperatureTemp = [recentWeatherInfo[i] objectForKey:@"low"];
                NSString *highTemperature = [highTemperatureTemp substringFromIndex:3];
                NSString *lowTemperature = [lowTemperatureTemp substringFromIndex:3];
                // 星期数存入缓存
                NSString *weekKey = [[NSString alloc]initWithFormat:@"week%lu",(unsigned long)i];
                [weatherDataCacheDictionary setObject:week forKey:weekKey];
                
                highTemperature = [[highTemperature substringToIndex:[highTemperature length]-1] stringByAppendingString:@"°"];
                lowTemperature = [[lowTemperature substringToIndex:[lowTemperature length]-1] stringByAppendingString:@"°"];
                NSString *recentTemperature = [[lowTemperature stringByAppendingString:@"~"] stringByAppendingString:highTemperature];
                
                // 星期温度存入缓存
                NSString *weekTempCacheKey = [[NSString alloc]initWithFormat:@"weekTemp%lu",(unsigned long)i];
                [weatherDataCacheDictionary setObject:recentTemperature forKey:weekTempCacheKey];
                // 未来星期天气类型存入缓存
                NSString *typeCacheKey = [[NSString alloc]initWithFormat:@"weekType%lu",(unsigned long)i];
                NSString *typeData = [[recentWeatherInfo[i] objectForKey:@"day"] objectForKey:@"type"];
                [weatherDataCacheDictionary setObject:typeData forKey:typeCacheKey];
                
                
                [weakSelf updateWeek:weekArray[i-1] week:week TemperatureUILable:weekTemperatureArray[i-1] Temperature:recentTemperature];
                [weakSelf updateWeatherTypePicture:weatherTypeImageView[i-1] Type:[[recentWeatherInfo[i] objectForKey:@"day"] objectForKey:@"type"]DayOrNight:nil];
            }
            
            // 将最近更新的信息写入到pist文件中
            [weakSelf.wim saveWeatherDataToPlist:weatherDataCacheDictionary FromMain:true];
            
            [weakSelf.view addSubview:cityTemperatureLable];
        };
        //初始化天气信息类
        wdata = [[WeatherInfoFromNet alloc]init];
        wdata.errorBlock = ^(NSString *title, NSString *errorMessage){
            [weakSelf showAlertViewWithTitle:title Message:errorMessage ButtonTitle:@"确定" ErrorType:ERROR_GET_DATA];
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置网络状态变化监听
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    [self configureReachability:self.internetReachability];
    
    /*
     * 向界面添加UILable，显示城市信息
     */
    // 初始化UILable，同时加上布局信息
    cityLable = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width-CITY_LABLE_WEIGHT)/2, self.view.frame.size.height/20, CITY_LABLE_WEIGHT, CITY_LABEL_HEIGHT)];
    // 设置文字居中
    cityLable.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    cityLable.font = [UIFont fontWithName:@"Arial" size:40];
    // 设置文字内容
    cityLable.text = @"_,_";
    // 添加文字到界面中
    [self.view addSubview:cityLable];
    
    /*
     * 向界面添加UILable，显示二级城市信息
     */
    // 初始化UILable，同时加上布局信息
    cityDetialLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width-CITY_LABLE_WEIGHT)/2, self.view.frame.size.height/7, CITY_LABLE_WEIGHT, CITY_LABEL_HEIGHT/2)];
    // 设置文字居中
    cityDetialLabel.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    cityDetialLabel.font = [UIFont fontWithName:@"Arial" size:20];
    // 设置文字内容
    cityDetialLabel.text = @"_,_";
    // 添加文字到界面中
    [self.view addSubview:cityDetialLabel];
    
    /*
     * 向界面添加UILable，显示城市温度信息
     */
    // 初始化UILable，同时加上布局信息
    cityTemperatureLable = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width-CITY_LABLE_WEIGHT)/2+10, self.view.frame.size.height/2-30, CITY_LABLE_WEIGHT, CITY_LABEL_HEIGHT)];
    // 设置文字居中
    cityTemperatureLable.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    cityTemperatureLable.font = [UIFont fontWithName:@"Arial" size:100];
    // 设置文字内容
    cityTemperatureLable.text = @"";
    // 添加文字到界面中
    [self.view addSubview:cityTemperatureLable];
    
    /*
     * 向界面添加UILable，显示天气状态信息
     */
    // 初始化UILable，同时加上布局信息
    weatherInfoLable = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width-CITY_LABLE_WEIGHT)/2, self.view.frame.size.height/3+55, CITY_LABLE_WEIGHT, CITY_LABEL_HEIGHT/3)];
    // 设置文字居中
    weatherInfoLable.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weatherInfoLable.font = [UIFont fontWithName:@"Arial" size:20];
    // 设置文字内容
    weatherInfoLable.text = @"_,_";
    // 添加文字到界面中
    [self.view addSubview:weatherInfoLable];
    
    /*
     * 向界面添加UIImageView，显示天气图标
     */
    // 初始化UIImageView，同时加上布局信息
    weatherImageview = [[UIImageView alloc]initWithFrame:CGRectMake((self.view.frame.size.width-WEATHER_IMAGE_WEIGHT)/2, self.view.frame.size.height/5, WEATHER_IMAGE_WEIGHT, WEATHER_IMAGE_HEIGHT)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview];
    
    /*
     * 向界面添加UIImageView，显示未来天气图标
     */
    // 初始化UIImageView，同时加上布局信息
    weatherImageview1 = [[UIImageView alloc]initWithFrame:CGRectMake((self.view.frame.size.width-50*4)/5, self.view.frame.size.height/4*3, WEATHER_IMAGE_WEIGHT/3, WEATHER_IMAGE_HEIGHT/3)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview1];
    
    // 初始化UIImageView，同时加上布局信息
    weatherImageview2 = [[UIImageView alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*2+50, self.view.frame.size.height/4*3, WEATHER_IMAGE_WEIGHT/3, WEATHER_IMAGE_HEIGHT/3)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview2];
    
    // 初始化UIImageView，同时加上布局信息
    weatherImageview3 = [[UIImageView alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*3+50*2, self.view.frame.size.height/4*3, WEATHER_IMAGE_WEIGHT/3, WEATHER_IMAGE_HEIGHT/3)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview3];
    
    // 初始化UIImageView，同时加上布局信息
    weatherImageview4 = [[UIImageView alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*4+50*3, self.view.frame.size.height/4*3, WEATHER_IMAGE_WEIGHT/3, WEATHER_IMAGE_HEIGHT/3)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview4];
    
    /*
     * 向界面添加UILable，显示未来天气温度
     */
    // 初始化UILable，同时加上布局信息
    temperatureLable1 = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width-50*4)/5-25, self.view.frame.size.height/7*6, 100, 50)];
    // 设置文字居中
    temperatureLable1.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    temperatureLable1.font = [UIFont fontWithName:@"Arial" size:20];
    // 设置文字内容
    temperatureLable1.text = @"-°";
    // 添加文字到界面中
    [self.view addSubview:temperatureLable1];
    
    // 初始化UILable，同时加上布局信息
    temperatureLable2 = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*2+25, self.view.frame.size.height/7*6, 100, 50)];
    // 设置文字居中
    temperatureLable2.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    temperatureLable2.font = [UIFont fontWithName:@"Arial" size:20];
    // 设置文字内容
    temperatureLable2.text = @"-°";
    // 添加文字到界面中
    [self.view addSubview:temperatureLable2];
    
    // 初始化UILable，同时加上布局信息
    temperatureLable3 = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*3+50*2-25, self.view.frame.size.height/7*6, 100, 50)];
    // 设置文字居中
    temperatureLable3.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    temperatureLable3.font = [UIFont fontWithName:@"Arial" size:20];
    // 设置文字内容
    temperatureLable3.text = @"-°";
    // 添加文字到界面中
    [self.view addSubview:temperatureLable3];
    
    // 初始化UILable，同时加上布局信息
    temperatureLable4 = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*4+50*3-25, self.view.frame.size.height/7*6, 100, 50)];
    // 设置文字居中
    temperatureLable4.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    temperatureLable4.font = [UIFont fontWithName:@"Arial" size:20];
    // 设置文字内容
    temperatureLable4.text = @"-°";
    // 添加文字到界面中
    [self.view addSubview:temperatureLable4];
    
    /*
     * 向界面添加UILable，显示未来星期数
     */
    // 初始化UILable，同时加上布局信息
    weekLable1 = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width-50*4)/5-25, self.view.frame.size.height/3*2, 100, 30)];
    // 设置文字居中
    weekLable1.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weekLable1.font = [UIFont fontWithName:@"Arial" size:20];
    // 设置文字内容
    weekLable1.text = @"——";
    // 添加文字到界面中
    [self.view addSubview:weekLable1];
    
    // 初始化UILable，同时加上布局信息
    weekLable2 = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*2+25, self.view.frame.size.height/3*2, 100, 30)];
    // 设置文字居中
    weekLable2.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weekLable2.font = [UIFont fontWithName:@"Arial" size:20];
    // 设置文字内容
    weekLable2.text = @"——";
    // 添加文字到界面中
    [self.view addSubview:weekLable2];
    
    // 初始化UILable，同时加上布局信息
    weekLable3 = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*3+50*2-25, self.view.frame.size.height/3*2, 100, 30)];
    // 设置文字居中
    weekLable3.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weekLable3.font = [UIFont fontWithName:@"Arial" size:20];
    // 设置文字内容
    weekLable3.text = @"——";
    // 添加文字到界面中
    [self.view addSubview:weekLable3];
    
    // 初始化UILable，同时加上布局信息
    weekLable4 = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*4+50*3-25, self.view.frame.size.height/3*2, 100, 30)];
    // 设置文字居中
    weekLable4.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weekLable4.font = [UIFont fontWithName:@"Arial" size:20];
    // 设置文字内容
    weekLable4.text = @"——";
    // 添加文字到界面中
    [self.view addSubview:weekLable4];
    
    [self loadCacheData];
}

- (void)viewWillAppear:(BOOL)animated{
     [self startLocation];
}

- (void)loadCacheData{
    //找到Documents文件所在的路径
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //取得第一个Documents文件夹的路径
    NSString *filePath = [path objectAtIndex:0];
    //把TestPlist文件加入
    NSString *plistPath = [filePath stringByAppendingPathComponent:@"weatherDataCache.plist"];
    NSMutableDictionary *weatherDataCache = [[NSMutableDictionary alloc]initWithContentsOfFile:plistPath];
    NSString *dayOrNight = [weatherDataCache objectForKey:@"dayOrNight"];
    if ([dayOrNight isEqualToString:@"day"]) {
        // 为应用添加背景图片
        [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.JPG"]]];
        cityLable.textColor = [UIColor blackColor];
        cityDetialLabel.textColor = [UIColor blackColor];
        cityTemperatureLable.textColor = [UIColor blackColor];
        weatherInfoLable.textColor = [UIColor blackColor];
        weekLable1.textColor = [UIColor blackColor];
        weekLable2.textColor = [UIColor blackColor];
        weekLable3.textColor = [UIColor blackColor];
        weekLable4.textColor = [UIColor blackColor];
    }else{
        // 为应用添加背景图片
        [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"night_background.JPG"]]];
        cityLable.textColor = [UIColor whiteColor];
        cityDetialLabel.textColor = [UIColor whiteColor];
        cityTemperatureLable.textColor = [UIColor whiteColor];
        weatherInfoLable.textColor = [UIColor whiteColor];
        weekLable1.textColor = [UIColor whiteColor];
        weekLable2.textColor = [UIColor whiteColor];
        weekLable3.textColor = [UIColor whiteColor];
        weekLable4.textColor = [UIColor whiteColor];
    }
    cityLable.text = [weatherDataCache objectForKey:@"cityName"];
    cityDetialLabel.text = [weatherDataCache objectForKey:@"cityDetialName"];
    cityTemperatureLable.text = [weatherDataCache objectForKey:@"cityTemperature"];
    weatherInfoLable.text = [weatherDataCache objectForKey:@"weatherType"];
     [self updateWeatherTypePicture:weatherImageview Type:[weatherDataCache objectForKey:@"weatherType"] DayOrNight:dayOrNight];
    
    // 未来四天的天气状态图
    [self updateWeatherTypePicture:weatherImageview1 Type:[weatherDataCache objectForKey:@"weekType1"] DayOrNight:dayOrNight];
    [self updateWeatherTypePicture:weatherImageview2 Type:[weatherDataCache objectForKey:@"weekType2"] DayOrNight:dayOrNight];
    [self updateWeatherTypePicture:weatherImageview3 Type:[weatherDataCache objectForKey:@"weekType3"] DayOrNight:dayOrNight];
    [self updateWeatherTypePicture:weatherImageview4 Type:[weatherDataCache objectForKey:@"weekType4"] DayOrNight:dayOrNight];
    
    [self updateWeek:weekLable1 week:[weatherDataCache objectForKey:@"week1"] TemperatureUILable:temperatureLable1 Temperature:[weatherDataCache objectForKey:@"weekTemp1"]];
    [self updateWeek:weekLable2 week:[weatherDataCache objectForKey:@"week2"] TemperatureUILable:temperatureLable2 Temperature:[weatherDataCache objectForKey:@"weekTemp2"]];
    [self updateWeek:weekLable3 week:[weatherDataCache objectForKey:@"week3"] TemperatureUILable:temperatureLable3 Temperature:[weatherDataCache objectForKey:@"weekTemp3"]];
    [self updateWeek:weekLable4 week:[weatherDataCache objectForKey:@"week4"] TemperatureUILable:temperatureLable4 Temperature:[weatherDataCache objectForKey:@"weekTemp4"]];
}


// 开始执行定位，并执行定位前的设置
- (void)startLocation{
    isGetInfo = false;
    _locationManager = [[CLLocationManager alloc] init];
    // 设置定位精度，十米，百米，最好
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    // 设置代理
    _locationManager.delegate = self;
    // 添加权限“始终允许访问位置信息”   或者可以选择“- (void)requestWhenInUseAuthorizatioin;”（使用应用程序期间允许访问位置数据）
    [_locationManager requestAlwaysAuthorization];
    // 设置每隔100米更新位置
     [_locationManager setDistanceFilter:100];
    // 开始时时定位
    [_locationManager startUpdatingLocation];
}

// 错误信息回调
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
     //错误信息
    NSString *errorMessage = nil;
    if (error.code == kCLErrorDenied) {
        errorMessage = @"访问被拒绝";
    }
    if (error.code == kCLErrorLocationUnknown) {
        errorMessage = @"获取位置信息失败";
    }
    [self showAlertViewWithTitle:@"Location!!!" Message:errorMessage ButtonTitle:@"重试" ErrorType:ERROR_GET_LOCATION];
}

// 6.0 以上调用这个函数获取位置信息
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *newLocation = locations[0];
    CLLocationCoordinate2D oldCoordinate = newLocation.coordinate;
    NSLog(@"旧的经度：%f,旧的纬度：%f",oldCoordinate.longitude,oldCoordinate.latitude);
    [manager stopUpdatingLocation];
    // ------------------位置反编码---5.0之后使用-----------------
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:newLocation
                   completionHandler:^(NSArray *placemarks, NSError *error){
                       for (CLPlacemark *place in placemarks) {
                           isGetInfo = true;
                           cityName = place.locality;                          // 获取城市名称
                           [weatherDataCacheDictionary setObject:cityName forKey:@"cityName"];                     // 城市名称存入缓存
                           cityDetialName = place.subLocality;                 // 获取二级城市名称
                           [weatherDataCacheDictionary setObject:cityDetialName forKey:@"cityDetialName"];         // 二级城市名称存入缓存
                           cityCode = [_wim translateCityNameToCityCode:cityName cityDetialName:cityDetialName];   // 获取城市代码
                           [wdata getWeatherInfoFromNetWithCityCode:cityCode model:_wim];                          // 从网上获取当地天气信息
                           [cityLable setText:cityName];                       // 显示所在城市名
                           [cityDetialLabel setText:cityDetialName];           // 显示所在二级城市名
                           NSLog(@"name,%@",place.name);                       // 位置名
                           NSLog(@"thoroughfare,%@",place.thoroughfare);       // 街道
                           NSLog(@"subThoroughfare,%@",place.subThoroughfare); // 子街道
                           NSLog(@"locality,%@",place.locality);               // 市
                           NSLog(@"subLocality,%@",place.subLocality);         // 区
                           NSLog(@"country,%@",place.country);                 // 国家
                       }
                       
                   }];
    // 获取定位信息失败，再次尝试
    if (!isGetInfo && isNetWork) {
        [self startLocation];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 加载未来天气图片
- (void)updateWeatherTypePicture:(UIImageView *)imageView Type:(NSString *)type DayOrNight:(NSString *) don{
    // 根据天气状态的不同加载不同的天气图片
    if ([type hasSuffix:@"晴"]) {
        if ([don isEqualToString:@"night"]) {
            // 给UIImageView添加上背景图片
            imageView.image  = [UIImage imageNamed:@"night_qing.png"];
        }else{
            // 给UIImageView添加上背景图片
            imageView.image  = [UIImage imageNamed:@"qingtian.png"];
        }
        
    }else if ([type hasSuffix:@"多云"]){
        if ([don isEqualToString:@"night"]) {
            // 给UIImageView添加上背景图片
            imageView.image  = [UIImage imageNamed:@"night_duoyun.png"];
        }else{
            // 给UIImageView添加上背景图片
            imageView.image  = [UIImage imageNamed:@"duoyun.png"];
        }
    }else if ([type hasSuffix:@"阴"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"yintian.png"];
    }else if ([type hasSuffix:@"小雨"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"xiaoyu.png"];
    }else if ([type hasSuffix:@"中雨"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"zhongyu.png"];
    }else if ([type hasSuffix:@"大雨"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"dayu.png"];
    }else if ([type hasSuffix:@"暴雨"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"baoyu.png"];
    }else if ([type hasSuffix:@"阵雨"]){
        if ([don isEqualToString:@"night"]) {
            // 给UIImageView添加上背景图片
            imageView.image  = [UIImage imageNamed:@"night_zhenyu.png"];
        }else{
            // 给UIImageView添加上背景图片
            imageView.image  = [UIImage imageNamed:@"zhenyu.png"];
        }
    }else if ([type hasSuffix:@"雷阵雪"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"leizhenxue.png"];
    }else if ([type hasSuffix:@"冻雨"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"dongyu.png"];
    }else if ([type hasSuffix:@"雨夹雪"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"yujiaxue.png"];
    }else if ([type hasSuffix:@"小雪"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"xiaoxue.png"];
    }else if ([type hasSuffix:@"中雪"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"zhongxue.png"];
    }else if ([type hasSuffix:@"大雪"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"daxue.png"];
    }else if ([type hasSuffix:@"暴雪"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"baoxue.png"];
    }else if ([type hasSuffix:@"阵雪"]){
        if ([don isEqualToString:@"night"]) {
            // 给UIImageView添加上背景图片
            imageView.image  = [UIImage imageNamed:@"night_zhenxue.png"];
        }else{
            // 给UIImageView添加上背景图片
            imageView.image  = [UIImage imageNamed:@"zhenxue.png"];
        }
    }
    else if ([type hasSuffix:@"雾"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"wu.png"];
    }
    else if ([type hasSuffix:@"霾"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"mai.png"];
    }else if ([type hasSuffix:@"沙尘暴"]){
        // 给UIImageView添加上背景图片
        imageView.image  = [UIImage imageNamed:@"shachenbao.png"];
    }
}

// 加载未来星期数
- (void)updateWeek:(UILabel *)weekLable week:(NSString *)week TemperatureUILable:(UILabel *)temperatureUILable Temperature:(NSString *)temperature  {
    [weekLable setText:week];
    // 设置不限制换行
    temperatureUILable.numberOfLines = 0;
    [temperatureUILable setTextColor:[UIColor whiteColor]];
    [temperatureUILable setText:temperature];
}

// alertView显示
- (void)showAlertViewWithTitle:(NSString *)title Message:(NSString *)message ButtonTitle:(NSString *)buttonTitle ErrorType:(NSUInteger) errorType{
    // 弹出dialog来提示用户错误信息
    UIAlertView *errorAlertView = [[UIAlertView alloc]initWithTitle:title message:message delegate:self cancelButtonTitle:buttonTitle  otherButtonTitles:nil, nil];
    errorAlertView.tag = ERROR_GET_LOCATION;
    [errorAlertView show];
}

 // 取消按钮的实现
- (void)alertViewCancel:(UIAlertView *)alertView{
    switch (alertView.tag) {
        case ERROR_GET_LOCATION:
            [self startLocation];
            break;
        case ERROR_GET_DATA:
            break;
        case ERROR_NET:
            break;
        default:
            break;
    }
   
}

// scrolleview的初始化
- (void)initScrolleView {
    [self initCountryData];
    _scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_BOUNDS.size.width, SCREEN_BOUNDS.size.height)];
    // 设置内容大小
    _scrollView.contentSize = CGSizeMake(SCREEN_BOUNDS.size.width * countryData.count, SCREEN_BOUNDS.size.height);
    // 是否分页
    _scrollView.pagingEnabled = YES;
    // 是否反弹
    _scrollView.bounces = YES;
    // 是否滚动
    _scrollView.scrollEnabled = YES;
    for (int i = 0; i < countryData.count; i++) {
        UIView *view = [[UIView alloc]initWithFrame:CGRectMake(i*SCREEN_BOUNDS.size.width, 0, SCREEN_BOUNDS.size.width, SCREEN_BOUNDS.size.height)];
        view.backgroundColor = [UIColor clearColor];
        [_scrollView addSubview:view];
        
    }
    
    [self.view addSubview:_scrollView];

}

// 用户添加城市信息初始化
- (void)initCountryData{
    countryData = [[NSMutableArray alloc]initWithObjects:@"北京", nil];
    [countryData addObject:@"天津"];
}

/*!
 * 网络状态变更时会调用此函数
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self configureReachability:curReach];
}


- (void)configureReachability:(Reachability *)reachability
{
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    
    switch (netStatus)
    {
        case NotReachable:        {
            //网络不可用
            isNetWork = false;
            [self showAlertViewWithTitle:@"网络不可用" Message:@"请检查网络后重试" ButtonTitle:@"确定" ErrorType:ERROR_NET];
            break;
        }
        case ReachableViaWWAN:        {
            // 蜂窝可用
            isNetWork = true;
            [self startLocation];
            break;
        }
        case ReachableViaWiFi:        {
            // wifi可用
            isNetWork = true;
            [self startLocation];
            break;
        }
    }
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

// 进入后台后再返回前台调用函数
- (void)updateWeatherdData{
    [self startLocation];
}

// 移除当前observer
- (void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
