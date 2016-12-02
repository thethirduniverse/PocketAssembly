//
//  GYConsoleView.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/18/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PAConsoleView.h"
@interface PAConsoleView()
@end
@implementation PAConsoleView

//-(void)layoutSubviews{
//    [super layoutSubviews];
//    //UIView* textContainerView = [self performSelector:NSSelectorFromString(@"_textContainerView")];
//    //[textContainerView setFrame:self.bounds];
//    for (UIView* subview in self.subviews) {
//        if ([subview isKindOfClass:NSClassFromString(@"_UITextContainerView")]) {
//            [subview setFrame:self.bounds];
//        }
//    }
//}

-(void)put:(Word)word{
    [self setText:[self.text stringByAppendingString:[NSString stringWithFormat:@"%c",(char)word]]];
    CGFloat height = ceilf([self sizeThatFits:self.frame.size].height);
    [self scrollRectToVisible:CGRectMake(0, height-1, 1, 1) animated:true];
    //[self scrollRangeToVisible:NSMakeRange([self.text length]-2, 1)];
}

@end
