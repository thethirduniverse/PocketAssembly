//
//  GYBDDictionary.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/18/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PAUtility.h"

//A bidirectional dictionary that takes a word and a nsstring
//this could be written as in favor of more generality
//but in the absense of generics(as in java), we have to
//constantly cast the types. So I used a more specific implementation
//in this class. Modifications for other uses should be easy to
//implement with some modifications
//word is wrapped in NSnumber as to permit null
@interface PABidirectionalDictionary : NSObject
-(NSNumber*)wordForString:(NSString*)string;
-(NSString*)stringForWord:(Word)word;
-(BOOL)containsString:(NSString*)string;
-(BOOL)containsWord:(NSNumber *)word;
-(void)addPair:(NSString*)string Word:(Word)word;
-(void)mergeWith:(PABidirectionalDictionary*)anotherDic;
-(void)reset;
@end
