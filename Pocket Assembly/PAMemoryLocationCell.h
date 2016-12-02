//
//  GYMemoryLocationCell.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/12/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PAModel.h"

@interface PAMemoryLocationCell : UITableViewCell
-(void)configureWithAddress:(Word)address Label:(NSString*)label Content:(Word)content Interpretation:(NSString*)interpretation;
@end
