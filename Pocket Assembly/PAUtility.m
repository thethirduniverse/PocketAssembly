//
//  GYPAUtility.m
//  PAtest
//
//  Created by Guanqing Yan on 12/16/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PAUtility.h"
#import <UIKit/UIKit.h>

@implementation PAUtility

#pragma mark Instructions
+(NSArray*)validInstructions{
    static dispatch_once_t onceToken;
    static NSArray* instructions = nil;
    dispatch_once(&onceToken,^{
        instructions = @[@"ADD",@"AND",@"NOT",@"ST",@"STI",
                         @"STR",@"LEA",@"LD",@"LDI",@"LDR",
                         @"BRN",@"BRZ",@"BRP",@"BRNZ",@"BRNP",
                         @"BRZP",@"BRNZP",@"BR",@"JMP",@"JSR",@"JSRR",
                         @"RET",@"RTI",@"TRAP",@".FILL",@".STRINGZ",
                         @".BLKW",@".ORIG",@".END"];
    });
    return instructions;
}
+(NSArray*)labelDependentInstructions{
    static dispatch_once_t onceToken;
    static NSArray* instructions = nil;
    dispatch_once(&onceToken,^{
        instructions = @[@"ST",@"STI",@"LEA",@"LD",@"LDI",@"BRN",@"BRZ",@"BRP",@"BRNZ",@"BRNP",@"BRZP",@"BRNZP",@"BR",@"JSR"];
    });
    return instructions;
}

#pragma mark memory sections
+(NSArray*)memorySectionTitles{
    static dispatch_once_t onceToken;
    static NSArray* memorySectionTitles = nil;
    dispatch_once(&onceToken,^{
        memorySectionTitles = @[@"Trap Vector Table",@"Interrupt Vector Table",@"Operating System",@"User Code",@"Video Output",@"Device Register Addressed"];
    });
    return memorySectionTitles;
}
+(NSUInteger*)memorySectionLengths{
    static NSUInteger memorySectionLengths[6] = {0x100,0x100,0x2E00,0x9000,0x3E00,0x200};
    return memorySectionLengths;
}
+(Word*)memoryIndexPathOffset{
    static Word memoryIndexPathOffset[6] = {0x0000,0x0100,0x0200,0x3000,0xC000,0xFE00};
    return memoryIndexPathOffset;
}
+(NSIndexPath*)indexPathFromLocation:(Word)location{
    for (int i=5; i>=0; i--) {
        if (location>=[self memoryIndexPathOffset][i]) {
            return [NSIndexPath indexPathForRow:location-[self memoryIndexPathOffset][i] inSection:i];
        }
    }
    return nil;
}
+(Word)locationFromIndexPath:(NSIndexPath*)indexPath{
    return [self memoryIndexPathOffset][indexPath.section]+indexPath.row;
}

#pragma mark registers
+(NSArray*)registerNames{
    static dispatch_once_t onceToken;
    static NSArray *registerNames;
    dispatch_once(&onceToken,^{
        registerNames=@[@"R0",@"R1",@"R2",@"R3",@"R4",@"R5",@"R6",@"R7",@"PC",@"CC",@"PSR",@"MPR"];
    });
    return registerNames;
}

#pragma mark interger manipulation
+(Word)sext_5:(Word) w{
    return (w&_4_MASK)?(w|_5_SEXT_1):(w&_5_SEXT_0);
}

+(Word)sext_6:(Word) w{
    return (w&_5_MASK)?(w|_6_SEXT_1):(w&_6_SEXT_0);
}

+(Word)zext_8:(Word) w{
    return w&_8_ZEXT_0;
}

+(Word)sext_9:(Word) w{
    return (w&_8_MASK)?(w|_9_SEXT_1):(w&_9_SEXT_0);
}

+(Word)sext_11:(Word) w{
    return (w&_10_MASK)?(w|_11_SEXT_1):(w&_11_SEXT_0);
}
+(Word)offsetFrom:(Word)a1 to:(Word)a2 length:(PANumberLength)length Error:(PAError*__strong*)error{
    short difference = a2-a1;
    if (length==PANumberLength9) {
        if (difference>_PC_OFFSET_9_MAX||difference<_PC_OFFSET_9_MIN) {
            *error = [[PAError alloc] initWithType:PAErrorLabelOutsideReach Message:[NSString stringWithFormat:@"The given difference: %d is impossible to be represented int 9 bits",difference]];
        }
        difference&=_0_8_MASK;
    }
    else if (length==PANumberLength11){
        if (difference>_PC_OFFSET_11_MAX||difference<_PC_OFFSET_11_MIN) {
            *error = [[PAError alloc] initWithType:PAErrorLabelOutsideReach Message:[NSString stringWithFormat:@"The given difference: %d is impossible to be represented int 11 bits",difference]];
        }
        difference&=_0_10_MASK;
    }
    else if (length!=PANumberLength16){
        NSLog(@"Attemp to perform an unsupported operation on LC-3 architecture.");
    }
    return difference;
}
+(Word)numberToBinary:(int)number length:(PANumberLength)length{
    Word word = (Word)number;
    switch (length) {
        case PANumberLength5:
            return word&=_0_4_MASK;
        case PANumberLength6:
            return word&=_0_5_MASK;
        case PANumberLength9:
            return word&=_0_8_MASK;
        case PANumberLength11:
            return word&=_0_10_MASK;
        case PANumberLength8:
            return word&=_0_7_MASK;
        case PANumberLength3:
            return word&=_0_2_MASK;
        default:
            NSLog(@"Attemp to perform an unsupported operation on LC-3 architecture.");
            return 0;
    }
}

+(Word)put:(Word)number into:(Word)word shiftBit:(int)shift length:(PANumberLength)length{
    Word temp=[PAUtility numberToBinary:number length:length];
    word|=(temp<<shift);
    return word;
}

#pragma mark settings
+(NSArray*)validFonts{
    static dispatch_once_t onceToken;
    static NSArray *validFonts;
    dispatch_once(&onceToken,^{
        validFonts=@[@"AmericanTypewriter",@"ArialMT",@"Damascus",@"HelveticaNeue",@"Courier New"];
    });
    return validFonts;
}
+(NSArray*)validFontSizes{
    static dispatch_once_t onceToken;
    static NSArray *validFontSizes;
    dispatch_once(&onceToken,^{
        validFontSizes=@[@10,@11,@12,@13,@14,@16,@22,@26,@30,@32];
    });
    return validFontSizes;
}

+(int)fontIndex{
    int index = [[[NSUserDefaults standardUserDefaults] objectForKey:@"CodeFont"]intValue];
    return index<[self validFonts].count?index:0;
}
+(int)fontSizeIndex{
    int index = [[[NSUserDefaults standardUserDefaults] objectForKey:@"TextSize"]intValue];
    return index<[self validFontSizes].count?index:0;
}

#pragma mark global variables
+(NSURL*)OSURL{
    static dispatch_once_t onceToken;
    static NSURL *osurl;
    dispatch_once(&onceToken,^{
        NSArray * paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL* localRoot = [paths objectAtIndex:0];
        osurl=[localRoot URLByAppendingPathComponent:[NSString stringWithFormat:@"lc3os.%@",GY_FILE_EXTENSION]];
    });
    return osurl;
}

#define SINGLGTON_OBJECT_DECLARATION(type,name,value) \
    +(type)name{ \
        static dispatch_once_t onceToken; \
        static type name;\
        dispatch_once(&onceToken,^{\
            name=value; \
        });\
        return name;\
    }


SINGLGTON_OBJECT_DECLARATION(UIColor*, tintRed, [[UIColor alloc]initWithRed:0xee/255.0 green:0x74/255.0 blue:0x69/255.0 alpha:1]);
SINGLGTON_OBJECT_DECLARATION(UIColor*, tintLightYellow, [[UIColor alloc]initWithRed:0xff/255.0 green:0xf0/255.0 blue:0xd6/255.0 alpha:1]);
SINGLGTON_OBJECT_DECLARATION(UIColor*, tintLightPurple, [[UIColor alloc]initWithRed:0xb8/255.0 green:0x95/255.0 blue:0x9b/255.0 alpha:1]);
SINGLGTON_OBJECT_DECLARATION(UIColor*, tintDarkPurple, [[UIColor alloc]initWithRed:0x83/255.0 green:0x6d/255.0 blue:0x6f/255.0 alpha:1]);
SINGLGTON_OBJECT_DECLARATION(UIColor*, tintBrown, [[UIColor alloc]initWithRed:0x38/255.0 green:0x37/255.0 blue:0x32/255.0 alpha:1]);

SINGLGTON_OBJECT_DECLARATION(NSString*, validFileNameRegex, @"([1-9]|[a-z]|[A-Z]|_)+");

+(NSDateFormatter*)universalDateFormatter{
    static dispatch_once_t onceToken;
    static NSDateFormatter *universalDateFormatter;
    dispatch_once(&onceToken,^{
        universalDateFormatter=[[NSDateFormatter alloc]init];
        [universalDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    });
    return universalDateFormatter;
}

@end
