//
//  GYPAInstructionLine.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/21/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PAUtility.h"
#define kLabelKey @"label"
#define kLengthKey @"length"

/*
 An instruction line is defined as a single non-empty line that 
 has some meaning to the program.
 
 A line full of comments is not an instruction line, but a line that 
 contains an instuction or an assembler directive is. A line that contains
 nothing but a label is still an instruction line.
 
 An instruction line has to make sense. In other words, it has to be
 able to execute. it cannot be some random text that will not path the 
 test of assemblr.
 
 An instruction line is considered needsResolution if and only if
 it is label dependent. Like BR LABEL, .FILL LABEL etc.
 These instructions cannot be resolved into a instruction by it self.
 */
typedef enum{
    PALabelOnly,
    PANormalInstruction,
    PALabelResolutionInstruction,
    PALabelResolutionFill,
    PAOrigDirective,
    PAEndDirective,
    PAIsStringzDirective,
    PAIsBlkwDirective,
    PAIsFillDirective,
}PAInstructionLineType;

@interface PAInstructionLine : NSObject
/*
 The type of the current instruction
 */
@property (nonatomic) PAInstructionLineType insturctionType;
/* 
 The argument associated with the instruction. 
 In case of there is only a label, there will be no argument.
 In case of normal instruction, there will be no arguemnt.
 In case of label resolution instuction or a label resolution fill, this will
    be a dictionary with following format:
    {
        @"label":label,
        @"length":length of the offset in the argument, in case of BR, LD it is 9.
            In case of jsr, it is 11. The offset will be expanded(shrinked) to 
            fit the length given and inserted into the instuction field of this
            object. The offset is an int type enum (PANumberLength), wrapped
            in a NSNumber.
    }
 In case of .orig instruction, this will be an NSNumber wrapping
    an Word(unsigned short), which is the start address of the code.
 In case of .end instruction, this will be nil, as .end insturction doesn't have
    any real effect
 In case of .stringz instruction, this will be the string literal
 In case of .blkw instruction, this will be an NSNumber wrapping
    an int, which is the total length of the code.
 */
@property (nonatomic) NSObject* argument;
/*
 the label of the current instruction. If there is no 
 label associated with the current line, this will be nil
 Note: this is not the same label in the argument 
    incae resolution is needed
 */
@property (nonatomic) NSString* instructionlabel;
/*
 the binary representation of the current instruction.
 If it needs resolution of labels, the place of the label 
 will be blank
 */
@property (nonatomic) Word instrution;
@end