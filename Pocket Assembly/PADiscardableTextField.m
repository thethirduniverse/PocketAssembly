//
//  GYDiscardableTextField.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/18/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PADiscardableTextField.h"
@interface PADiscardableTextField()
@property(strong,nonatomic)NSString* previousValue;
@end

@implementation PADiscardableTextField
-(NSString*)previousValue{
    return _previousValue;
}
-(void)setAndSaveText:(NSString*)string{
    self.previousValue=string;
    self.text=string;
}
-(void)keepChange{
    self.previousValue=self.text;
    //NSLog(@"change did save");
}
-(void)discardChange{
    self.text=self.previousValue;
    //NSLog(@"change did discard");
}

@end
