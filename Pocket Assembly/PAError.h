//
//  PAError.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 3/9/15.
//  Copyright (c) 2015 G. Yan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    PAErrorUnexpectedArgumentList,
    PAErrorLiteralOutOfRange,
    PAErrorUnrecognizedToken,
    PAErrorImpossibleOperation,
    PAErrorEmptyLabelEncountered,
    PAErrorDuplicateLabelEncountered,
    PAErrorUndeclaredLabelEncountered,
    PAErrorLabelOutsideReach
}PAErrorType;

@interface PAError : NSError
-(instancetype)initWithType:(PAErrorType)type Message:(NSString*)message;
+(instancetype)errorWithType:(PAErrorType)type Message:(NSString*)message;
+(NSString*)titleForErrorType:(PAErrorType)type;
@property (nonatomic) PAErrorType type;
@property (strong,nonatomic) NSString* message;
@end
