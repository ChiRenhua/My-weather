//
//  TodayViewController.m
//  Weather widget
//
//  Created by Martin on 15/12/4.
//  Copyright © 2015年 Martin. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#define WEATHER_IMAGE_WEIGHT 150
#define WEATHER_IMAGE_HEIGHT 150

@interface TodayViewController () <NCWidgetProviding>{

}
@property (nonatomic,strong) WeatherInfoModel *wim;        // 天气编码类
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

NSMutableDictionary *weatherDataCacheDictionary;  //天气数据缓存

@implementation TodayViewController

- (id)init{
    if (self = [super init]) {
        // 设置widget的宽高
        self.preferredContentSize = CGSizeMake(self.view.bounds.size.width, 170);
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
            
            // 当天温度
            NSString *Temperature = [[weatherInfoToday objectForKey:@"wendu"] stringByAppendingString:@"°"];
            // 获取当天的天气状态
            NSString *weatherType = [[recentWeatherInfo[0] objectForKey:@"day"] objectForKey:@"type"];
            // 天气状态
            NSString *weatherInfo = [[[@"现在" stringByAppendingString:weatherType] stringByAppendingString:@"，气温"] stringByAppendingString:Temperature];
            [weatherDataCacheDictionary setObject:weatherInfo forKey:@"weatherInfo"];
            // 显示当前的天气状态
            [weatherLable setText:weatherInfo];
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
            [weakSelf.wim saveWeatherDataToPlist:weatherDataCacheDictionary FromMain:false];
            
        };
        wdata = [[WeatherInfoFromNet alloc]init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UITapGestureRecognizer *tapGesture =[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openApp)];
    [self.view addGestureRecognizer:tapGesture];
    
    weatherLable = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width-50*4)/5, 10, 375, 30)];
    // 设置文字颜色
    weatherLable.textColor = [UIColor whiteColor];
    // 设置文字样式和大小
    weatherLable.font = [UIFont fontWithName:@"Arial" size:17];
    // 设置文字内容
    weatherLable.text = @"......";
    [self.view addSubview:weatherLable];
    
    /*
     * 向界面添加UIImageView，显示未来天气图标
     */
    // 初始化UIImageView，同时加上布局信息
    weatherImageview1 = [[UIImageView alloc]initWithFrame:CGRectMake((self.view.frame.size.width-50*4)/5, 75, WEATHER_IMAGE_WEIGHT/3, WEATHER_IMAGE_HEIGHT/3)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview1];
    
    // 初始化UIImageView，同时加上布局信息
    weatherImageview2 = [[UIImageView alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*2+50, 75, WEATHER_IMAGE_WEIGHT/3, WEATHER_IMAGE_HEIGHT/3)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview2];
    
    // 初始化UIImageView，同时加上布局信息
    weatherImageview3 = [[UIImageView alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*3+50*2, 75, WEATHER_IMAGE_WEIGHT/3, WEATHER_IMAGE_HEIGHT/3)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview3];
    
    // 初始化UIImageView，同时加上布局信息
    weatherImageview4 = [[UIImageView alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*4+50*3, 75, WEATHER_IMAGE_WEIGHT/3, WEATHER_IMAGE_HEIGHT/3)];
    // 添加图片到界面中
    [self.view addSubview:weatherImageview4];
    
    /*
     * 向界面添加UILable，显示未来天气温度
     */
    // 初始化UILable，同时加上布局信息
    temperatureLable1 = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width-50*4)/5-25, 110, 100, 50)];
    // 设置文字居中
    temperatureLable1.textAlignment = NSTextAlignmentCenter;
    // 设置文字颜色
    temperatureLable1.textColor = [UIColor whiteColor];
    // 设置文字样式和大小
    temperatureLable1.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字内容
    temperatureLable1.text = @"-°";
    // 添加文字到界面中
    [self.view addSubview:temperatureLable1];
    
    // 初始化UILable，同时加上布局信息
    temperatureLable2 = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*2+25, 110, 100, 50)];
    // 设置文字居中
    temperatureLable2.textAlignment = NSTextAlignmentCenter;
    // 设置文字颜色
    temperatureLable2.textColor = [UIColor whiteColor];
    // 设置文字样式和大小
    temperatureLable2.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字内容
    temperatureLable2.text = @"-°";
    // 添加文字到界面中
    [self.view addSubview:temperatureLable2];
    
    // 初始化UILable，同时加上布局信息
    temperatureLable3 = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*3+50*2-25, 110, 100, 50)];
    // 设置文字居中
    temperatureLable3.textAlignment = NSTextAlignmentCenter;
    // 设置文字颜色
    temperatureLable3.textColor = [UIColor whiteColor];
    // 设置文字样式和大小
    temperatureLable3.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字内容
    temperatureLable3.text = @"-°";
    // 添加文字到界面中
    [self.view addSubview:temperatureLable3];
    
    // 初始化UILable，同时加上布局信息
    temperatureLable4 = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*4+50*3-25, 110, 100, 50)];
    // 设置文字居中
    temperatureLable4.textAlignment = NSTextAlignmentCenter;
    // 设置文字颜色
    temperatureLable4.textColor = [UIColor whiteColor];
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
    weekLable1 = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width-50*4)/5-25, 50, 100, 30)];
    // 设置文字居中
    weekLable1.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weekLable1.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字颜色
    weekLable1.textColor = [UIColor whiteColor];
    // 设置文字内容
    weekLable1.text = @"——";
    // 添加文字到界面中
    [self.view addSubview:weekLable1];
    
    // 初始化UILable，同时加上布局信息
    weekLable2 = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*2+25, 50, 100, 30)];
    // 设置文字居中
    weekLable2.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weekLable2.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字颜色
    weekLable2.textColor = [UIColor whiteColor];
    // 设置文字内容
    weekLable2.text = @"——";
    // 添加文字到界面中
    [self.view addSubview:weekLable2];
    
    // 初始化UILable，同时加上布局信息
    weekLable3 = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*3+50*2-25, 50, 100, 30)];
    // 设置文字居中
    weekLable3.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weekLable3.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字颜色
    weekLable3.textColor = [UIColor whiteColor];
    // 设置文字内容
    weekLable3.text = @"——";
    // 添加文字到界面中
    [self.view addSubview:weekLable3];
    
    // 初始化UILable，同时加上布局信息
    weekLable4 = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width-50*4)/5)*4+50*3-25, 50, 100, 30)];
    // 设置文字居中
    weekLable4.textAlignment = NSTextAlignmentCenter;
    // 设置文字样式和大小
    weekLable4.font = [UIFont fontWithName:@"Arial" size:15];
    // 设置文字颜色
    weekLable4.textColor = [UIColor whiteColor];
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
                           NSString *cityDetialName = place.subLocality;                 // 获取二级城市名称
                           NSString *cityCode = [_wim translateCityNameToCityCode:cityName cityDetialName:cityDetialName];   // 获取城市代码
                           [wdata getWeatherInfoFromNetWithCityCode:cityCode model:_wim];                          // 从网上获取当地天气信息
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

//消除间隔
- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets{
    return UIEdgeInsetsMake(0,0,0,0);
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

- (void)openApp{
    NSURL *url = [NSURL URLWithString:@"myWeather://"];
    [self.extensionContext openURL:url completionHandler:nil];
}

@end