//
//  PALabelResolutionSign.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 3/11/15.
//  Copyright (c) 2015 G. Yan. All rights reserved.
//

#import "PALabelResolutionSign.h"

@implementation PALabelResolutionSign
-(instancetype)initWithLine:(PAInstructionLine*)line index:(Word)index{
    self=[super init];
    _line=line;
    _index=index;
    return self;
}
@end
