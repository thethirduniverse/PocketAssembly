//
//  NSString+Substring.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 3/9/15.
//  Copyright (c) 2015 G. Yan. All rights reserved.
//

#import "NSString+Substring.h"

@implementation NSString (Substring)
-(NSString*)substringUpToString:(NSString*)str{
    NSRange range = [self rangeOfString:str];
    return range.location==NSNotFound?self:[self substringToIndex:range.location];
}
@end
