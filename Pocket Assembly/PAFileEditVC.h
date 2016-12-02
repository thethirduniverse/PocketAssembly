//
//  GYFileEditVC.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/19/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PAFileEditVC : UIViewController
-(void)setFile:(NSData*)file;
@property (nonatomic) BOOL enableEditing;
@end
