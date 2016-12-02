//
//  GYMemoryLocationCell.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/12/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PAMemoryLocationCell.h"
#import "PADiscardableTextField.h"
#import "PAInterfaceVC.h"
#import "AppDelegate.h"

@interface PAMemoryLocationCell()
@property (nonatomic) Word address;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *labelLabel;
@property (weak, nonatomic) IBOutlet UILabel *instructionLabel;
@property (weak, nonatomic) IBOutlet PADiscardableTextField *contentTextField;
@property (nonatomic,strong) NSString* savedContent;
@property (nonatomic) BOOL initialized;
@end

@implementation PAMemoryLocationCell

-(void)initialize{
    double fontsize=UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone?16:18;
    
    self.labelLabel.font=[UIFont italicSystemFontOfSize:fontsize];
    self.addressLabel.font=[UIFont boldSystemFontOfSize:fontsize];
    self.contentTextField.font=[UIFont boldSystemFontOfSize:fontsize];
    self.instructionLabel.font=[UIFont italicSystemFontOfSize:fontsize];
    
    [self.contentTextField setTextAlignment:NSTextAlignmentCenter];
    [self.addressLabel setTextAlignment:NSTextAlignmentCenter];
    [self.contentTextField setTextAlignment:NSTextAlignmentCenter];
    [self.instructionLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self.labelLabel setAdjustsFontSizeToFitWidth:true];
    [self.addressLabel setAdjustsFontSizeToFitWidth:true];
    [self.contentTextField setAdjustsFontSizeToFitWidth:true];
    [self.contentTextField setMinimumFontSize:5];
    [self.instructionLabel setAdjustsFontSizeToFitWidth:true];
    
    [self.contentTextField setKeyboardType:UIKeyboardTypeASCIICapable];
    [self.contentTextField setDelegate:[(AppDelegate*)[[UIApplication sharedApplication] delegate] mainInterface]];
    _initialized=true;
}

-(void)configureWithAddress:(Word)address Label:(NSString*)label Content:(Word)content Interpretation:(NSString*)interpretation{
    if (!_initialized) {
        [self initialize];
    }
    [self.contentTextField setTag:address];
    self.addressLabel.text=[NSString stringWithFormat:@"0x%04X",address];
    self.labelLabel.text=label;
    [self.contentTextField setAndSaveText:[[NSString alloc] initWithFormat:@"0x%04X",content]];
    self.instructionLabel.text=interpretation;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    if (selected) {
        [self setBackgroundColor:[PAUtility tintRed]];
    }
    else{
        [self setBackgroundColor:[UIColor clearColor]];
    }
}

@end
