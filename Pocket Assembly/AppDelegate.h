//
//  AppDelegate.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/8/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PAInterfaceVC;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong,nonatomic) PAInterfaceVC* mainInterface;
@end

