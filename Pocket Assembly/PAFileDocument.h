//
//  GYFileDocument.h
//  boringtest
//
//  Created by Guanqing Yan on 12/26/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PAFileSnapshot;
@interface PAFileDocument : UIDocument
-(NSData*)file;
-(void)setFile:(NSData*)file;
@property (strong,nonatomic) PAFileSnapshot* snapshot;
@end
