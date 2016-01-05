//
//  AppDelegate.h
//  My weather
//
//  Created by lgy on 15/11/27.
//  Copyright © 2015年 Martin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^EnterForeground)();
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, copy) EnterForeground enterForeground;


@end

