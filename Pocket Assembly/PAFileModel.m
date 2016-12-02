//
//  GYPAFileModel.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/21/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PAFileModel.h"
#import "PAInstructionLine.h"
#import "PAUtility.h"
#import "NSString+Substring.h"
#import "PAError.h"
#import "PABidirectionalDictionary.h"
#import "PALabelResolutionSign.h"
@interface PAFileModel()
@property (strong,nonatomic) NSMutableArray* instructions;
@end

@implementation PAFileModel
+(instancetype)fileModelWithContent:(NSString*)content Error:(PAError*__strong*)error{
        PAFileModel* fm=[[PAFileModel alloc]init];
        NSMutableArray* instructions = fm.instructions;
        BOOL isFirstLine=true;
        __block BOOL modelValid=true;
        //translating input
        [content enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            //process this single line
            //store temporaty instructions
            //resolve all instructions that is resolvable
            //resolve half way those are not resovalle, like BR
            //NSString* content=line;
            NSString* stringLiteral;
            NSRange range;
            //Remove Comments
            //everything after the first ; is considered comment and removed
            line = [line substringUpToString:@";"];
            
            //Find string literal
            //everything after teh first " is considered string literal, and extracted
            //more detailed examination will be performed later
            range=[line rangeOfString:@"\""];
            if (range.location!=NSNotFound) {
                stringLiteral=[[line substringFromIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                line=[line substringToIndex:range.location];
            }
            
            //extract contents
            NSMutableArray* components;
            line = [[line stringByReplacingOccurrencesOfString:@"( |\t|,)+" withString:@" " options:NSRegularExpressionSearch range:NSMakeRange(0,line.length)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            //seperate components
            if ([line isEqualToString:@""]) {
                return;
            }
            else{
                components = [[NSMutableArray alloc]initWithArray:[[line uppercaseString] componentsSeparatedByString:@" "]];
            }
            
            //add string literal to components
            if (stringLiteral) {
                [components addObject:stringLiteral];
            }
            
            //switch nickname of trap to formal instructions
            NSUInteger tempIndex;
            if ((tempIndex=[components indexOfObject:@"GETC"])!=NSNotFound) {
                [components replaceObjectsInRange:NSMakeRange(tempIndex, 1) withObjectsFromArray:@[@"TRAP",@"X20"]];
            }
            else if ((tempIndex=[components indexOfObject:@"OUT"])!=NSNotFound){
                [components replaceObjectsInRange:NSMakeRange(tempIndex, 1) withObjectsFromArray:@[@"TRAP",@"X21"]];
            }
            else if ((tempIndex=[components indexOfObject:@"PUTS"])!=NSNotFound){
                [components replaceObjectsInRange:NSMakeRange(tempIndex, 1) withObjectsFromArray:@[@"TRAP",@"X22"]];
            }
            else if ((tempIndex=[components indexOfObject:@"IN"])!=NSNotFound){
                [components replaceObjectsInRange:NSMakeRange(tempIndex, 1) withObjectsFromArray:@[@"TRAP",@"X23"]];
            }
            else if ((tempIndex=[components indexOfObject:@"PUTSP"])!=NSNotFound){
                [components replaceObjectsInRange:NSMakeRange(tempIndex, 1) withObjectsFromArray:@[@"TRAP",@"X24"]];
            }
            else if ((tempIndex=[components indexOfObject:@"HALT"])!=NSNotFound){
                [components replaceObjectsInRange:NSMakeRange(tempIndex, 1) withObjectsFromArray:@[@"TRAP",@"X25"]];
            }
            
            //try to seperate Label
            NSString* label;
            NSString* first = (NSString*)[components objectAtIndex:0];
            if (![[PAUtility validInstructions] containsObject:first]) {
                range = [first rangeOfString:@"([a-z]|[A-Z]|[0-9]|_)+" options:NSRegularExpressionSearch];
                if (range.location==NSNotFound||range.length!=first.length) {
                    *stop=true;
                    modelValid=false;
                    *error = [PAError errorWithType:PAErrorUnrecognizedToken Message:[NSString stringWithFormat:@"Label can only be composed of alphanumeric and underscore, got:%@",label]];
                    return;
                }
                label=first;
                [components removeObjectAtIndex:0];
            }
            
            PAInstructionLine* inst;
            //set empty components to nil
            if ([components count]==0) {
                inst = [[PAInstructionLine alloc]init];
                [inst setInsturctionType:PALabelOnly];
            }else{
                inst = [self instuctionFromComponents:components Error:error];
                if (!inst) {
                    *stop=true;
                    modelValid=false;
                    return;
                }
            }
            [inst setInstructionlabel:label];
            [instructions addObject:inst];
        }];
        
        /*
         return nil if unvalid
         error is already set
         */
        if(!modelValid){
            return nil;
        }
        
        //first pass
        //expand assembler directives
        //create symbol table
        if (isFirstLine) {
            if (((PAInstructionLine*)instructions[0]).insturctionType==PAOrigDirective) {
                [fm setStartPosition:[(NSNumber*)[instructions[0] argument] unsignedShortValue]];
            }
            else{
                [fm setStartPosition:0x3000];
            }
            isFirstLine=false;
        }
        
        PABidirectionalDictionary*symbolTable= (fm.symbolTable = [[PABidirectionalDictionary alloc] init]);
        NSMutableArray* resolutionSigns = [[NSMutableArray alloc]init];
        Word currentAddress=0;
        NSMutableArray* machineCodes = fm.machineCodes;
        //NSMutableArray* resolutionList=[[NSMutableArray alloc]init];
        NSString* danglingLabel;
        int loopTemp;
        
        //first pass
        for (PAInstructionLine* line in instructions) {
            if (line.instructionlabel) {
                if (danglingLabel) {
                    *error = [PAError errorWithType:PAErrorEmptyLabelEncountered Message:[NSString stringWithFormat:@"Builder encounterd empty label :%@. Please consider removing it.",line.instructionlabel]];
                    return nil;
                }
                if ([symbolTable containsString:line.instructionlabel]) {
                    *error = [PAError errorWithType:PAErrorDuplicateLabelEncountered Message:[NSString stringWithFormat:@"Builder encountered multiple declaration of the same label:%@",line.instructionlabel]];
                    return nil;
                }
                
                danglingLabel=line.instructionlabel;
            }
            if (line.insturctionType!=PALabelOnly) {
                if (danglingLabel) {
                    [symbolTable addPair:danglingLabel Word:currentAddress+fm.startPosition];
                    danglingLabel=nil;
                }
                if (line.insturctionType!=PAOrigDirective) {
                    if(line.insturctionType==PAIsBlkwDirective){
                        loopTemp = [(NSNumber*)line.argument unsignedShortValue];
                        for (int i=0; i<loopTemp; i++) {
                            [machineCodes addObject:[NSNumber numberWithUnsignedShort:0]];
                        }
                        currentAddress+=loopTemp;
                    }else if (line.insturctionType==PAIsStringzDirective){
                        loopTemp = (int)[(NSString*)line.argument length];
                        for (int i=0; i<loopTemp; i++) {
                            [machineCodes addObject:[NSNumber numberWithUnsignedShort:(Word)[(NSString*)line.argument characterAtIndex:i]]];
                        }
                        [machineCodes addObject:[NSNumber numberWithUnsignedShort:0]];
                        currentAddress+=loopTemp+1;
                    }else if (line.insturctionType==PALabelResolutionFill||line.insturctionType==PALabelResolutionInstruction){
                        [resolutionSigns addObject:[[PALabelResolutionSign alloc] initWithLine:line index:currentAddress]];
                        [machineCodes addObject:[NSNumber numberWithUnsignedShort:line.instrution]];
                        currentAddress++;
                    }
                    else {
                        [machineCodes addObject:[NSNumber numberWithUnsignedShort:line.instrution]];
                        currentAddress++;
                    }
                }
            }
        }
        
        //resolution of labels
        for (PALabelResolutionSign* sign in resolutionSigns) {
            Word word = [(NSNumber*)machineCodes[sign.index] unsignedShortValue];
            NSNumber* labelAddress = [symbolTable wordForString:[sign.line.argument valueForKey:kLabelKey]];
            if (labelAddress==nil) {
                *error = [PAError errorWithType:PAErrorUndeclaredLabelEncountered Message:[NSString stringWithFormat:@"Builder encountered undeclared label: %@",sign]];
                return nil;
            }
            if (sign.line.insturctionType==PALabelResolutionFill) {
                machineCodes[sign.index]=labelAddress;
            }
            else{
                Word offset = [PAUtility offsetFrom:sign.index+1 to:[labelAddress unsignedShortValue]-fm.startPosition length:(PANumberLength)[[sign.line.argument valueForKey:kLengthKey] intValue] Error:error];
                if (*error) {
                    return nil;
                }
                machineCodes[sign.index]=[NSNumber numberWithUnsignedShort:word|offset];
            }
        }
        
        //dangling label at the end is not allowed
        if (danglingLabel) {
            *error = [PAError errorWithType:PAErrorEmptyLabelEncountered Message:[NSString stringWithFormat:@"Builder encounterd empty label at the end:%@. Please consider removing it.",danglingLabel]];
            return nil;
        }
        return fm;
    }

+(PAInstructionLine*)instuctionFromComponents:(NSArray*)components Error:(PAError*__strong*)error{
    NSString* inst = components[0];
    NSArray* values; //holds the value of the components
    NSUInteger instructionIndex = [[PAUtility validInstructions] indexOfObject:inst];
    BOOL immediate=false;
    Word instruction=0;
    PAInstructionLine* l = [[PAInstructionLine alloc]init];
    [l setInsturctionType:PANormalInstruction];
    switch (instructionIndex) {
        case 0:
            instruction|=ADD_INS;
            goto l1;
        case 1:
            instruction|=AND_INS;
        l1:
            values = [self component:components fromType:@"RRR" numberLength:PANumberLength16 Error:error];
            if (!values) {
                *error=nil;
                values=[self component:components fromType:@"RRN" numberLength:PANumberLength16 Error:error];
                immediate=true;
                if (!values) {
                    return nil;
                }
            }
            instruction=[PAUtility put:[values[0] unsignedShortValue] into:instruction shiftBit:9 length:PANumberLength3];
            instruction=[PAUtility put:[values[1] unsignedShortValue] into:instruction shiftBit:6 length:PANumberLength3];
            if (immediate) {
                instruction|=ADD_AND_IMMEDIATE_BIT;
                instruction=[PAUtility put:[values[2] unsignedShortValue] into:instruction shiftBit:0 length:PANumberLength5];
            }else{
                instruction=[PAUtility put:[values[2] unsignedShortValue] into:instruction shiftBit:0 length:PANumberLength3];
            }
            break;
        case 2:
            values = [self component:components fromType:@"RR" numberLength:PANumberLength16 Error:error];
            if (!values) {
                return nil;
            }
            instruction|=NOT_INS;
            instruction=[PAUtility put:[values[0] unsignedShortValue] into:instruction shiftBit:9 length:PANumberLength3];
            instruction=[PAUtility put:[values[1] unsignedShortValue] into:instruction shiftBit:6 length:PANumberLength3];
            instruction|=_0_5_MASK;
            break;
        case 3:
            instruction|=ST_INS;
            goto l2;
        case 4:
            instruction|=STI_INS;
            goto l2;
        case 6:
            instruction|=LEA_INS;
            goto l2;
        case 7:
            instruction|=LD_INS;
            goto l2;
        case 8:
            instruction|=LDI_INS;
        l2:
            values=[self component:components fromType:@"RL" numberLength:PANumberLength9 Error:error];
            if (!values) {
                return nil;
            }
            instruction=[PAUtility put:[values [0]unsignedShortValue] into:instruction shiftBit:9 length:PANumberLength3];
            [l setInsturctionType:PALabelResolutionInstruction];
            [l setArgument:@{kLabelKey:values[1],kLengthKey:@(PANumberLength9)}];
            break;
        case 5:
            instruction|=STR_INS;
            goto l3;
        case 9:
            instruction|=LDR_INS;
        l3:
            values=[self component:components fromType:@"RRN" numberLength:PANumberLength6 Error:error];
            if (!values) {
                return nil;
            }
            instruction=[PAUtility put:[values[0] unsignedShortValue] into:instruction shiftBit:9 length:PANumberLength3];
            instruction=[PAUtility put:[values[1] unsignedShortValue] into:instruction shiftBit:6 length:PANumberLength3];
            instruction=[PAUtility put:[values[2] unsignedShortValue] into:instruction shiftBit:0 length:PANumberLength6];
            break;
        case 10:
        case 11:
        case 12:
        case 13:
        case 14:
        case 15:
        case 16:
        case 17:
            values=[self component:components fromType:@"L" numberLength:PANumberLength16 Error:error];
            if (!values) {
                return nil;
            }
            instruction|=BR_INS;
            for (int i=2; i<[inst length]; i++) {
                switch ([inst characterAtIndex:i]) {
                    case 'N':
                        instruction|=BR_N;
                        break;
                    case 'Z':
                        instruction|=BR_Z;
                        break;
                    case 'P':
                        instruction|=BR_P;
                        break;
                }
            }
            [l setInsturctionType:PALabelResolutionInstruction];
            [l setArgument:@{kLabelKey:values[0],kLengthKey:@(PANumberLength9)}];
            break;
        case 18:
            instruction|=JMP_INS;
            values = [self component:components fromType:@"R" numberLength:PANumberLength16 Error:error];
            if (!values) {
                return nil;
            }
            instruction=[PAUtility put:[values[0] unsignedShortValue] into:instruction shiftBit:6 length:PANumberLength3];
            break;
        case 19:
            instruction|=JSR_INS;
            instruction|=_11_MASK;
            values= [self component:components fromType:@"L" numberLength:PANumberLength11 Error:error];
            if (!values) {
                return nil;
            }
            [l setInsturctionType:PALabelResolutionInstruction];
            [l setArgument:@{kLabelKey:values[0],kLengthKey:@(PANumberLength11)}];
            break;
        case 20:
            values= [self component:components fromType:@"R" numberLength:PANumberLength16 Error:error];
            if (!values) {
                return nil;
            }
            instruction|=JSR_INS;
            instruction=[PAUtility put:[values[0] unsignedShortValue] into:instruction shiftBit:6 length:PANumberLength3];
            break;
        case 21:
            instruction|=RET_INS_FULL;
            break;
        case 22:
            NSLog(@"RTI encountered");
            instruction|=RTI_INS;
            break;
        case 23:
            values = [self component:components fromType:@"N" numberLength:PANumberLength8 Error:error];
            if (!values) {
                return nil;
            }
            instruction|=TRAP_INS;
            instruction=[PAUtility put:[values[0] unsignedShortValue] into:instruction shiftBit:0 length:PANumberLength8];
            break;
        case 24:
            //.FILL
            values= [self component:components fromType:@"N" numberLength:PANumberLength16 Error:error];
            if (!values) {
                *error=nil;
                values=[self component:components fromType:@"L" numberLength:PANumberLength16 Error:error];
                if (!values) {
                    return nil;
                }
                [l setInsturctionType:PALabelResolutionFill];
                [l setArgument:@{kLabelKey:values[0],kLengthKey:@(PANumberLength16)}];
            }
            else {
                instruction=(Word)[(NSNumber*)values[0] intValue];
                [l setInsturctionType:PAIsFillDirective];
            }
            break;
        case 25:
            //.STRINGZ
            values= [self component:components fromType:@"S" numberLength:PANumberLength16 Error:error];
            [l setInsturctionType:PAIsStringzDirective];
            [l setArgument:values[0]];
            break;
        case 26:
            //.BLKW
            values= [self component:components fromType:@"N" numberLength:PANumberLength16 Error:error];
            if (!values) {
                return nil;
            }
            [l setInsturctionType:PAIsBlkwDirective];
            [l setArgument:values[0]];
            break;
        case 27:
            //.ORIG
            NSLog(@"encountered .orig");
            values = [self component:components fromType:@"N" numberLength:PANumberLength16 Error:error];
            if (!values) {
                return nil;
            }
            [l setInsturctionType:PAOrigDirective];
            [l setArgument:values[0]];
            break;
        case 28:
            //.END
            NSLog(@"encounterd . end");
            [l setInsturctionType:PAEndDirective];
            break;
        default:
            *error = [PAError errorWithType:PAErrorUnrecognizedToken Message:[NSString stringWithFormat:@"Unrecognized instruction name, got:%@",inst]];
            return nil;
            break;
    }
    [l setInstrution:instruction];
    return l;
}

//test covered

+(NSString*)explanationForType:(NSString*)type{
    NSMutableString* ms=[[NSMutableString alloc]init];
    for (int i=0; i<type.length; i++) {
        switch ([type characterAtIndex:i]) {
            case 'R':
                [ms appendString:@"Register "];
                break;
            case 'N':
                [ms appendString:@"NumberLiteral "];
                break;
            case 'L':
                [ms appendString:@"Label"];
                break;
            case 'S':
                [ms appendString:@"StringLiteral"];
                break;
            default:
                NSLog(@"Unrecognized Type Specifier Encountered");
                break;
        }
    }
    return ms;
}


/*
 The extracted values of the instruction
 For example "ADD R0 R0 #3" is extracted as [0,0,3]
 The instruction name is omitted
 */
+(NSArray*)component:(NSArray*)comp fromType:(NSString*)type numberLength:(PANumberLength)numLength Error:(PAError*__strong*)error{
    NSMutableArray* ma=[[NSMutableArray alloc]init];
    if (comp.count!=type.length+1) {
        //*error = [PAError errorWithType:PAErrorUnexpectedArgumentList Message:[NSString stringWithFormat:@"Expected:%@ got:%@",[self explanationForType:type],[comp description]]];
        return nil;
    }
    for (int i=0; i<type.length; i++) {
        if ([type characterAtIndex:i]=='R') {
            Word sr;
            if (![self registerNum:comp[i+1] :&sr]) {
                *error = [PAError errorWithType:PAErrorUnrecognizedToken Message:[NSString stringWithFormat:@"Expected a register between R0 and R7, got:%@",comp[i+1]]];
                return nil;
            }

            [ma addObject:[NSNumber numberWithInt:sr]];
        }
        else if ([type characterAtIndex:i]=='N'){
            int num;
            if (![self numberFromLiteral:comp[i+1] :&num]) {
                *error = [PAError errorWithType:PAErrorUnrecognizedToken Message:[NSString stringWithFormat:@"Expected a number, got:%@",comp[i+1]]];
                return nil;
            }
            
            *error = [PAFileModel checkRangeOfNumber:num withLength:numLength];
            
            if (*error) {
                return nil;
            }
            
            [ma addObject:[NSNumber numberWithUnsignedShort:(Word)num]];
        }
        else if ([type characterAtIndex:i]=='L'){
            //label as arguement
            [ma addObject:comp[i+1]];
        }
        else if([type characterAtIndex:i]=='S'){
            NSString* str = comp[i+1];
            NSString* res = nil;
            res = [PAFileModel checkStringLiteral:str];
            
            if (!res) {
                *error = [PAError errorWithType:PAErrorUnrecognizedToken Message:[NSString stringWithFormat:@"Invalid string literal. It must be covered in quotes and properly escaped, got:%@",comp[i+1]]];
                return nil;
            }
            
            [ma addObject:res];
        }
    }
    return ma;
}

+(NSString*)checkStringLiteral:(NSString*)str{
    return [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:NULL];
}


+(PAError*)checkRangeOfNumber:(int)num withLength:(PANumberLength)len{
    PAError* error = nil;
    switch (len) {
        case PANumberLength5:
            if (num<_PC_OFFSET_5_MIN||num>_PC_OFFSET_5_MAX) {
                error = [PAError errorWithType:PAErrorLiteralOutOfRange Message:[NSString stringWithFormat:@"literal must be between -16 to 15, got:%d",num]];
            }
            break;
        case PANumberLength6:
            if (num<_PC_OFFSET_6_MIN||num>_PC_OFFSET_6_MAX) {
                error = [PAError errorWithType:PAErrorLiteralOutOfRange Message:[NSString stringWithFormat:@"literal must be between -32 to 31, got:%d",num]];
            }
            break;
        case PANumberLength8:
            if (num<_PC_OFFSET_8_MIN||num>_PC_OFFSET_8_MAX) {
                error = [PAError errorWithType:PAErrorLiteralOutOfRange Message:[NSString stringWithFormat:@"literal must be between -128 to 127, got:%d",num]];
            }
            break;
        case PANumberLength9:
            if (num<_PC_OFFSET_9_MIN||num>_PC_OFFSET_9_MAX) {
                error = [PAError errorWithType:PAErrorLiteralOutOfRange Message:[NSString stringWithFormat:@"literal must be between -256 to 255, got:%d",num]];
            }
            break;
        case PANumberLength11:
            if (num<_PC_OFFSET_11_MIN||num>_PC_OFFSET_11_MAX) {
                error = [PAError errorWithType:PAErrorLiteralOutOfRange Message:[NSString stringWithFormat:@"literal must be between -1024 to 1023, got:%d",num]];
            }
            break;
        case PANumberLength16:
            //if (num<_PC_OFFSET_16_MIN||num>_PC_OFFSET_16_MAX) {
            //    error = [PAError errorWithType:PAErrorLiteralOutOfRange Message:[NSString stringWithFormat:@"literal must be between -32768 to 32767, got:%d",num]];
            //}
            break;
        default:
            error = [PAError errorWithType:PAErrorImpossibleOperation Message:@"(Internal Error) This offset is unsuitable for a number literal, please make sure the correct interpretation of commands"];
        
    }
    return error;
}

/*
 Strip out the register number as an int and stores it in the address provided
 if the string doesn't start with 'R' or what follows the 'R' isn't a number
 that is between 0 and 8 then false is returned. Otherwise, true is returned.
 */
+(BOOL)registerNum:(NSString*)str :(Word*)num{
    if ([str characterAtIndex:0]!='R' || str.length!=2){
        return false;
    }
    unichar c = [str characterAtIndex:1];
    if (c<'0'||c>'7') {
        return false;
    }
    *num = (Word)c-NUM_CHAR_DIFFERENCE;
    return true;
}
/*
 Strip out the number as an int and stores it in the address provided. If the process
 is successful, true is returned, otherwise false is returned.
 Recognized format:
 '#' + decimal numbers
 pure decimal numbers
 '0x/0X'+ hexadecimal numbers
 'x/X' + hexadecimal numbers
 the string is converted to upper case by this point
 */
+(BOOL)numberFromLiteral:(NSString*)str :(int*)num{
    //decimal
    if ([str characterAtIndex:0]=='#') {
        NSScanner* scan = [NSScanner scannerWithString:[str substringFromIndex:1]];
        return [scan scanInt:num]&&[scan isAtEnd];
    }
    //hex that starts with an 'x'
    else if ([str characterAtIndex:0]=='X'){
        NSScanner* scan = [NSScanner scannerWithString:[str substringFromIndex:1]];
        unsigned int t;
        BOOL suc = [scan scanHexInt:&t];
        *num=(int)t;
        return suc&&[scan isAtEnd];
    }
    //hex that starts with 0x
    else if([str hasPrefix:@"0X"]){
        NSScanner* scan = [NSScanner scannerWithString:str];
        unsigned int t;
        BOOL suc = [scan scanHexInt:&t];
        *num=(int)t;
        return suc&&[scan isAtEnd];
    }
    //decimal numbers that doesn't have prefix
    else{
        NSScanner* scan = [NSScanner scannerWithString:str];
        return [scan scanInt:num]&&[scan isAtEnd];
    }
}

-(instancetype)init{
    self=[super init];
    self.instructions=[[NSMutableArray alloc]init];
    _machineCodes=[[NSMutableArray alloc]init];
    return self;
}
@end
