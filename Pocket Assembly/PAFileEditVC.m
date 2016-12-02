//
//  GYFileEditVC.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/19/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "PAFileEditVC.h"
#import "CYRTextView.h"
#import "AppDelegate.h"
#import "PAInterfaceVC.h"
#import "PAFileModel.h"
#import "PAFileCollectionVC.h"
#import "PAFileDocument.h"
#import "PAFileEditInputAccessoryView.h"

#define RGB(r,g,b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f]

@interface PAFileEditVC ()<MFMailComposeViewControllerDelegate,UITextFieldDelegate,PAFileEditInputAccessoryViewDelegate,UIAlertViewDelegate,UITextViewDelegate>
@property (strong,nonatomic) UIBarButtonItem* mailButton;
@property (strong,nonatomic) UIBarButtonItem* loadButton;
@property (strong,nonatomic) UIBarButtonItem* saveButton;
@property (strong,nonatomic) UIBarButtonItem* cancelButton;
@property (strong,nonatomic) UIBarButtonItem* hideKeyboardButton;
@property (weak,nonatomic) NSLayoutConstraint* keyboardConstraint;
@property (strong, nonatomic) UITextView *textView;
@property (strong,nonatomic) NSData* file;
@property (strong,nonatomic) PAFileEditInputAccessoryView* inputAccessoryView;
@property (nonatomic) BOOL keyboardShown;
@property (nonatomic) BOOL changed;
@end

@implementation PAFileEditVC

-(void)setFile:(NSData*)file{
    _file=file;
    [self loadFile];
}

-(void)loadFile{
    self.textView.text=[[NSString alloc] initWithData:_file encoding:NSUTF8StringEncoding];
}

-(void)awakeFromNib{
    _loadButton=[[UIBarButtonItem alloc]initWithTitle:@"Load" style:UIBarButtonItemStylePlain target:self action:@selector(loadButtonTapped:)];
    _saveButton=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonTapped:)];
    _mailButton=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"mail_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(mailButtonTapped:)];
    _hideKeyboardButton=[[UIBarButtonItem alloc] initWithTitle:@"Hide Keyboard" style:UIBarButtonItemStylePlain target:self action:@selector(hideKeyboardButtonTapped:)];
    [_saveButton setEnabled:false];
    [_hideKeyboardButton setEnabled:false];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem* spaceButton=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceButton.width=20;
    self.navigationItem.rightBarButtonItem=_hideKeyboardButton;

    for (UIBarButtonItem* item in self.toolbarItems) {
        item.tintColor=[UIColor whiteColor];
    }
    /*
     A thousand thanks for illyabusigin, his
     shared code on gitbuh https://github.com/illyabusigin/CYRTextView
     has made the creation of this app much more efficient
     */
    if([[[NSUserDefaults standardUserDefaults] valueForKey:@"UseCustomTextView"] boolValue]){
        _textView = [[CYRTextView alloc] initWithFrame:self.view.bounds];
        CYRToken* comment_t = [CYRToken tokenWithName:@"comment"
                                           expression:@"(;.*\n)|(;.*$)|(;.*\r\n)"
                                           attributes:@{
                                                        NSForegroundColorAttributeName : RGB(2, 117, 52)
                                                        }];
        CYRToken* insructions_t = [CYRToken tokenWithName:@"instructions"
                                               expression:@"\\b(ADD|AND|NOT|ST|STI|STR|LEA|LD|LDI|LDR|BRN|BRZ|BRP|BRNZ|BRNP|BRZP|BRNZP|BR|JMP|JSR|JSRR|RET|RTI|TRAP)\\b"
                                               attributes:@{
                                                            NSForegroundColorAttributeName : RGB(246, 71, 71)
                                                            }];
        CYRToken* directive_t = [CYRToken tokenWithName:@"directives"
                                             expression:@"(\\s((\\.FILL)|\\.STRINGZ|\\.BLKW|\\.ORIG|\\.END)\\b)|^(((\\.FILL)|\\.STRINGZ|\\.BLKW|\\.ORIG|\\.END)\\b)"
                                             attributes:@{
                                                          NSForegroundColorAttributeName : RGB(210, 82, 127)
                                                          }];
        CYRToken* number_t = [CYRToken tokenWithName:@"number"
                                          expression:@"(\\b(0x|#|x)?([0-9]|[a-f]|[A-F])+\\b)|(\\s(0x|#|x)?([0-9]|[a-f]|[A-F])+\\b)"
                                          attributes:@{
                                                       NSForegroundColorAttributeName : RGB(65, 131, 215)
                                                       }];
        CYRToken* string_t = [CYRToken tokenWithName:@"string"
                                          expression:@"\".*?(\"|$)"
                                          attributes:@{
                                                       NSForegroundColorAttributeName : RGB(24, 110, 109)
                                                       }];
        CYRToken* register_t = [CYRToken tokenWithName:@"register"
                                            expression:@"\\bR[0-9]\\b"
                                            attributes:@{
                                                         NSForegroundColorAttributeName : RGB(248, 148, 6)
                                                         }];
        //unfinished
        CYRToken* traps_t = [CYRToken tokenWithName:@"traps"
                                         expression:@"\\b(GETC|OUT|PUTS|IN|PUTSP|HALT)\\b"
                                         attributes:@{
                                                      NSForegroundColorAttributeName : RGB(102, 51,153)
                                                      }];
        [(CYRTextView*)_textView setTokens:@[register_t,string_t,number_t,insructions_t,directive_t,traps_t,comment_t]];
    }
    else{
        _textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    }
    _textView.font=[UIFont fontWithName:[[PAUtility validFonts] objectAtIndex:[PAUtility fontIndex]] size:[(NSNumber*)[[PAUtility validFontSizes] objectAtIndex:[PAUtility fontSizeIndex]] intValue]];
    [_textView setKeyboardType:UIKeyboardTypeASCIICapable];
    _textView.delegate=self;
    [self.view addSubview:_textView];
    [_textView setTranslatesAutoresizingMaskIntoConstraints:false];
    id topGuide = self.topLayoutGuide;
    id bottomGuide = self.bottomLayoutGuide;
    if ([[[UIDevice currentDevice] systemVersion] floatValue]>=8.0) {
        [self.view addConstraints:@[
                                    [NSLayoutConstraint constraintWithItem:_textView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_textView.superview attribute:NSLayoutAttributeTop multiplier:1 constant:0],
                                    
                                    _keyboardConstraint=[NSLayoutConstraint constraintWithItem:_textView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_textView.superview attribute:NSLayoutAttributeBottom multiplier:1 constant:0]
                                    ]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"H:|-0-[_textView]-0-|"
                                                                          options: NSLayoutFormatDirectionLeadingToTrailing
                                                                          metrics: nil
                                                                            views: NSDictionaryOfVariableBindings (_textView)]];
    }
    else{
        [self.view addConstraints:@[
                                    [NSLayoutConstraint constraintWithItem:_textView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
                                    
                                    _keyboardConstraint=[NSLayoutConstraint constraintWithItem:_textView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:-self.navigationController.toolbar.frame.size.height]
                                    ]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"H:|-0-[_textView]-0-|"
                                                                          options: NSLayoutFormatDirectionLeadingToTrailing
                                                                          metrics: nil
                                                                            views: NSDictionaryOfVariableBindings (_textView)]];
    }
    if(_file){
        [self loadFile];
    }else{
        [self.textView setEditable:false];
        [self.textView setText:@"Create a new file or open an existing file."];
    }
    
    if (self.file!=nil) {
        if (!self.enableEditing) {
            self.toolbarItems=@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],_mailButton,spaceButton,_loadButton,];
            [self.textView setEditable:false];
        }
        else{
            self.toolbarItems=@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],_mailButton,spaceButton,_saveButton,spaceButton,_loadButton,];
            [self.textView setEditable:true];
        }
    }
    self.navigationItem.leftItemsSupplementBackButton=false;
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Files" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonTapped:)];
}

/*UIKit seems to be automatically calling this method, rather than we setting it by
 our selves*/
- (PAFileEditInputAccessoryView *)inputAccessoryView {
    
    if (!_inputAccessoryView) {
        NSString *nibName = NSStringFromClass([PAFileEditInputAccessoryView class]);
        NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
        PAFileEditInputAccessoryView *view = [nibViews objectAtIndex:0];
        if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone) {
            [view setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, INPUT_ACCESSORY_VIEW_HEIGHT_PHONE)];
        }
        else if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad){
            [view setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, INPUT_ACCESSORY_VIEW_HEIGHT_PAD)];
        }
        _inputAccessoryView=view;
        _inputAccessoryView.delegate=self;
    }
    return self.enableEditing?_inputAccessoryView:nil;
}

-(void)addString:(NSString *)text{
    [self.textView insertText:text];
    [self setChanged:true];
    [self.saveButton setEnabled:true];
}

-(void)viewWillAppear:(BOOL)animated{
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillShow:)
                               name:UIKeyboardWillShowNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillHide:)
                               name:UIKeyboardWillHideNotification
                             object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - alertView deledate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex==1) {
        [self saveButtonTapped:nil];
    }
    [self.navigationController popViewControllerAnimated:true];
}


#pragma mark - text view delegate
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    _changed=true;
    [_saveButton setEnabled:true];
    return true;
}

#pragma mark - handle keyboard
-(void)keyboardWillShow:(NSNotification*)not{
    [UIView animateWithDuration:0.3 animations:^{
            if ([[[UIDevice currentDevice] systemVersion] floatValue]>=8.0) {
                self.keyboardConstraint.constant=self.navigationController.toolbar.frame.size.height-[(NSValue*)[[not userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
            }else{
                self.keyboardConstraint.constant=-[(NSValue*)[[not userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
            }
        [self.view layoutIfNeeded];
    }];
                [self.hideKeyboardButton setEnabled:true];
            }
-(void)keyboardWillHide:(NSNotification*)not{
    [UIView animateWithDuration:0.3 animations:^{
                    if ([[[UIDevice currentDevice] systemVersion] floatValue]>=8.0) {
        self.keyboardConstraint.constant=0;
                    }else{
                        self.keyboardConstraint.constant=-self.navigationController.toolbar.frame.size.height;
                    }
        [self.view layoutIfNeeded];
    }];
    [self.hideKeyboardButton setEnabled:false];
}


#pragma mark - handle touch events
-(void)mailButtonTapped:(UIBarButtonItem*)button{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        NSInteger numberOfViewControllers = self.navigationController.viewControllers.count;
        PAFileCollectionVC* collectionVC=[self.navigationController.viewControllers objectAtIndex:numberOfViewControllers - 2];
        NSString* filename =[[[collectionVC.selectedDocument fileURL] lastPathComponent] stringByDeletingPathExtension];
        [mailViewController setSubject:filename];
        [mailViewController addAttachmentData:[self.textView.text dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/plain" fileName:[filename stringByAppendingString:@".asm"]];
        [self presentViewController:mailViewController animated:true completion:nil];
    }
    else {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Unable To Mail" message:@"Pocket Assembly Is not allowed to send mail on this device." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];
    }
}

-(void)loadButtonTapped:(UIBarButtonItem*)button{
    if ([self enableEditing]) {
        [self saveButtonTapped:button];
    }
    PAInterfaceVC* mainInterface=[(AppDelegate*)[[UIApplication sharedApplication] delegate] mainInterface];
    if (!mainInterface) {
        mainInterface=[[self storyboard] instantiateViewControllerWithIdentifier:@"interfaceVC"];
    }
    PAError* error=nil;
    PAFileModel* model=[PAFileModel fileModelWithContent:self.textView.text Error:&error];
    if (model!=nil) {
        if ([mainInterface loadModel:model]) {
            //if auto return
            if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"AutoReturn"] boolValue]) {
                [self.navigationController popToRootViewControllerAnimated:true];
            }
        }
    }
    else{
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:[PAError titleForErrorType:error.type] message:error.message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];
    }
    
}
-(void)saveButtonTapped:(UIBarButtonItem*)button{
    NSData* file=[self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
    NSInteger numberOfViewControllers = self.navigationController.viewControllers.count;
    PAFileCollectionVC* collectionVC=[self.navigationController.viewControllers objectAtIndex:numberOfViewControllers - 2];
    [collectionVC saveCurrentFile:file];
    _file=file;
    [self.textView resignFirstResponder];
    [self.saveButton setEnabled:false];
    self.changed=false;
}

-(void)hideKeyboardButtonTapped:(UIBarButtonItem*)button{
    [self.textView resignFirstResponder];
}
-(void)backButtonTapped:(UIBarButtonItem*)button{
    if (self.file&&self.changed&&self.enableEditing) {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Unsaved Change" message:@"The file has unsaved changed. Do you want to save before leaving?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Save", nil];
        alert.delegate=self;
        [alert show];
    }
    else{
        [self.navigationController popViewControllerAnimated:true];
    }
}
#pragma mark mailComposeDelegate
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
