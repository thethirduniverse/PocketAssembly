//
//  NSString+Substring.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 3/9/15.
//  Copyright (c) 2015 G. Yan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Substring)
/*
 This method returns the subtring up to (not including) the given string
 if the given string is not encountered, the original string is returned.
 */
-(NSString*)substringUpToString:(NSString*)str;
@end
