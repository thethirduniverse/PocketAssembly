//
//  GYRegistersDisplayCell.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/18/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PARegistersDisplayCell.h"
#import "PADiscardableTextField.h"
#import "AppDelegate.h"
#import "PAInterfaceVC.h"

@interface PARegistersDisplayCell()
@property (nonatomic) int registerNumber;
@property (nonatomic,strong) UILabel* titleLabel;
@property (nonatomic,strong) PADiscardableTextField* valueField;
@property (nonatomic,strong) NSString* savedValue;
@property (nonatomic) BOOL initialized;
@end

@implementation PARegistersDisplayCell
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    [self initialize];
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    [self initialize];
}

-(void)initialize{
    _titleLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, 70, 20)];
    [_titleLabel setTextAlignment:NSTextAlignmentCenter];
    _valueField=[[PADiscardableTextField alloc]initWithFrame:CGRectMake(0, 20, 70, 20)];
    [_valueField setFont:_titleLabel.font];
    [_valueField setTextAlignment:NSTextAlignmentCenter];
    [_valueField setKeyboardType:UIKeyboardTypeASCIICapable];
    [_valueField setDelegate:[(AppDelegate*)[[UIApplication sharedApplication] delegate] mainInterface]];
    [self.contentView addSubview:_titleLabel];
    [self.contentView addSubview:_valueField];

    _initialized=true;
}
-(void)configureWithTitle:(NSUInteger)title Value:(Word)value{
    if (!_initialized) {
        [self initialize];
    }
    self.registerNumber=(int)title;
    [self.valueField setTag:title<<Register_Identity_SHIFT|Register_Identity_Mask];
    self.titleLabel.text=[PAUtility registerNames][(int)title];
    //NSLog(self.titleLabel.text);
    [self.valueField setAndSaveText:[[NSString alloc] initWithFormat:@"0x%04X",value]];
}
-(void)keepChange{
    self.savedValue=self.valueField.text;
}
-(void)discardChange{
    self.valueField.text=self.savedValue;
}
@end
