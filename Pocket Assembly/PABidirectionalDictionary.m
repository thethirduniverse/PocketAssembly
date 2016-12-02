//
//  GYBDDictionary.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/18/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PABidirectionalDictionary.h"
@interface PABidirectionalDictionary()
@property (nonatomic,strong) NSMutableDictionary* w2s;
@property (nonatomic,strong) NSMutableDictionary* s2w;
@end

@implementation PABidirectionalDictionary
-(instancetype)init{
    self=[super init];
    self.w2s=[[NSMutableDictionary alloc]init];
    self.s2w=[[NSMutableDictionary alloc]init];
    return self;
}
-(BOOL)containsString:(NSString*)string{
    return [self.s2w objectForKey:string]!=nil;
}
-(BOOL)containsWord:(NSNumber *)word{
    return [self.w2s objectForKey:word]!=nil;
}
-(NSNumber*)wordForString:(NSString*)string{
    return [self.s2w objectForKey:string];
}
-(NSString*)stringForWord:(Word)word{
    return [self.w2s objectForKey:[NSNumber numberWithUnsignedShort:word]];
}
-(void)addPair:(NSString*)string Word:(Word)word{
    NSNumber* wd=[NSNumber numberWithUnsignedShort:word];
    [self.w2s setObject:string forKey:wd];
    [self.s2w setObject:wd forKey:string];
}
-(void)mergeWith:(PABidirectionalDictionary*)anotherDic{
    [self.w2s addEntriesFromDictionary:[anotherDic w2s]];
    [self.s2w addEntriesFromDictionary:[anotherDic s2w]];
}
-(void)reset{
    [self.w2s removeAllObjects];
    [self.s2w removeAllObjects];
}
@end
