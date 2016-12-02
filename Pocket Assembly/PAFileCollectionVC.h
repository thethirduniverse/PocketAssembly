//
//  GYFileCollectionVC.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/19/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PAFileDocument;

@interface PAFileCollectionVC : UITableViewController<UITextFieldDelegate>
/*
 Once a file is opened, the viewcontroller keeps a record of the current opening file,
 using this method to overwrite the content of the file.
 Parameter: file, the NSData representation of the content of file to be saved
 */
-(void)saveCurrentFile:(NSData*)file;

/*
 Loads file at URL provided.
 Parameter: file, the URL of file to be opened
 Returns: always true
 */
-(BOOL)loadTextFileFromURL:(NSURL*)file;

/*
 When opening a file from iOS. The system copies the file to the app's inbox folder.
 After copying the file to proper position in the app directory, this method is needed to
 clean up the local inbox to prevent jamming.
 */
-(void)deleteInbox;

/*the current opening document*/
@property (strong,nonatomic) PAFileDocument* selectedDocument;

@end
