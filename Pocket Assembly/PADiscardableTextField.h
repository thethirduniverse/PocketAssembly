//
//  GYDiscardableTextField.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/18/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PADiscardableTextField : UITextField
-(NSString*)previousValue;
-(void)setAndSaveText:(NSString*)string;
-(void)keepChange;
-(void)discardChange;
@end
