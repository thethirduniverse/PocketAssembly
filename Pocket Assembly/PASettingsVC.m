//
//  GYSettingsVC.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/25/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PASettingsVC.h"
#import "PAUtility.h"
#import "AppDelegate.h"
#import "PAInterfaceVC.h"
#import <MessageUI/MessageUI.h>
#define FLIP_DEFAULS_FOR_PATH
@interface PASettingsVC()<MFMailComposeViewControllerDelegate>
@property (weak,nonatomic) NSUserDefaults* defaults;
@end
@implementation PASettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.defaults=[NSUserDefaults standardUserDefaults];
    self.navigationItem.leftItemsSupplementBackButton=true;
}


#pragma mark - handle tap events

-(void)flipTempAutoloadOS{
    [self flipDefaultsForPath:@"AutoloadOS"];
}
-(void)flipTempShowVideo{
    [self flipDefaultsForPath:@"ShowVideoOutput"];
}
-(void)flipTempPlaySound{
    [self flipDefaultsForPath:@"PlaySound"];
}
-(void)flipTempAutoReturn{
    [self flipDefaultsForPath:@"AutoReturn"];
}
-(void)flipUseCustomTextView{
    [self flipDefaultsForPath:@"UseCustomTextView"];
}
-(void)flipDefaultsForPath:(NSString*)path{
    [self.defaults setValue:@(![[self.defaults valueForKey:path] boolValue]) forKey:path];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 9;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return [PAUtility validFontSizes].count;
        case 1:
            return [PAUtility validFonts].count;
        default:
            return 1;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section>0) {
        return 44;
    }
    return [[PAUtility validFontSizes][indexPath.row] floatValue]+20;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section>=6) {
        return 50;
    }
    return 50;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.section) {
        case 0:
            if (indexPath.row==[PAUtility fontSizeIndex]) {
                cell.accessoryType=UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType=UITableViewCellAccessoryNone;
            }
            break;
        case 1:
            if (indexPath.row==[PAUtility fontIndex]) {
                cell.accessoryType=UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType=UITableViewCellAccessoryNone;
            }
            break;
        case 7:
        case 8:
            cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
            break;
    }

    
    UILabel* textLabel =(UILabel*)[[cell contentView] viewWithTag:1];
    textLabel.textColor=[UIColor blackColor];
    textLabel.font=[UIFont systemFontOfSize:17];
    
    UISwitch* cellSwitch = (UISwitch*)[[cell contentView] viewWithTag:2];
    if (cellSwitch) {
        [cellSwitch setThumbTintColor:[PAUtility tintRed]];
        [cellSwitch setOnTintColor:[PAUtility tintLightYellow]];
    }
    
    
    switch (indexPath.section) {
        case 0:
            textLabel.text=[[NSString alloc]initWithFormat:@"%d",[[PAUtility validFontSizes][indexPath.row] intValue]];
            textLabel.font=[cell.textLabel.font fontWithSize:[[PAUtility validFontSizes][indexPath.row] doubleValue]];
            break;
        case 1:
            textLabel.text=[PAUtility validFonts][indexPath.row];
            textLabel.font=[UIFont fontWithName:[PAUtility validFonts][indexPath.row] size:22];
            break;
        case 2:
            textLabel.text=@"Auto Load OS At Launch";
            [cellSwitch setOn:[[self.defaults valueForKey:@"AutoloadOS"] boolValue]];
            [cellSwitch addTarget:self action:@selector(flipTempAutoloadOS) forControlEvents:UIControlEventTouchUpInside];
            break;
        case 3:
            textLabel.text=@"Show Video Output";
            [cellSwitch setOn:[[self.defaults valueForKey:@"ShowVideoOutput"] boolValue]];
            [cellSwitch addTarget:self action:@selector(flipTempShowVideo) forControlEvents:UIControlEventTouchUpInside];
            break;
        case 4:
            textLabel.text=@"Play Sounds";
            [cellSwitch setOn:[[self.defaults valueForKey:@"PlaySound"] boolValue]];
            [cellSwitch addTarget:self action:@selector(flipTempPlaySound) forControlEvents:UIControlEventTouchUpInside];
            break;
        case 5:
            textLabel.text=@"Show Home If Load Succeed";
            [textLabel setAdjustsFontSizeToFitWidth:true];
            [cellSwitch setOn:[[self.defaults valueForKey:@"AutoReturn"] boolValue]];
            [cellSwitch addTarget:self action:@selector(flipTempAutoReturn) forControlEvents:UIControlEventTouchUpInside];
            break;
        case 6:
            textLabel.text=@"Use Custom Editor";
            [textLabel setAdjustsFontSizeToFitWidth:true];
            [cellSwitch setOn:[[self.defaults valueForKey:@"UseCustomTextView"] boolValue]];
            [cellSwitch addTarget:self action:@selector(flipUseCustomTextView) forControlEvents:UIControlEventTouchUpInside];
            break;
        case 7:
            textLabel.text=@"Report a Bug";
            [textLabel setAdjustsFontSizeToFitWidth:true];
            break;
        case 8:
            textLabel.text=@"Rate in App Store";
            [textLabel setAdjustsFontSizeToFitWidth:true];
            break;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return @"Code Font Size";
        case 1:
            return @"Code Font";
        case 6:
            return @"Custom Editor can display line number and highlight your syntax. While normal editor is faster.";
        case 7:
            return @"Please report any bug you encountered to help make a better experience.";
        case 8:
            return @"If you find this app useful. Please don't hesitate to rate it. Your input is highly appreciated.";
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath{
    return indexPath.section<2||indexPath.section>=6;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *link;
    switch (indexPath.section) {
        case 0:
            [self.defaults setValue:@((int)indexPath.row) forKey:@"TextSize"];
            break;
        case 1:
            [self.defaults setValue:@((int)indexPath.row) forKey:@"CodeFont"];
            break;
        case 7:
            if ([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
                mailViewController.mailComposeDelegate = self;
                [mailViewController setSubject:@"Pocket Assembly Bug Report"];
                [mailViewController setToRecipients:@[@"thethirduniverse@gmail.com"]];
                [self presentViewController:mailViewController animated:true completion:nil];
            }
            else {
                link = @"https://thethirduniverse.wordpress.com/2015/01/31/pocket-assembly-bug-report/";
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
            }
            break;
        case 8:
            link = @"https://itunes.apple.com/us/app/pocket-assembly/id959802466?ls=1&mt=8";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
            break;
            
    }
    [UIView transitionWithView:self.tableView
                      duration:0.1f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
                        [self.tableView reloadData];
                        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:false];
                        //[self.tableView setNeedsDisplay];
                    } completion:NULL];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell;
    if (indexPath.section>1&&indexPath.section<7) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"labelCell"];
    }
    return cell;
}

#pragma mark mailComposeDelegate
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissViewControllerAnimated:true completion:nil];
}


@end
