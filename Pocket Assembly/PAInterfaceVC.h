//
//  ViewController.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/8/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PAModel.h"
@class PAFileModel;
@interface PAInterfaceVC : UIViewController<UITextFieldDelegate,PAModelDelegate>
-(BOOL)loadModel:(PAFileModel*)model;
-(BOOL)loadFileWithURL:(NSURL*)fileURL;
-(void)presentAlertWhenReady:(UIAlertController*)alert;
@end

