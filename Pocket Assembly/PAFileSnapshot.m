//
//  GYFileSnapshot.m
//  boringtest
//
//  Created by Guanqing Yan on 12/26/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PAFileSnapshot.h"

@implementation PAFileSnapshot
-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.createDate forKey:kCreateDateKey];
    [aCoder encodeObject:self.modificationDate forKey:kModificationDateKey];
    [aCoder encodeBool:self.isProtected forKey:kIsProtectedKey];
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self.createDate=[aDecoder decodeObjectForKey:kCreateDateKey];
    self.modificationDate=[aDecoder decodeObjectForKey:kModificationDateKey];
    self.isProtected=[aDecoder decodeBoolForKey:kIsProtectedKey];
    return self;
}
-(instancetype)init{
    self=[super init];
    self.createDate=[[NSDate alloc]init];
    self.modificationDate=self.createDate;
    self.isProtected=false;
    return self;
}
@end
