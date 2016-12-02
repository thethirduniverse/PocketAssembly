//
//  GYDisplayView.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/18/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PADisplayView.h"
@interface PADisplayView()
@property (nonatomic) const double pixelHeight;
@property (nonatomic) const double pixelWidth;
@property (nonatomic) Word* source;
@end

@implementation PADisplayView
-(void)loadDisplayFromSource:(Word*)source{
    self.source=source;
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    self.pixelWidth=self.bounds.size.width/128;
    self.pixelHeight=self.bounds.size.height/124;
    
    CGFloat drawWidth = ceil(self.pixelWidth);
    CGFloat drawHeight = ceil(self.pixelHeight);
    
    if (self.source!=NULL) {
        Word currentPointer=[PAUtility memoryIndexPathOffset][4];
        CGFloat height=0;
        for (int i=0; i<DISPLAY_PIXEL_VER; i++) {
            CGFloat width=0;
            for (int j=0; j<DISPLAY_PIXEL_HOR; j++) {
                Word content=_source[currentPointer++];
                CGFloat red=(CGFloat)((content>>DISPLAY_RED_SHIFT)&DISPLAY_COLOR_MASK)/31;
                CGFloat green=(CGFloat)((content>>DISPLAY_GREEN_SHIFT)&DISPLAY_COLOR_MASK)/31;
                CGFloat blue=(CGFloat)((content>>DISPLAY_BLUE_SHIFT)&DISPLAY_COLOR_MASK)/31;
                [[UIColor colorWithRed:red green:green blue:blue alpha:1] setFill];
                
                UIBezierPath* path=[UIBezierPath bezierPathWithRect:CGRectMake(ceil(width), ceil(height), drawWidth, drawHeight)];
                [path fill];
                width+=self.pixelWidth;
            }
            //width=0;
            height+=self.pixelHeight;
        }
    }
}


@end
