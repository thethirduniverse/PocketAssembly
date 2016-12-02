//
//  GYRegistersDisplayCell.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/18/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PAUtility.h"

@interface PARegistersDisplayCell : UICollectionViewCell
-(void)configureWithTitle:(NSUInteger)location Value:(Word)value;
-(void)keepChange;
-(void)discardChange;
@end
