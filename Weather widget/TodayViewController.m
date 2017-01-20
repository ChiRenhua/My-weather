//
//  TodayViewController.m
//  Weather widget
//
//  Created by Martin on 15/12/4.
//  Copyright © 2015年 Martin. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "DrawLines.h"
#import "WeatherInfoModel.h"
#import "WeatherInfoFromNet.h"

#define WEATHER_IMAGE_WEIGHT 150
#define WEATHER_IMAGE_HEIGHT 150

#define CurrentWeatherImageWidth 80
#define CurrentWeatherImageHeight 80

#define CompactHeight 110
#define ExpandedHeight 230
#define UIScreenWidth self.view.frame.size.width

@interface TodayViewController () <NCWidgetProviding>

@property (nonatomic,strong) WeatherInfoModel *weatherInfoModel;        // 天气编码类
@property (nonatomic,strong) UIImageView *currentWeatherImage;          // 当前天气图片
@property (nonatomic,strong) UILabel *currentCity;                      // 当前城市
@property (nonatomic,strong) UILabel *currentWeatherType;               // 当前天气状态
@property (nonatomic,strong) UILabel *currentTemperature;               // 当前天气温度

@end

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

// 显示当前天气信息
UILabel *weatherLable;

WeatherInfoFromNet *wdata;                                 // 获取天气信息类

BOOL isGetInfo;                                            // 判断网络请求是否获取到数据
BOOL isNetWork;                                            // 判断当前网络是否在工作

NSMutableDictionary *weatherDataCacheDictionary;           //天气数据缓存

@implementation TodayViewController

- (id)init{
    if (self = [super init]) {
        
        UITapGestureRecognizer *tapGesture =[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openApp)];
        [self.view addGestureRecognizer:tapGesture];
        
         weatherDataCacheDictionary = [[NSMutableDictionary alloc]init];
        _weatherInfoModel = [[WeatherInfoModel alloc]init];
        __weak typeof(self) weakSelf = self;
        _weatherInfoModel.updataTemperature = ^(NSDictionary *weatherInfoToday,NSDictionary *enviroment,NSMutableArray *recentWeatherInfo){
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
            
            // 当天温度
            NSString *currentTemperature = [[weatherInfoToday objectForKey:@"wendu"] stringByAppendingString:@"°"];
            // 获取当天的天气状态
            NSString *currentWeatherType = [[recentWeatherInfo[0] objectForKey:@"day"] objectForKey:@"type"];
            // 白天还是黑夜
            NSString *currentWeatherDayOrNight = [weatherInfoToday objectForKey:@"dayOrNight"];
            
            [weakSelf updateWeatherTypePicture:weakSelf.currentWeatherImage Type:currentWeatherType DayOrNight:currentWeatherDayOrNight];
            [weatherDataCacheDictionary setObject:currentWeatherType forKey:@"currentWeatherType"];
            [weatherDataCacheDictionary setObject:currentWeatherDayOrNight forKey:@"currentWeatherDayOrNight"];
            [weatherDataCacheDictionary setObject:currentTemperature forKey:@"currentTemperature"];
            
            weakSelf.currentWeatherType.text = currentWeatherType;
            weakSelf.currentTemperature.text = currentTemperature;

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
            [weakSelf.weatherInfoModel saveWeatherDataToPlist:weatherDataCacheDictionary FromMain:false];
            
        };
        wdata = [[WeatherInfoFromNet alloc]init];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
#ifdef __IPHONE_10_0
    // 需要折叠
    self.extensionContext.widgetLargestAvailableDisplayMode = NCWidgetDisplayModeExpanded;
#endif
    
    self.currentWeatherImage = [[UIImageView alloc] initWithFrame:CGRectMake((UIScreenWidth - CurrentWeatherImageWidth) / 2, (CompactHeight - CurrentWeatherImageHeight) / 2, CurrentWeatherImageHeight, CurrentWeatherImageHeight)];
    [self.view addSubview:self.currentWeatherImage];
    
    self.currentCity = [[UILabel alloc] initWithFrame:CGRectMake(50, CompactHeight / 7, 100, 20)];
    [self.currentCity setFont:[UIFont fontWithName:@"Helvetica-Bold" size:18]];
    [self.view addSubview:self.currentCity];
    
    self.currentTemperature = [[UILabel alloc] initWithFrame:CGRectMake(UIScreenWidth - 70, CompactHeight / 4, 50, 20)];
    self.currentTemperature.font = [UIFont systemFontOfSize:25];
    [self.view addSubview:self.currentTemperature];
    
    self.currentWeatherType = [[UILabel alloc] initWithFrame:CGRectMake(UIScreenWidth - 100, CompactHeight * 0.7, 100, 20)];
    self.currentWeatherType.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:self.currentWeatherType];
    
    // 添加各种线条
    UIImageView *cityLineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(UIScreenWidth / 2 - 70, CompactHeight * 0.22, 55, 12)];
    UIImage *cityLineImage = [DrawLines getCityLineWithSize:cityLineImageView.bounds.size];
    cityLineImageView.image = cityLineImage;
    [self.view addSubview:cityLineImageView];
    
    UIImageView *tmpLineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(UIScreenWidth / 2 + 35, CompactHeight * 0.35, 70, 12)];
    UIImage *tmpLineImage = [DrawLines getTemperatureLineWithSize:tmpLineImageView.bounds.size];
    tmpLineImageView.image = tmpLineImage;
    [self.view addSubview:tmpLineImageView];
    
    UIImageView *weatherInfoLineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(UIScreenWidth / 2 + 10, CompactHeight * 0.7, 60, 12)];
    UIImage *weatherInfoLine = [DrawLines getWeatherInfoLineWithSize:weatherInfoLineImageView.bounds.size];
    weatherInfoLineImageView.image = weatherInfoLine;
    [self.view addSubview:weatherInfoLineImageView];
    
    UIImageView *dividingLineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, CompactHeight + 1, UIScreenWidth - 10, 0.5)];
    [dividingLineImageView setBackgroundColor:[UIColor grayColor]];
    [self.view addSubview:dividingLineImageView];
    
    /*
     * 向界面添加UIImageView，显示未来天气图标
     */
    // 初始化UIImageView，同时加上布局信息
    weatherImageview1 = [[UIImageView alloc]initWithFrame:CGRectMake((UIScreenWidth-50*4)/5, CompactHeight + 35, WEATHER_IMAGE_WEIGHT/3, WEATHER_IMAGE_HEIGHT/3)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview1];
    
    // 初始化UIImageView，同时加上布局信息
    weatherImageview2 = [[UIImageView alloc]initWithFrame:CGRectMake(((UIScreenWidth-50*4)/5)*2+50, CompactHeight + 35, WEATHER_IMAGE_WEIGHT/3, WEATHER_IMAGE_HEIGHT/3)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview2];
    
    // 初始化UIImageView，同时加上布局信息
    weatherImageview3 = [[UIImageView alloc]initWithFrame:CGRectMake(((UIScreenWidth-50*4)/5)*3+50*2, CompactHeight + 35, WEATHER_IMAGE_WEIGHT/3, WEATHER_IMAGE_HEIGHT/3)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview3];
    
    // 初始化UIImageView，同时加上布局信息
    weatherImageview4 = [[UIImageView alloc]initWithFrame:CGRectMake(((UIScreenWidth-50*4)/5)*4+50*3, CompactHeight + 35, WEATHER_IMAGE_WEIGHT/3, WEATHER_IMAGE_HEIGHT/3)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview4];
    
    /*
     * 向界面添加UILable，显示未来天气温度
     */
    // 初始化UILable，同时加上布局信息
    temperatureLable1 = [[UILabel alloc]initWithFrame:CGRectMake((UIScreenWidth-50*4)/5-25, CompactHeight + 70, 100, 50)];
    // 设置文字居中
    temperatureLable1.textAlignment = NSTextAlignmentCenter;
    // 设置文字颜色
    temperatureLable1.textColor = [UIColor blackColor];
    // 设置文字样式和大小
    temperatureLable1.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字内容
    temperatureLable1.text = @"-°";
    // 添加文字到界面中
    [self.view addSubview:temperatureLable1];
    
    // 初始化UILable，同时加上布局信息
    temperatureLable2 = [[UILabel alloc]initWithFrame:CGRectMake(((UIScreenWidth-50*4)/5)*2+25, CompactHeight + 70, 100, 50)];
    // 设置文字居中
    temperatureLable2.textAlignment = NSTextAlignmentCenter;
    // 设置文字颜色
    temperatureLable2.textColor = [UIColor blackColor];
    // 设置文字样式和大小
    temperatureLable2.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字内容
    temperatureLable2.text = @"-°";
    // 添加文字到界面中
    [self.view addSubview:temperatureLable2];
    
    // 初始化UILable，同时加上布局信息
    temperatureLable3 = [[UILabel alloc]initWithFrame:CGRectMake(((UIScreenWidth-50*4)/5)*3+50*2-25, CompactHeight + 70, 100, 50)];
    // 设置文字居中
    temperatureLable3.textAlignment = NSTextAlignmentCenter;
    // 设置文字颜色
    temperatureLable3.textColor = [UIColor blackColor];
    // 设置文字样式和大小
    temperatureLable3.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字内容
    temperatureLable3.text = @"-°";
    // 添加文字到界面中
    [self.view addSubview:temperatureLable3];
    
    // 初始化UILable，同时加上布局信息
    temperatureLable4 = [[UILabel alloc]initWithFrame:CGRectMake(((UIScreenWidth-50*4)/5)*4+50*3-25, CompactHeight + 70, 100, 50)];
    // 设置文字居中
    temperatureLable4.textAlignment = NSTextAlignmentCenter;
    // 设置文字颜色
    temperatureLable4.textColor = [UIColor blackColor];
    // 设置文字样式和大小
    temperatureLable4.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字内容
    temperatureLable4.text = @"-°";
    // 添加文字到界面中
    [self.view addSubview:temperatureLable4];
    
    /*
     * 向界面添加UILable，显示未来星期数
     */
    // 初始化UILable，同时加上布局信息
    weekLable1 = [[UILabel alloc]initWithFrame:CGRectMake((UIScreenWidth-50*4)/5-25, CompactHeight + 5, 100, 30)];
    // 设置文字居中
    weekLable1.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weekLable1.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字颜色
    weekLable1.textColor = [UIColor blackColor];
    // 设置文字内容
    weekLable1.text = @"——";
    // 添加文字到界面中
    [self.view addSubview:weekLable1];
    
    // 初始化UILable，同时加上布局信息
    weekLable2 = [[UILabel alloc]initWithFrame:CGRectMake(((UIScreenWidth-50*4)/5)*2+25, CompactHeight + 5, 100, 30)];
    // 设置文字居中
    weekLable2.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weekLable2.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字颜色
    weekLable2.textColor = [UIColor blackColor];
    // 设置文字内容
    weekLable2.text = @"——";
    // 添加文字到界面中
    [self.view addSubview:weekLable2];
    
    // 初始化UILable，同时加上布局信息
    weekLable3 = [[UILabel alloc]initWithFrame:CGRectMake(((UIScreenWidth-50*4)/5)*3+50*2-25, CompactHeight + 5, 100, 30)];
    // 设置文字居中
    weekLable3.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weekLable3.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字颜色
    weekLable3.textColor = [UIColor blackColor];
    // 设置文字内容
    weekLable3.text = @"——";
    // 添加文字到界面中
    [self.view addSubview:weekLable3];
    
    // 初始化UILable，同时加上布局信息
    weekLable4 = [[UILabel alloc]initWithFrame:CGRectMake(((UIScreenWidth-50*4)/5)*4+50*3-25, CompactHeight + 5, 100, 30)];
    // 设置文字居中
    weekLable4.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weekLable4.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字颜色
    weekLable4.textColor = [UIColor blackColor];
    // 设置文字内容
    weekLable4.text = @"——";
    // 添加文字到界面中
    [self.view addSubview:weekLable4];
    [self loadCacheData];
    [self startLocation];

}

- (void)loadCacheData{
    //找到Documents文件所在的路径
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //取得第一个Documents文件夹的路径
    NSString *filePath = [path objectAtIndex:0];
    //把TestPlist文件加入
    NSString *plistPath = [filePath stringByAppendingPathComponent:@"weatherDataCacheWidget.plist"];
    NSMutableDictionary *weatherDataCache = [[NSMutableDictionary alloc]initWithContentsOfFile:plistPath];
    NSString *dayOrNight = [weatherDataCache objectForKey:@"dayOrNight"];
    // 未来四天的天气状态图
    [self updateWeatherTypePicture:weatherImageview1 Type:[weatherDataCache objectForKey:@"weekType1"] DayOrNight:dayOrNight];
    [self updateWeatherTypePicture:weatherImageview2 Type:[weatherDataCache objectForKey:@"weekType2"] DayOrNight:dayOrNight];
    [self updateWeatherTypePicture:weatherImageview3 Type:[weatherDataCache objectForKey:@"weekType3"] DayOrNight:dayOrNight];
    [self updateWeatherTypePicture:weatherImageview4 Type:[weatherDataCache objectForKey:@"weekType4"] DayOrNight:dayOrNight];
    
    [self updateWeek:weekLable1 week:[weatherDataCache objectForKey:@"week1"] TemperatureUILable:temperatureLable1 Temperature:[weatherDataCache objectForKey:@"weekTemp1"]];
    [self updateWeek:weekLable2 week:[weatherDataCache objectForKey:@"week2"] TemperatureUILable:temperatureLable2 Temperature:[weatherDataCache objectForKey:@"weekTemp2"]];
    [self updateWeek:weekLable3 week:[weatherDataCache objectForKey:@"week3"] TemperatureUILable:temperatureLable3 Temperature:[weatherDataCache objectForKey:@"weekTemp3"]];
    [self updateWeek:weekLable4 week:[weatherDataCache objectForKey:@"week4"] TemperatureUILable:temperatureLable4 Temperature:[weatherDataCache objectForKey:@"weekTemp4"]];
    
    [weatherLable setText:[weatherDataCache objectForKey:@"weatherInfo"]];
    
    // 读取缓存的天气信息
    NSString *currentWeatherType = [weatherDataCache objectForKey:@"currentWeatherType"];
    NSString *currentWeatherDayOrNight = [weatherDataCache objectForKey:@"dayOrNight"];
    NSString *currentCityName = [weatherDataCache objectForKey:@"cityName"];
    NSString *currentWeatherTemperature = [weatherDataCache objectForKey:@"currentTemperature"];
    
    [self updateWeatherTypePicture:self.currentWeatherImage Type:currentWeatherType DayOrNight:currentWeatherDayOrNight];
    self.currentCity.text = currentCityName;
    self.currentWeatherType.text = currentWeatherType;
    self.currentTemperature.text = currentWeatherTemperature;

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
                           NSString *cityName = place.locality;                          // 获取城市名称
                           
                           self.currentCity.text = cityName;
                           [weatherDataCacheDictionary setObject:cityName forKey:@"cityName"];
                           [self.weatherInfoModel saveWeatherDataToPlist:weatherDataCacheDictionary FromMain:false];
                           
                           NSString *cityDetialName = place.subLocality;                 // 获取二级城市名称
                           NSString *cityCode = [_weatherInfoModel translateCityNameToCityCode:cityName cityDetialName:cityDetialName];   // 获取城市代码
                           [wdata getWeatherInfoFromNetWithCityCode:cityCode model:_weatherInfoModel];                          // 从网上获取当地天气信息
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

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
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

#pragma mark - UI
// 去掉左侧留白
- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsZero;
}

// 展开／收起 监听
- (void)widgetActiveDisplayModeDidChange:(NCWidgetDisplayMode)activeDisplayMode withMaximumSize:(CGSize)maxSize {
    if (activeDisplayMode == NCWidgetDisplayModeExpanded) {
        self.preferredContentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, ExpandedHeight);
    }else {
        self.preferredContentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, CompactHeight);
    }
}

// 加载未来星期数
- (void)updateWeek:(UILabel *)weekLable week:(NSString *)week TemperatureUILable:(UILabel *)temperatureUILable Temperature:(NSString *)temperature  {
    [weekLable setText:week];
    // 设置不限制换行
    temperatureUILable.numberOfLines = 0;
    [temperatureUILable setTextColor:[UIColor blackColor]];
    [temperatureUILable setText:temperature];
}

- (void)openApp{
    NSURL *url = [NSURL URLWithString:@"myWeather://"];
    [self.extensionContext openURL:url completionHandler:nil];
}

@end
