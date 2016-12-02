//
//  ViewController.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/8/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PAInterfaceVC.h"
#import "PAModel.h"
#import "PADiscardableTextField.h"
#import "AppDelegate.h"
#import "PADisplayView.h"
#import "PAConsoleView.h"
#import "PAFileModel.h"
#import "PAFileCollectionVC.h"
#import <AudioToolbox/AudioToolbox.h>

@interface PAInterfaceVC ()<UITableViewDelegate,UIAlertViewDelegate,UITextViewDelegate,UIActionSheetDelegate>{
    CGRect _displayOriginalFrame;
    BOOL _displayZoomed;
    BOOL _initialized;
    UIAlertController* _alert;
}
@property (weak, nonatomic) IBOutlet UISegmentedControl *sectionSegments;
@property (weak, nonatomic) IBOutlet UITableView *memoryView;
@property (weak, nonatomic) IBOutlet UICollectionView *registersView;
@property (strong, nonatomic) IBOutlet PADisplayView *displayView;
@property (weak, nonatomic) IBOutlet PAConsoleView *consoleView;
@property (strong,nonatomic) UIActivityIndicatorView* spinner;
@property (strong, nonatomic) UITextView* keyboardInputTextView; //hidden text view, used to show keyboard for input
@property (strong,nonatomic) PAModel* model;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *continueButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *stepButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *suspendButton;
@property (strong, nonatomic) UIBarButtonItem *filesButton;
@property (strong, nonatomic)  UIBarButtonItem *settingsButton;
@property (strong, nonatomic) UIBarButtonItem *resetButton;
@property (strong, nonatomic) UIBarButtonItem* keyboardButton;

@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *cellLongPress;
/*keeps track of selected cell when long pressing a memory location*/
@property (strong,nonatomic) NSIndexPath* selectedCellIndexPath;
@end

@implementation PAInterfaceVC
#pragma mark Event Handling
- (IBAction)segmentTapped:(id)sender {
    [self.memoryView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[(UISegmentedControl*)sender selectedSegmentIndex]] atScrollPosition:UITableViewScrollPositionTop animated:true];
}
- (IBAction)continueTapped:(id)sender {
    [self.model continueExecutionUsingMode:PAExecuteModeRun];
    [self setEnabled:false];
}
- (IBAction)stepTapped:(id)sender {
    [self.model continueExecutionUsingMode:PAExecuteModeStep];
    [self setEnabled:false];
}
- (IBAction)nextTapepd:(id)sender {
    [self.model continueExecutionUsingMode:PAExecuteModeNext];
    [self setEnabled:false];
}
- (IBAction)suspendTapped:(id)sender {
    [self.model suspend];
}
-(void)keyboardButtonTapped:(id)sender{
    if (self.keyboardInputTextView.isFirstResponder) {
        [self.keyboardInputTextView resignFirstResponder];
    }
    else{
        [self.keyboardInputTextView becomeFirstResponder];
    }
}
-(void)filesButtonTapped:(id)sender{
    [self performSegueWithIdentifier:@"showFilesVC" sender:self];
}
-(void)settingsButtonTapped:(id)sender{
    [self performSegueWithIdentifier:@"showSettingsVC" sender:self];
}
- (void)resetButtonTapped:(id)sender {
    if ([[[UIDevice currentDevice] systemVersion] floatValue]>=8.0) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Select Refresh Action"
                                              message:nil
                                              preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:@"Cancel"
                                       style:UIAlertActionStyleCancel
                                       handler:nil];
        UIAlertAction *clearConsoleAction = [UIAlertAction
                                   actionWithTitle:@"Clear Console"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       [self.consoleView setText:@""];
                                   }];
        UIAlertAction *clearRegistersAction = [UIAlertAction
                                             actionWithTitle:@"Clear Registers"
                                             style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action)
                                             {
                                                 [self.model initializeRegisters];
                                                 [self.registersView reloadData];
                                             }];
        UIAlertAction *clearBreakpointsAction = [UIAlertAction
                                               actionWithTitle:@"Remove Breakpoints"
                                               style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action)
                                               {
                                                   [self.model initializeBreakPoint];
                                                   [self.memoryView reloadData];
                                               }];
        UIAlertAction *clearAllAction = [UIAlertAction
                                   actionWithTitle:@"Restore All"
                                   style:UIAlertActionStyleDestructive
                                   handler:^(UIAlertAction *action)
                                   {
                                       [self.model clearModel];
                                   }];
        [alertController addAction:cancelAction];
        [alertController addAction:clearConsoleAction];
        [alertController addAction:clearRegistersAction];
        [alertController addAction:clearBreakpointsAction];
        [alertController addAction:clearAllAction];
        [alertController.view setTintColor:[PAUtility tintDarkPurple]];
        UIPopoverPresentationController *popover = alertController.popoverPresentationController;
        if (popover)
        {
            [popover setBarButtonItem:_resetButton];
            popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
        }
        [self presentViewController:alertController animated:true completion:nil];
    }
    else{
        UIActionSheet* actionSheet = [[UIActionSheet alloc]initWithTitle:@"Select Refresh Action" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Restore All" otherButtonTitles:@"Clear Console",@"Clear Registers",@"Clear Breakpoints",nil];
        [actionSheet showInView:self.view];
    }
}
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex==[actionSheet destructiveButtonIndex]) {
        [self.model clearModel];
    }
    else if(buttonIndex==1){
        [self.consoleView setText:@""];
    }
    else if(buttonIndex==2){
        [self.model initializeRegisters];
        [self.registersView reloadData];
    }
    else if(buttonIndex==3){
        [self.model initializeBreakPoint];
        [self.memoryView reloadData];
    }
}

-(void)presentAlertWhenReady:(UIAlertController*)alert{
    _alert = alert;
}

#pragma mark ViewController Life Cycle
-(void)awakeFromNib{
    [super awakeFromNib];
    [(AppDelegate*)[[UIApplication sharedApplication] delegate] setMainInterface:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!_initialized) {
        [self initialize];
    }
    if (_alert) {
        [self presentViewController:_alert animated:true completion:nil];
        _alert = nil;
    }
}

-(void)initialize{
    self.model=[[PAModel alloc]init];
    self.model.delegate=self;
    self.memoryView.dataSource=self.model;
    self.memoryView.delegate=self;
    [self.memoryView setContentInset:UIEdgeInsetsMake(100, 0, 0, 0)];
    self.registersView.dataSource=self.model;
    //self.consoleView.layer.borderWidth=0;
    
    [self.memoryView registerNib:[UINib nibWithNibName:@"PAMemoryLocationCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"cell"];
    self.spinner= [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.center=self.view.center;
    self.spinner.backgroundColor = [UIColor blackColor];
    [self.spinner layer].cornerRadius = 8.0;
    [self.spinner layer].masksToBounds = YES;
    
    self.resetButton=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(resetButtonTapped:)];
    self.keyboardButton=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"keyboard_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(keyboardButtonTapped:)];
    self.filesButton=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"file_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(filesButtonTapped:)];
    self.settingsButton=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"settings_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonTapped:)];
    UIBarButtonItem* fixedWidth=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedWidth.width=20;
    self.navigationItem.rightBarButtonItems=@[self.settingsButton,fixedWidth,self.filesButton];
    self.navigationItem.leftBarButtonItems=@[self.resetButton,fixedWidth,self.keyboardButton];
    
    self.keyboardInputTextView=[[UITextView alloc]init];
    [self.keyboardInputTextView setHidden:true];
    self.keyboardInputTextView.tag=MAIN_INTEFACE_INPUT_TEXT_VIEW_TAG;
    self.keyboardInputTextView.delegate=self;
    self.keyboardInputTextView.keyboardType=UIKeyboardTypeASCIICapable;
    [self.view addSubview:self.keyboardInputTextView];
    
    
    self.navigationController.navigationBar.barTintColor=[PAUtility tintLightPurple];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    self.navigationController.toolbar.barTintColor=[PAUtility tintBrown];
    self.navigationController.toolbar.tintColor = [UIColor whiteColor];
    
    self.view.tintColor = [PAUtility tintBrown];
    
    //[self.registersView setBackgroundColor:[PAUtility tintLightYellow]];
    
    _initialized=true;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone?UIInterfaceOrientationMaskPortrait:UIInterfaceOrientationMaskAll;
}

-(BOOL)prefersStatusBarHidden{
    return false;
}

- (void)presentModalViewController:(UIViewController *)modalViewController fromView:(UIView *)view
{
    modalViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    
    // Add the modal viewController but don't animate it. We will handle the animation manually
    //[self presentModalViewController:modalViewController animated:NO];
    [self presentViewController:modalViewController animated:YES completion:nil];
    
    // Remove the shadow. It causes weird artifacts while animating the view.
    //    CGColorRef originalShadowColor = modalViewController.view.superview.layer.shadowColor;
    //    modalViewController.view.superview.layer.shadowColor = [[UIColor clearColor] CGColor];
    //
    //    // Save the original size of the viewController's view
    //    CGRect originalFrame = modalViewController.view.superview.frame;
    //
    //    // Set the frame to the one of the view we want to animate from
    //    modalViewController.view.superview.frame = view.frame;
    //
    //    // Begin animation
    //    [UIView animateWithDuration:1.0f
    //                     animations:^{
    //                         // Set the original frame back
    //                         modalViewController.view.superview.frame = originalFrame;
    //                     }
    //                     completion:^(BOOL finished) {
    //                         // Set the original shadow color back after the animation has finished
    //                         modalViewController.view.superview.layer.shadowColor = originalShadowColor;
    //                     }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updateViews];
}
-(void)viewWillDisappear:(BOOL)animated{
    NSNotificationCenter* nc=[NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [nc removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewDidLayoutSubviews{
    _displayOriginalFrame=self.displayView.frame;
//    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone) {
//        if (![[[NSUserDefaults standardUserDefaults] valueForKey:@"ShowVideoOutput"] boolValue]) {
//            [self.displayView setHidden:true];
//            CGRect rect=self.consoleView.frame;
//            rect.origin.x-=self.displayView.frame.size.width;
//            rect.size.width+=self.displayView.frame.size.width;
//            self.consoleView.frame=rect;
//        }
//        else{
//            if ([self.displayView isHidden]) {
//                [self.displayView setHidden:false];
//                CGRect rect=self.consoleView.frame;
//                rect.origin.x+=self.displayView.frame.size.width;
//                rect.size.width-=self.displayView.frame.size.width;
//                self.consoleView.frame=rect;
//            }
//        }
//    }
//    else{
//        if (![[[NSUserDefaults standardUserDefaults] valueForKey:@"ShowVideoOutput"] boolValue]) {
//            [self.displayView setHidden:true];
//            CGRect rect=self.consoleView.frame;
//            rect.origin.y-=self.displayView.frame.size.height;
//            rect.size.height+=self.displayView.frame.size.height;
//            self.consoleView.frame=rect;
//        }
//        else{
//            if ([self.displayView isHidden]) {
//                [self.displayView setHidden:false];
//                CGRect rect=self.consoleView.frame;
//                rect.origin.y+=self.displayView.frame.size.height;
//                rect.size.height-=self.displayView.frame.size.height;
//                self.consoleView.frame=rect;
//            }
//        }
//    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    UITableView* tableView = (UITableView*) scrollView;
    NSArray* visiblecells = [tableView visibleCells];
    NSUInteger sectionNumber = 0;//default to 0
    if ([visiblecells count]>0) {
        sectionNumber = [[tableView indexPathForCell:[visiblecells objectAtIndex:0]] section];
    }
    [[self sectionSegments] setSelectedSegmentIndex:sectionNumber];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 40;
}

-(void)updateViews{
    [self.memoryView reloadData];
    [self.registersView reloadData];
    if (!self.displayView.isHidden) {
        [[self displayView] loadDisplayFromSource:_model.memory];
        //[self.displayView setNeedsDisplay];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma public API
-(BOOL)loadModel:(PAFileModel*)model{
    return [self.model loadFile:model showAlert:true];
}


-(BOOL)loadFileWithURL:(NSURL*)fileURL{
    [self.navigationController popToRootViewControllerAnimated:NO];
    PAFileCollectionVC* collectionVC=[self.storyboard instantiateViewControllerWithIdentifier:@"filesCollectionVC"];
    [collectionVC loadTextFileFromURL:fileURL];
    [self.navigationController pushViewController:collectionVC animated:true];
    return true;
}

#pragma mark UITableViewDelegate
-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath{
    return false;
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([PAUtility locationFromIndexPath:indexPath]==self.model.PC) {
        [cell setSelected:true];
    }
    if (indexPath.row % 2 == 1) {
        if (cell.backgroundColor != [PAUtility tintRed]) {
            [cell setBackgroundColor:[PAUtility tintLightYellow]];
        }
    }
}

#pragma mark UITextFieldDelegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    self.selectedCellIndexPath=[self.memoryView indexPathForCell:(UITableViewCell*)textField.superview.superview];
    return YES;
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self.view endEditing:YES];
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:self];
    [textField resignFirstResponder];
    return true;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    Word value;
    unsigned int valueInt;
    NSScanner* scanner = [NSScanner scannerWithString:textField.text];
    if ([scanner scanHexInt:&valueInt]&&[scanner isAtEnd]) {
        //NSLog(@"%d",[textField respondsToSelector:@selector(keepChange)]);
        
        if (valueInt>0xffff) {
            [(PADiscardableTextField*)textField discardChange];
            return;
        }
        
        value=(Word)valueInt;
        [(PADiscardableTextField*)textField keepChange];
        //if register
        //        NSLog(@"%d",textField.tag&Register_Identiry_Mask);
        //        NSLog(@"%d",textField.tag);
        if (textField.tag&Register_Identity_Mask) {
            Word identity=(textField.tag>>Register_Identity_SHIFT)&Register_Identity_UNMASK;
            switch (identity) {
                case PC_Collection_Index:
                    [self.model setPC:value];
                    break;
                case CC_Collection_Index:
                    [self.model setCC:value];
                    break;
                case MPR_Collection_Index:
                    [self.model setMPR:value];
                    break;
                case PSR_Collection_Index:
                    [self.model setPSR:value];
                    break;
                default:
                    [self.model registers][identity]=value;
                    break;
            }
        }
        //if memory
        else{
            [self.model setMemoryAtLocation:textField.tag newValue:value];
            //display screen
            if (textField.tag>=[PAUtility memoryIndexPathOffset][4]&&textField.tag<[PAUtility memoryIndexPathOffset][5]) {
                [[self displayView] loadDisplayFromSource:_model.memory];
            }
            //console
            else if(textField.tag==Display_Status_Register){
                
            }
        }
        [self.memoryView reloadData];
    }else{
        [(PADiscardableTextField*)textField discardChange];
    }
}

#pragma mark UItextview delegate
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if (text==nil) {
        return false;
    }
    [self.model keyboardDidEnterCharacter:[text characterAtIndex:0]];
    return false;
}

#pragma mark keyboard management

-(void)keyboardWillShow:(NSNotification*)not{
    [self.memoryView scrollToRowAtIndexPath:_selectedCellIndexPath atScrollPosition:UITableViewScrollPositionTop animated:true];
}
-(void)keyboardWillHide:(NSNotification*)not{
}

#pragma mark GYPAModelDelegate
-(void)didFinishLoadingFileModel:(PAFileModel *)model showAlert:(BOOL)alert{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (alert) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Loading Success" message:[NSString stringWithFormat:@"The file is successfully loaded at start position 0x%X.",model.startPosition] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
            [alert setTintColor:[PAUtility tintLightPurple]];
            [alert show];
            if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"PlaySound"] boolValue]) {
                AudioServicesPlaySystemSound(1033);
            }
        }
        [self updateViews];
    });
}

-(void)didFailLoadingFileWithError:(PAError*)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[PAError titleForErrorType:error.type] message:error.message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];
        if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"PlaySound"] boolValue]) {
            AudioServicesPlaySystemSound(1051);
        }
    });
}
-(void)didFinishExecutionWithPC:(Word)pc{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateViews];
        [[self memoryView] scrollToRowAtIndexPath:[PAUtility indexPathFromLocation:pc] atScrollPosition:UITableViewScrollPositionMiddle animated:true];//if not fluent, change to false
        [self setEnabled:true];
        if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"PlaySound"] boolValue]) {
            AudioServicesPlaySystemSound(1057);
        }
    });
}
-(void)outputChar:(Word)character{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.consoleView put:character];
        //NSRange range = NSMakeRange(self.consoleView.text.length - 1, 1);
        //[self.consoleView scrollRangeToVisible:range];
    });
}

-(void)showSpinner{
    [self.spinner startAnimating];
    [self.view addSubview:self.spinner];
}
-(void)hideSpinner{
    [self.spinner stopAnimating];
    [self.spinner removeFromSuperview];
}

-(void)modelDidBecomeBusy{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showSpinner];
        [self setEnabled:false];
    });
}
-(void)modelDidBecomeRelaxed{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideSpinner];
        [self setEnabled:true];
    });
}
-(void)modelDidClear{
    //other view are handled by updateViews;
    self.consoleView.text=@"";
}

-(void) setEnabled:(BOOL)enabled{
    [self.continueButton setEnabled:enabled];
    [self.stepButton setEnabled:enabled];
    [self.nextButton setEnabled:enabled];
    [self.displayView setUserInteractionEnabled:enabled];
    [self.registersView setUserInteractionEnabled:enabled];
    [self.memoryView setUserInteractionEnabled:enabled];
    [self.filesButton setEnabled:enabled];
    [self.resetButton setEnabled:enabled];
    [self.settingsButton setEnabled:enabled];
}

#pragma mark zoom videoOutput
- (IBAction)displayTapped:(id)sender {
    if (self.displayView.isHidden) {
        return;
    }
    if (!_displayZoomed) {
        CGRect maxBound = self.view.bounds;
        CGFloat newWidth = MIN(maxBound.size.height-44-64, maxBound.size.width);
        CGRect frame=self.displayView.frame;
        frame.size.height = newWidth;
        frame.size.width = newWidth;
        _displayZoomed=true;
        [UIView animateWithDuration:0.3 animations:^(void){
            [self.displayView setFrame:frame];
            [self.displayView setNeedsDisplay];
        }];
    }
    else {
        _displayZoomed=false;
        [UIView animateWithDuration:0.3 animations:^(void){
            [self.displayView setFrame:_displayOriginalFrame];
        }];
    }
}

#pragma mark display menu
-(BOOL)canBecomeFirstResponder{
    return true;
}

- (IBAction)longPressed:(id)sender {
    UILongPressGestureRecognizer* lp=(UILongPressGestureRecognizer*)sender;
    if ([lp state]==UIGestureRecognizerStateBegan) {
        [self becomeFirstResponder];
        Word pointedAddress = [PAUtility locationFromIndexPath:[self indexPathForPointedCell]];
        
        UIMenuItem* item = [[UIMenuItem alloc]initWithTitle:@"set PC" action:@selector(setPCPressed:)];
        UIMenuItem* item2;
        if ([self.model isAtBreakPoint:pointedAddress]) {
            item2 = [[UIMenuItem alloc]initWithTitle:@"cancel Break Point" action:@selector(cancelBPPressed:)];
        }
        else{
            item2 = [[UIMenuItem alloc]initWithTitle:@"set Break Point" action:@selector(setBPPressed:)];
        }
        UIMenuController* menu = [UIMenuController sharedMenuController];
        UITableViewCell* cell=[self.memoryView cellForRowAtIndexPath:_selectedCellIndexPath=[self indexPathForPointedCell]];
        [menu setTargetRect:cell.frame inView:self.memoryView];
        menu.arrowDirection=UIMenuControllerArrowDown;
        menu.menuItems=@[item,item2];
        [menu setMenuVisible:YES animated:true];
    }
}
-(void)setPCPressed:(id)sender{
    self.model.PC=[PAUtility locationFromIndexPath:_selectedCellIndexPath];
    [self.memoryView reloadData];
    [[self registersView] reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:8 inSection:0]]];
}
-(void)cancelBPPressed:(id)sender{;
    [self.model removeBreakPoint:[PAUtility locationFromIndexPath:_selectedCellIndexPath]];
    [self.memoryView reloadData];
}
-(void)setBPPressed:(id)sender{
    [self.model addBreakPoint:[PAUtility locationFromIndexPath:_selectedCellIndexPath]];
    [self.memoryView reloadData];
}
-(NSIndexPath*)indexPathForPointedCell{
    CGPoint point = [self.cellLongPress locationInView:self.memoryView];
    NSIndexPath* ip=[self.memoryView indexPathForRowAtPoint:point];
    //NSLog(@"%d,%d",[ip section],[ip row]);
    return ip;
}
@end
