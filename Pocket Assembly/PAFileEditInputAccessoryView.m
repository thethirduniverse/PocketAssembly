//
//  GYFileEditInputAccessoryView.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 1/16/15.
//  Copyright (c) 2015 G. Yan. All rights reserved.
//

#import "PAFileEditInputAccessoryView.h"
#import "PAUtility.h"

@interface PAFileEditInputAccessoryView()

@end


@implementation PAFileEditInputAccessoryView
-(void)awakeFromNib{
    [super awakeFromNib];
    for (UIView* view in self.subviews) {
        [view.layer setCornerRadius:INPUT_ACCESSORY_VIEW_BUTTON_CONNER_RADIUS];
        [view.layer setShadowOffset:(CGSize){0,1}];
        [view.layer setShadowRadius:0];
        [view.layer setShadowOpacity:0.5];
    }
}
-(IBAction)tapped:(UIButton*)button{
    [[UIDevice currentDevice]playInputClick];
    if (self.delegate) {
        //NSLog(@"%c",(char)button.tag);
        [self.delegate addString:[NSString stringWithFormat:@"%c",(char)button.tag]];
    }
}
-(BOOL)enableInputClicksWhenVisible{
    return true;
}
@end
