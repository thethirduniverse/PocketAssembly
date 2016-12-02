//
//  GYPAMdlDcdExctnOperation.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/12/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PAUtility.h"
@class PAModel;

/*the model needs to be informed once the operation has finished*/
@protocol PAMdlDcdExctnOperationDelegate
@required
-(void) operationDidFinish;
@end

/*
 This operation performs the fetch-decode-execute cycle of the simulator.
 Three different PAExecuteMode is supported:
    1.PAExecuteModeRun:    cotinue the cycle infinitely, until the operation
        has been cancelled or an breakpoint has been encountered
    2.PAExecuteModeStep:   continue the cycle one time, jump into subroutines 
        if needed
    3.PAExecuteModeNext:   continue the cycle, until the next line of the source
        code is reached. In other words, this is a step that will not jump into
        subroutines
 */
@interface PAMdlDcdExctnOperation : NSOperation
-(instancetype)initWithModel:(PAModel*)model Mode:(PAExecuteMode)mode;
@end
