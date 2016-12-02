//
//  GYFileSnapshot.h
//  boringtest
//
//  Created by Guanqing Yan on 12/26/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kFileNameKey @"filename"
#define kCreateDateKey @"createDate"
#define kModificationDateKey @"modificationDate"
#define kIsProtectedKey @"isProtected"
#define kSnapshotKey @"snapshot"
#define kContentKey @"content"


@interface PAFileSnapshot : NSObject <NSCoding>
@property (nonatomic,strong) NSDate* createDate;
@property (nonatomic,strong) NSDate* modificationDate;
@property (nonatomic) BOOL isProtected;
@end
