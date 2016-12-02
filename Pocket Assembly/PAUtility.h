//
//  GYPAUtility.h
//  PAtest
//
//  Created by Guanqing Yan on 12/16/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <Foundation/Foundation.h>
#define _15_MASK 0x8000
#define _9_11_MASK 0x0E00
#define _9_11_SHFTBIT 9
#define _6_8_MASK 0x01C0
#define _6_8_SHFTBIT 6
#define _11_MASK 0x0800
#define _10_MASK 0x0400
#define _8_MASK 0x0100
#define _5_MASK 0x0020
#define _4_MASK  0x0010
#define _0_2_MASK 0x0007
#define _0_4_MASK 0x001F
#define _0_5_MASK 0x003F
#define _0_7_MASK 0x00FF
#define _0_8_MASK 0x01FF
#define _0_10_MASK 0x07FF
#define _0_15_MASK 0xFFFF
#define _9_MASK 0x0200
#define _10_MASK 0x0400
#define _11_MASK 0x0800

#define INSTRUCTION_MASK 0xF000
#define ADD_INS 0x1000
#define ADD_AND_IMMEDIATE_BIT 0x0020
#define AND_INS 0x5000
#define BR_INS 0x0000
#define JMP_INS 0xC000
#define JSR_INS 0x4000
#define LD_INS 0x2000
#define LDI_INS 0xA000
#define LDR_INS 0x6000
#define LEA_INS 0xE000
#define NOT_INS 0x9000
#define RTI_INS 0x8000
#define ST_INS 0x3000
#define STI_INS 0xB000
#define STR_INS 0x7000
#define TRAP_INS 0xF000
#define RSV_INS 0xD000
#define RET_MASK 0xF1C0
#define RET_INS_FULL 0xC1C0

#define CCn 0x4
#define CCz 0x2
#define CCp 0x1
#define BR_N 0x800
#define BR_Z 0x400
#define BR_P 0x200

#define _5_SEXT_0 0x001F//to be ANDed
#define _5_SEXT_1 0xFFE0//to be ORed
#define _6_SEXT_0 0x003F//to be ANDed
#define _6_SEXT_1 0xFFC0//to be ORed
#define _8_ZEXT_0 0x00FF
#define _9_SEXT_0 0x01FF//to be ANDed
#define _9_SEXT_1 0xFE00//to be ORed
#define _11_SEXT_0 0x07FF//to be ANDed
#define _11_SEXT_1 0xF800//to be ORed
#define _PC_OFFSET_5_MIN (-16)
#define _PC_OFFSET_5_MAX 15
#define _PC_OFFSET_6_MIN (-32)
#define _PC_OFFSET_6_MAX 31
#define _PC_OFFSET_8_MIN (-128)
#define _PC_OFFSET_8_MAX 127
#define _PC_OFFSET_9_MIN (-256)
#define _PC_OFFSET_9_MAX 255
#define _PC_OFFSET_11_MIN (-1024)
#define _PC_OFFSET_11_MAX 1023
#define _PC_OFFSET_16_MIN (-(1<<15))
#define _PC_OFFSET_16_MAX ((1<<15)-1)

#define PC_Collection_Index 8
#define CC_Collection_Index 9
#define PSR_Collection_Index 10
#define MPR_Collection_Index 11

#define Register_Identity_SHIFT 16
#define Register_Identity_Mask 0x100000
#define Register_Identity_UNMASK 0xF
#define COLLECTION_ROW_NUM 2
#define COLLECTION_COL_NUM 6

#define DISPLAY_PIXEL_HOR 128
#define DISPLAY_PIXEL_VER 124
#define DISPLAY_RED_SHIFT 10
#define DISPLAY_GREEN_SHIFT 5
#define DISPLAY_BLUE_SHIFT 0
#define DISPLAY_COLOR_MASK 0x1F

#define NUM_CHAR_DIFFERENCE 0x30

#define Keyboard_Status_Register 0xFE00
#define Keyboard_Data_Register 0xFE02
#define Display_Status_Register 0xFE04
#define Display_Data_Register 0xFE06

#define GY_FILE_EXTENSION @"GYF"

#define INPUT_ACCESSORY_VIEW_HEIGHT_PHONE 105
#define INPUT_ACCESSORY_VIEW_HEIGHT_PAD 150
#define INPUT_ACCESSORY_VIEW_BUTTON_HEIGHT 45
#define INPUT_ACCESSORY_VIEW_BUTTON_CONNER_RADIUS 7

#define MAIN_INTEFACE_INPUT_TEXT_VIEW_TAG 0x10000

#import <UIKit/UIKit.h>
#import "PAError.h"

//LC-3 has a word size of 16
typedef unsigned short Word;

typedef enum{
    PANumberLength3,
    PANumberLength5,
    PANumberLength6,
    PANumberLength8,
    PANumberLength9,
    PANumberLength11,
    PANumberLength16,
}PANumberLength;

typedef enum{
    PAExecuteModeRun,PAExecuteModeStep,PAExecuteModeNext
}PAExecuteMode;

@interface PAUtility : NSObject
/*instructions*/
+(NSArray*)validInstructions;
+(NSArray*)labelDependentInstructions;//instuctions that needs label resolution

/*memory sections*/
+(NSArray*)memorySectionTitles;
+(NSUInteger*)memorySectionLengths;
+(Word*)memoryIndexPathOffset;
+(NSIndexPath*)indexPathFromLocation:(Word)location;
+(Word)locationFromIndexPath:(NSIndexPath*)indexPath;

/*Utility methods about registers*/
+(NSArray*)registerNames;

/*integer manipulation*/
+(Word)sext_5:(Word)word;
+(Word)sext_6:(Word)word;
+(Word)zext_8:(Word)word;
+(Word)sext_9:(Word)word;
+(Word)sext_11:(Word)word;
+(Word)offsetFrom:(Word)a1 to:(Word)a2 length:(PANumberLength)length Error:(PAError*__strong*)error;
+(Word)numberToBinary:(int)number length:(PANumberLength)length;
+(Word)put:(Word)number into:(Word)word shiftBit:(int)shift length:(PANumberLength)length;

/*settings*/
+(NSArray*)validFonts;
+(NSArray*)validFontSizes;
+(NSString*)validFileNameRegex;
+(int)fontIndex;
+(int)fontSizeIndex;

/*global variables*/
+(NSDateFormatter*)universalDateFormatter;
+(NSURL*)OSURL;
+(UIColor*)tintRed;
+(UIColor*)tintLightYellow;
+(UIColor*)tintLightPurple;
+(UIColor*)tintDarkPurple;
+(UIColor*)tintBrown;
@end
