//
//  GYPAFileModel.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/21/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PAUtility.h"
@class PAError;
@class PABidirectionalDictionary;
@protocol PAFileModelDelegate
-(void) fileModelDidFailLoadingFileWithTitle:(NSString*)title Message:(NSString*)string;
@end

@interface PAFileModel : NSObject
+(instancetype)fileModelWithContent:(NSString*)content Error:(PAError*__strong*)error;
@property (nonatomic) Word startPosition;
@property (strong,nonatomic,readonly) NSMutableArray* machineCodes;
@property (strong,nonatomic) PABidirectionalDictionary* symbolTable;

//private, exposed for testing
+(BOOL)numberFromLiteral:(NSString*)str :(int*)num;
+(BOOL)registerNum:(NSString*)str :(Word*)num;
+(PAError*)checkRangeOfNumber:(int)num withLength:(PANumberLength)len;
+(NSString*)checkStringLiteral:(NSString*)str;
+(NSArray*)component:(NSArray*)comp fromType:(NSString*)type numberLength:(PANumberLength)numLength Error:(PAError*__strong*)error;
@end
