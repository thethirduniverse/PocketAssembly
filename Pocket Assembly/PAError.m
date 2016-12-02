//
//  PAError.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 3/9/15.
//  Copyright (c) 2015 G. Yan. All rights reserved.
//

#import "PAError.h"
@interface PAError()

@end

@implementation PAError
-(instancetype)initWithType:(PAErrorType)type Message:(NSString*)message{
    self = [super initWithDomain:message code:0 userInfo:nil];
    _type=type;
    _message=message;
    return self;
}
+(instancetype)errorWithType:(PAErrorType)type Message:(NSString*)message{
    PAError* e = [[PAError alloc] initWithDomain:message code:0 userInfo:nil];
    e.type = type;
    e.message = message;
    return e;
}
+(NSString*)titleForErrorType:(PAErrorType)type{
    static dispatch_once_t onceToken;
    static NSArray* titles = nil;
    dispatch_once(&onceToken,^{
        titles = @[@"Unexpected Argument List",
                   @"Literal Out Of Range",
                   @"Unrecognized Token",
                   @"Impossible Operation",
                   @"Empty Label Encountered",
                   @"Duplicate Label Encountered",
                   @"Undeclared Label Encountered",
                   @"Label Out Of Reach"
                   ];
    });
    switch (type) {
        case PAErrorUnexpectedArgumentList:
            return titles[0];
        case PAErrorLiteralOutOfRange:
            return titles[1];
        case PAErrorUnrecognizedToken:
            return titles[2];
        case PAErrorImpossibleOperation:
            return titles[3];
        case PAErrorEmptyLabelEncountered:
            return titles[4];
        case PAErrorDuplicateLabelEncountered:
            return titles[5];
        case PAErrorUndeclaredLabelEncountered:
            return titles[6];
        case PAErrorLabelOutsideReach:
            return titles[7];
    }
    
}
@end