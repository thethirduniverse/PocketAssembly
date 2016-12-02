//
//  GYPAMdlDcdExctnOperation.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/12/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PAMdlDcdExctnOperation.h"
#import "PAModel.h"
@interface PAMdlDcdExctnOperation(){
    PAExecuteMode _mode;
}
@property (nonatomic,weak) PAModel<PAMdlDcdExctnOperationDelegate>* model;
@end
@implementation PAMdlDcdExctnOperation
-(instancetype)initWithModel:(PAModel*)model Mode:(PAExecuteMode)mode{
    self=[super init];
    self.model=model;
    _mode=mode;
    return self;
}
-(void)main{
    //will step into subrutines
    if (_mode==PAExecuteModeStep) {
        [self decodeAndExecute];
    }
    else if(_mode==PAExecuteModeNext){
        if ([self willJumpToSubRoutine]) {
            //potentially faulty algorithm, but will do for most cases
            Word pc = [self.model PC]+1;
            do{
                [self decodeAndExecute];
            }while (self.model.PC!=pc&&![self isCancelled]&&![self.model isAtBreakPoint]);
        }else{
            [self decodeAndExecute];
        } 
    }
    else if(_mode==PAExecuteModeRun){
        do{
            [self decodeAndExecute];
        }while (![self.model isAtBreakPoint]&&![self isCancelled]);
    }
    else{
        NSLog(@"unrecognized operation mode");
    }
    //NSLog(@"operationDidFinish");
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.model operationDidFinish];
    }];
}
//-(BOOL)willReturnFromSubRoutine{
//    Word instruction = [self.model memoryFromLocation:self.model.PC]&RET_MASK;
//    return instruction==RET_INS_FULL;
//}
-(BOOL)willJumpToSubRoutine{
    Word instruction = [self.model memoryFromLocation:self.model.PC]&INSTRUCTION_MASK;
    return instruction==JSR_INS||instruction==TRAP_INS;
}
-(void)decodeAndExecute{
    Word inst = [self.model memoryFromLocation:self.model.PC];
    Word* rst = [self.model registers];
    Word temp=0; /*holds the temporary results of various operations*/
    BOOL setCC=false; /*store if the current instruction needs to set condition code*/
    Word loadFromAddress;
    self.model.PC++;
    
    switch (inst&INSTRUCTION_MASK) {
        case ADD_INS:
            //immediate 5
            if (inst&_5_MASK) {
                temp=rst[(inst&_6_8_MASK)>>_6_8_SHFTBIT]+[PAUtility sext_5:inst&_0_4_MASK];
            }
            //offset
            else{
                temp=rst[(inst&_6_8_MASK)>>_6_8_SHFTBIT]+rst[inst&_0_2_MASK];
            }
            rst[(inst&_9_11_MASK)>>_9_11_SHFTBIT]=temp;
            setCC=true;
            break;
        case AND_INS:
            //immediate 5
            if (inst&_5_MASK) {
                temp=rst[(inst&_6_8_MASK)>>_6_8_SHFTBIT]&[PAUtility sext_5:inst&_0_4_MASK];
            }
            //offset
            else{
                temp=rst[(inst&_6_8_MASK)>>_6_8_SHFTBIT]&rst[inst&_0_2_MASK];
                
            }
            rst[(inst&_9_11_MASK)>>_9_11_SHFTBIT]=temp;
            setCC=true;
            break;
        case BR_INS:
            if (((inst&_9_11_MASK)>>_9_11_SHFTBIT)&self.model.CC) {
                self.model.PC=self.model.PC+[PAUtility sext_9:inst&_0_8_MASK];
            }
            break;
        case JMP_INS:
            self.model.PC=rst[(inst&_6_8_MASK)>>_6_8_SHFTBIT];
            break;
        case JSR_INS:
            //JSR
            rst[7]=self.model.PC;
            if (inst&_11_MASK) {
                self.model.PC=self.model.PC+[PAUtility sext_11:inst&_0_10_MASK];
            }
            //JSRR
            else{
                self.model.PC=rst[(inst&_6_8_MASK)>>_6_8_SHFTBIT];
            }
            break;
        case LD_INS:
            loadFromAddress=self.model.PC+[PAUtility sext_9:inst&_0_8_MASK];
            temp = [self.model memoryFromLocation:loadFromAddress];
            rst[(inst&_9_11_MASK)>>_9_11_SHFTBIT]=temp;
            /*Once content at Keyboard_Data_Register has been read, we need to set the keyboard status to false,
             to wait for the next input(if there is any).*/
            if (loadFromAddress==Keyboard_Data_Register) {
                [self.model setKeyboardStatus:false];
            }
            setCC=true;
            break;
        case LDI_INS:
            loadFromAddress=[self.model memoryFromLocation:self.model.PC+[PAUtility sext_9:inst&_0_8_MASK]];
            temp = [self.model memoryFromLocation:loadFromAddress];
            rst[(inst&_9_11_MASK)>>_9_11_SHFTBIT]=temp;
            /*Once content at Keyboard_Data_Register has been read, we need to set the keyboard status to false,
             to wait for the next input(if there is any).*/
            if (loadFromAddress==Keyboard_Data_Register) {
                [self.model setKeyboardStatus:false];
            }
            setCC=true;
            break;
        case LDR_INS:
            loadFromAddress=rst[(inst&_6_8_MASK)>>_6_8_SHFTBIT]+[PAUtility sext_6:inst&_0_5_MASK];
            temp=[self.model memoryFromLocation:loadFromAddress];
            rst[(inst&_9_11_MASK)>>_9_11_SHFTBIT]=temp;
            /*Once content at Keyboard_Data_Register has been read, we need to set the keyboard status to false,
             to wait for the next input(if there is any).*/
            if (loadFromAddress==Keyboard_Data_Register) {
                [self.model setKeyboardStatus:false];
            }
            setCC=true;
            break;
        case LEA_INS:
            temp=self.model.PC+[PAUtility sext_9:inst&_0_8_MASK];
            rst[(inst&_9_11_MASK)>>_9_11_SHFTBIT]=temp;
            setCC=true;
            break;
        case NOT_INS:
            temp=_0_15_MASK-rst[(inst&_6_8_MASK)>>_6_8_SHFTBIT];
            rst[(inst&_9_11_MASK)>>_9_11_SHFTBIT]=temp;
            setCC=true;
            break;
        case RTI_INS:
            //unimplemeted
            NSLog(@"RTI instruction is currently unsupported");
            break;
        case ST_INS:
            [self.model setMemoryAtLocation:self.model.PC+[PAUtility sext_9:inst&_0_8_MASK] newValue:rst[(inst&_9_11_MASK)>>_9_11_SHFTBIT]];
            break;
        case STI_INS:
            [self.model setMemoryAtLocation:[self.model memoryFromLocation:self.model.PC+[PAUtility sext_9:inst&_0_8_MASK]] newValue:rst[(inst&_9_11_MASK)>>_9_11_SHFTBIT]];
            break;
        case STR_INS:
            [self.model setMemoryAtLocation:rst[(inst&_6_8_MASK)>>_6_8_SHFTBIT]+[PAUtility sext_6:inst&_0_5_MASK] newValue:rst[(inst&_9_11_MASK)>>_9_11_SHFTBIT]];
            break;
        case TRAP_INS:
            rst[7]=self.model.PC;
            self.model.PC=[self.model memoryFromLocation:[PAUtility zext_8:inst&_0_7_MASK]];
            break;
        default:
            break;
    }
    
    if (setCC) {
        if (temp&_15_MASK) {
            self.model.CC=CCn;
        }
        else if(temp){
            self.model.CC=CCp;
        }
        else{
            self.model.CC=CCz;
        }
    }
}
@end
