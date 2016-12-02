//
//  PALabelResolutionSign.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 3/11/15.
//  Copyright (c) 2015 G. Yan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PAUtility.h"
@class PAInstructionLine;

/*
 This marks a line that needs resolution of labels
 */
@interface PALabelResolutionSign : NSObject

@property (strong,nonatomic) PAInstructionLine* line;
/*
 the index of current instruction in the machinecodes array
 index+1 is the (incremented) PC at that position
 we can use indes+1 as if it is the PC, because all label resolution
 uses relative model
 */
@property (nonatomic) Word index;

-(instancetype)initWithLine:(PAInstructionLine*)line index:(Word)index;
@end
