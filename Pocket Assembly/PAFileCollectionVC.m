//
//  GYFileCollectionVC.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/19/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//
//  UIDocument and file management code modified from
//  Ray Wenderlich's excellent tutorial:
//  http://www.raywenderlich.com/12779/icloud-and-uidocument-beyond-the-basics-part-1

#import "PAFileCollectionVC.h"
#import "PAFileDocument.h"
#import "PAFileEditVC.h"
#import "PAFileEntry.h"
#import "PAUtility.h"
#import "PADiscardableTextField.h"
#import "AppDelegate.h"
#import "PAInterfaceVC.h"

@interface PAFileCollectionVC (){
    NSURL* _localRoot;
    NSMutableArray* _objects;
    BOOL _keyboardShown;
    NSArray* _localDocuments;
}
@property (strong,nonatomic) UIActivityIndicatorView* spinner;
@end

@implementation PAFileCollectionVC

#pragma mark ViewController Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    _objects=[[NSMutableArray alloc] init];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.toolbarItems=@[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],addButton];
    self.navigationItem.leftItemsSupplementBackButton=true;
    
    self.tableView.dataSource=self;
    self.tableView.delegate=self;
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    
    self.spinner= [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.center=self.view.center;
    self.spinner.backgroundColor = [UIColor blackColor];
    [self.spinner layer].cornerRadius = 8.0;
    [self.spinner layer].masksToBounds = YES;
    
    [self refresh];
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

#pragma mark Handling Keyboard
-(void)keyboardWillShow:(NSNotification*)not{
    if (!_keyboardShown) {
        CGRect frame = self.tableView.frame;
        frame.size.height-=[(NSValue*)[[not userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
        self.tableView.frame=frame;
        _keyboardShown=true;
    }
}
-(void)keyboardWillHide:(NSNotification*)not{
    _keyboardShown=false;
    CGRect frame = self.tableView.frame;
    frame.size.height+=[(NSValue*)[[not userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    self.tableView.frame=frame;
}

#pragma mark Handling Spinner
-(void)showSpinner{
    [self.spinner startAnimating];
    [self.view addSubview:self.spinner];
}
-(void)hideSpinner{
    [self.spinner stopAnimating];
    [self.spinner removeFromSuperview];
}

#pragma mark File URLs

- (BOOL)iCloudOn {
    return NO;
}

/*
 Returns the URL to the local Document Directory
 */
- (NSURL *)localRoot {
    if (_localRoot != nil) {
        return _localRoot;
    }
    
    NSArray * paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    _localRoot = [paths objectAtIndex:0];
    return _localRoot;
}

/*
 Appending the filename to current document directory to get the full directory
 */
- (NSURL *)getDocURL:(NSString *)filename {
    if ([self iCloudOn]) {
        return nil;
    } else {
        return [self.localRoot URLByAppendingPathComponent:filename];
    }
}

/*
 Checks if there is already a file named docName
 */
- (BOOL)docNameExistsInObjects:(NSString *)docName {
    BOOL nameExists = NO;
    for (PAFileEntry * entry in _objects) {
        if ([[entry.fileURL lastPathComponent] isEqualToString:docName]) {
            nameExists = YES;
            break;
        }
    }
    return nameExists;
}

/*
 Get a unique name with prefix.
 The new names will be generated using the following pattern:
 name   name_0  name_1  name_2  name_3  ...
 Currently only supports uniqueInObjects == true
 */
- (NSString*)getDocFilename:(NSString *)prefix uniqueInObjects:(BOOL)uniqueInObjects {
    NSInteger docCount = 0;
    NSString* newDocName = nil;
    
    // At this point, the document list should be up-to-date.
    BOOL done = NO;
    BOOL first = YES;
    while (!done) {
        if (first) {
            first = NO;
            newDocName = [NSString stringWithFormat:@"%@.%@",
                          prefix, GY_FILE_EXTENSION];
        } else {
            newDocName = [NSString stringWithFormat:@"%@_%d.%@",
                          prefix, (int)docCount, GY_FILE_EXTENSION];
        }
        
        // Look for an existing document with the same name. If one is
        // found, increment the docCount value and try again.
        BOOL nameExists;
        if (uniqueInObjects) {
            nameExists = [self docNameExistsInObjects:newDocName];
        } else {
            return nil;
        }
        if (!nameExists) {
            break;
        } else {
            docCount++;
        }
        
    }
    
    return newDocName;
}

#pragma mark Entry management methods

- (int)indexOfEntryWithFileURL:(NSURL *)fileURL {
    __block int retval = -1;
    [_objects enumerateObjectsUsingBlock:^(PAFileEntry * entry, NSUInteger idx, BOOL *stop) {
        if ([entry.fileURL isEqual:fileURL]) {
            retval = (int)idx;
            *stop = YES;
        }
    }];
    return retval;
}

- (void)addOrUpdateEntryWithURL:(NSURL *)fileURL metadata:(PAFileSnapshot*)snapshot state:(UIDocumentState)state version:(NSFileVersion *)version {
    
    int index = [self indexOfEntryWithFileURL:fileURL];
    
    // Not found, so add
    if (index == -1) {
        PAFileEntry* entry = [[PAFileEntry alloc] initWithFileURL:fileURL metadata:snapshot state:state version:version];
        [_objects addObject:entry];
        [_objects sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[[(PAFileEntry*)obj2 snapshot] modificationDate] compare:[[(PAFileEntry*)obj1 snapshot] modificationDate]];
        }];
        [self.tableView reloadData];
    }
    // Found, so edit
    else {
        PAFileEntry* entry = [_objects objectAtIndex:index];
        entry.snapshot = snapshot;
        entry.state = state;
        entry.version = version;
        [_objects sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[[(PAFileEntry*)obj2 snapshot] modificationDate] compare:[[(PAFileEntry*)obj1 snapshot] modificationDate]];
        }];
        [self.tableView reloadData];
    }
    
}
- (void)removeEntryWithURL:(NSURL *)fileURL {
    int index = [self indexOfEntryWithFileURL:fileURL];
    [_objects removeObjectAtIndex:index];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
}
- (void)deleteEntry:(PAFileEntry *)entry {
    
    // Simple delete to start
    NSFileManager* fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtURL:entry.fileURL error:nil];
    // Fixup view
    [self removeEntryWithURL:entry.fileURL];
    
}

- (BOOL)renameEntry:(PAFileEntry *)entry to:(NSString *)filename {
    
    // Bail if not actually renaming
    if ([entry.description isEqualToString:filename]) {
        return YES;
    }
    
    // Check if can rename file
    NSString * newDocFilename = [NSString stringWithFormat:@"%@.%@",
                                 filename, GY_FILE_EXTENSION];
    if ([self docNameExistsInObjects:newDocFilename]) {
        NSString * message = [NSString stringWithFormat:@"\"%@\" is already taken.  Please choose a different name.", filename];
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView setTintColor:[PAUtility tintDarkPurple]];
        [alertView show];
        return NO;
    }
    
    NSURL * newDocURL = [self getDocURL:newDocFilename];
    //NSLog(@"Moving %@ to %@", entry.fileURL, newDocURL);
    
    // Simple renaming to start
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError * error;
    BOOL success = [fileManager moveItemAtURL:entry.fileURL toURL:newDocURL error:&error];
    if (!success) {
        //NSLog(@"Failed to move file: %@", error.localizedDescription);
        return NO;
    }
    
    // Fix up entry
    entry.fileURL = newDocURL;
    int index = [self indexOfEntryWithFileURL:entry.fileURL];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    
    return YES;
    
}

- (void)insertNewObject:(id)sender
{
    [self insertNewObject:sender WithName:nil];
}
- (void)insertNewObject:(id)sender WithName:(NSString*)name{
    // Determine a unique filename to create
    NSURL * fileURL = [self getDocURL:[self getDocFilename:(name!=nil?name:@"New_File") uniqueInObjects:YES]];
    
    // Create new document and save to the filename
    PAFileDocument* document = [[PAFileDocument alloc] initWithFileURL:fileURL];
    [document saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        if (!success) {
            NSLog(@"Failed to create file at %@", fileURL);
            return;
        }
        PAFileSnapshot * snapshot = document.snapshot;
        NSURL * fileURL = document.fileURL;
        UIDocumentState state = document.documentState;
        NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
        
        // Add on the main thread and perform the segue
        _selectedDocument = document;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addOrUpdateEntryWithURL:fileURL metadata:snapshot state:state version:version];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self indexOfEntryWithFileURL:fileURL] inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
            UITextField* field=(UITextField*)[[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self indexOfEntryWithFileURL:fileURL] inSection:0]] contentView] viewWithTag:3];
            field.text=@"";
            [self setEditing:true animated:true];
            [field becomeFirstResponder];
        });
        
    }];
}

#pragma mark File Management
-(BOOL)loadTextFileFromURL:(NSURL*)file{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showSpinner];
    });
    [self loadLocalWithCompletionHandler:^(bool success) {
            NSString* name=[file.lastPathComponent stringByDeletingPathExtension];
            NSURL * fileURL = [self getDocURL:[self getDocFilename:(name!=nil?name:@"New_File") uniqueInObjects:YES]];
            // Create new document and save to the filename
            PAFileDocument* document = [[PAFileDocument alloc] initWithFileURL:fileURL];
            document.file = [NSData dataWithContentsOfURL:file];
            [document saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                [self deleteInbox];
                if (!success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"File is not successfully opened and not copied to the storage of Pocket Assembly. File URL: %@",file.description);
                        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Open Failed" message:@"File is not successfully opened and not copied to the storage of Pocket Assembly." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
                        [alert show];
                    });
                    return;
                }
                
                PAFileSnapshot * snapshot = document.snapshot;
                NSURL * fileURL = document.fileURL;
                UIDocumentState state = document.documentState;
                NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
                _selectedDocument=document;
                // Add on the main thread and perform the segue
                [document closeWithCompletionHandler:^(BOOL success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self hideSpinner];
                        [self addOrUpdateEntryWithURL:fileURL metadata:snapshot state:state version:version];
                        PAFileEditVC* editVC=[[self storyboard] instantiateViewControllerWithIdentifier:@"fileEditVC"];
                        _selectedDocument=document;
                        [editVC setFile:_selectedDocument.file];
                        /*check here!!*/
                        [editVC setEnableEditing:!_selectedDocument.snapshot.isProtected];
                        [editVC setTitle:[[_selectedDocument.fileURL lastPathComponent] stringByDeletingPathExtension]];
                        [self.navigationController pushViewController:editVC animated:true];
                        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Open Succuess" message:@"File is successfully opened and copied to the storage of Pocket Assembly." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
                        [alert show];
                    });
                }];
            }];
    }];
    return true;
}


-(void)saveFileName:(UITextField*)textField{
    UIView* view=textField;
    while (![view isMemberOfClass:[UITableViewCell class]]) {
        view=view.superview;
    }
    
    if ([textField.text isEqualToString:[(PADiscardableTextField*)textField previousValue]]) {
        return;
    }
    
    if ([self docNameExistsInObjects:textField.text]) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Name Conflict" message:[NSString stringWithFormat:@"There is already another file having the name: %@ . Please consider a unique name.",textField.text] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alertView show];
        [(PADiscardableTextField*)textField discardChange];
    }
    else{
        NSRange range = [textField.text rangeOfString:[PAUtility validFileNameRegex] options:NSRegularExpressionSearch];
        if (range.location==0&&range.length==textField.text.length) {
            [self renameEntry:_objects[[self.tableView indexPathForCell:(UITableViewCell*)view].row] to:textField.text];
            [(PADiscardableTextField*)textField keepChange];
        }
        else{
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Invalid Filename" message:[NSString stringWithFormat:@"Valid Filename must be composed entirely of alphanumeric characters, underscore (_)."] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
            [alertView show];
            [(PADiscardableTextField*)textField discardChange];
        }
    }
}

- (void)loadLocalWithCompletionHandler:(void(^)(bool success))handler{
    [_objects removeAllObjects];
    _localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.localRoot includingPropertiesForKeys:nil options:0 error:nil];
    if (_localDocuments.count!=0) {
        [self loadDocAtIndex:0 withCompletionHandler:handler];
    }
}

-(void)loadDocAtIndex:(int)index withCompletionHandler:(void(^)(bool success))handler{
    NSURL* fileURL=[_localDocuments objectAtIndex:index];
    if ([[fileURL pathExtension] isEqualToString:GY_FILE_EXTENSION]) {
        //NSLog(@"Found local file: %@", fileURL);
        PAFileDocument * doc = [[PAFileDocument alloc] initWithFileURL:[_localDocuments objectAtIndex:index]];
        if (index!=[_localDocuments count]-1) {
            [doc openWithCompletionHandler:^(BOOL success) {
                // Check status
                if (!success) {
                    //NSLog(@"Failed to open %@", [[_localDocuments objectAtIndex:index] description]);
                    [self loadDocAtIndex:index+1 withCompletionHandler:handler];
                }
                // Preload metadata on background thread
                PAFileSnapshot * snapshot=doc.snapshot;
                NSURL * fileURL = doc.fileURL;
                UIDocumentState state = doc.documentState;
                NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
                //NSLog(@"Loaded File URL: %@", [doc.fileURL lastPathComponent]);
                
                // Close since we're done with it
                [doc closeWithCompletionHandler:^(BOOL success) {
                    // Check status
                    if (!success) {
                        //NSLog(@"Failed to close %@", fileURL);
                        // Continue anyway...
                    }
                    [self loadDocAtIndex:index+1 withCompletionHandler:handler];
                    // Add to the list of files on main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self addOrUpdateEntryWithURL:fileURL metadata:snapshot state:state version:version];
                    });
                }];
            }];
        }
        else{
            [doc openWithCompletionHandler:^(BOOL success) {
                // Check status
                if (!success) {
                    //NSLog(@"Failed to open %@", [[_localDocuments objectAtIndex:index] description]);
                    return;
                }
                // Preload metadata on background thread
                PAFileSnapshot * snapshot=doc.snapshot;
                NSURL * fileURL = doc.fileURL;
                UIDocumentState state = doc.documentState;
                NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
                //NSLog(@"Loaded File URL: %@", [doc.fileURL lastPathComponent]);
                
                // Close since we're done with it
                [doc closeWithCompletionHandler:^(BOOL success) {
                    
                    // Check status
                    if (!success) {
                        //NSLog(@"Failed to close %@", fileURL);
                        // Continue anyway...
                    }
                    
                    // Add to the list of files on main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self addOrUpdateEntryWithURL:fileURL metadata:snapshot state:state version:version];
                        if(handler!=NULL){
                            handler(success);
                        }
                    });
                }];
            }];
        }
    }else{
        if (index!=[_localDocuments count]-1) {
            [self loadDocAtIndex:index+1 withCompletionHandler:handler];
        }else{
            if(handler!=NULL){
                handler(true);
            }
        }
    }
}

-(void)saveCurrentFile:(NSData*)file{
    _selectedDocument.file=file;
    _selectedDocument.snapshot.modificationDate=[[NSDate alloc]init];
    [_selectedDocument saveToURL:_selectedDocument.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success){
        NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:_selectedDocument.fileURL];
        [self addOrUpdateEntryWithURL:_selectedDocument.fileURL metadata:_selectedDocument.snapshot state:_selectedDocument.documentState version:version];
    }];
}

#pragma mark Event Handling
-(void)backButtonTapped:(UIBarButtonItem*)button{
    PAInterfaceVC* mainInterface=[(AppDelegate*)[[UIApplication sharedApplication] delegate] mainInterface];
    if (!mainInterface) {
        mainInterface=[[self storyboard] instantiateViewControllerWithIdentifier:@"interfaceVC"];
    }
    [mainInterface dismissViewControllerAnimated:true completion:nil];
}

-(void)editButtonTapped:(UIBarButtonItem* )button{
    [self setEditing:!self.tableView.editing animated:true];
}

#pragma mark Editing
-(void)setEditing:(BOOL)editing animated:(BOOL)animated{
    if (editing) {
        NSArray* cells = [self.tableView visibleCells];
        for (UITableViewCell* cell in cells) {
            PADiscardableTextField* textField=(PADiscardableTextField*)[cell viewWithTag:3];
            if (!((PAFileEntry*)_objects[[self.tableView indexPathForCell:cell].row]).snapshot.isProtected) {
                [textField setUserInteractionEnabled:true];
                [textField setDelegate:self];
                [textField setClearButtonMode:UITextFieldViewModeAlways];
            }
        }
    }
    else{
        NSArray* cells = [self.tableView visibleCells];
        for (UITableViewCell* cell in cells) {
            PADiscardableTextField* textField=(PADiscardableTextField*)[cell viewWithTag:3];
            if ([textField isFirstResponder]) {
                [self saveFileName:textField];
                [textField resignFirstResponder];
            }
            [textField setClearButtonMode:UITextFieldViewModeNever];
            [textField setUserInteractionEnabled:false];
            [textField setDelegate:nil];
        }
    }
    [super setEditing:editing animated:animated];
}

#pragma mark Delete Inbox
-(void)deleteInbox{
    NSDirectoryEnumerator* en = [[NSFileManager defaultManager] enumeratorAtPath:[[[self localRoot] path] stringByAppendingPathComponent:@"Inbox"]];
    NSString* inboxFilePath;
    NSError* error=nil;
    while ((inboxFilePath=en.nextObject)) {
        NSURL* inboxFileFullPath = [[[NSURL fileURLWithPath:[[self localRoot] path]]URLByAppendingPathComponent:@"Inbox"] URLByAppendingPathComponent:inboxFilePath];
        [[NSFileManager defaultManager] removeItemAtURL:inboxFileFullPath error:&error];
        if (error) {
            NSLog(@"error occurred while deleting inbox:%@",[error description]);
        }
    }
}

#pragma mark Refresh Methods
- (void)refresh {
    [_objects removeAllObjects];
    [self.tableView reloadData];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self.toolbarItems[0] setEnabled:false];
    [self showSpinner];
    if (![self iCloudOn]) {
        [self loadLocalWithCompletionHandler:^(bool success) {
            self.navigationItem.rightBarButtonItem.enabled=true;
            [self.toolbarItems[0] setEnabled:true];
            [self hideSpinner];
        }];
    }
}

#pragma mark UITextFieldDelegate
-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    [self textFieldDidEndEditing:textField];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    [self saveFileName:textField];
    [self setEditing:false animated:true];
    [textField resignFirstResponder];
}

#pragma mark TableView Data Source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _objects.count;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.tableView.isEditing) {
        PADiscardableTextField* textField=(PADiscardableTextField*)[cell viewWithTag:3];
        if (((PAFileEntry*)_objects[indexPath.row]).snapshot.isProtected) {
            [textField setUserInteractionEnabled:true];
            [textField setDelegate:self];
            [textField setClearButtonMode:UITextFieldViewModeAlways];
        }else{
            [textField setUserInteractionEnabled:false];
            [textField setDelegate:nil];
            [textField setClearButtonMode:UITextFieldViewModeNever];
        }
    }
    else{
        PADiscardableTextField* textField=(PADiscardableTextField*)[cell viewWithTag:3];
        [textField setUserInteractionEnabled:false];
        [textField setDelegate:nil];
        [textField setClearButtonMode:UITextFieldViewModeNever];
        if ([textField isFirstResponder]) {
            [self saveFileName:textField];
            [self resignFirstResponder];
        }
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fileCell"];
    PAFileEntry *entry = [_objects objectAtIndex:indexPath.row];
    [(PADiscardableTextField*)[cell viewWithTag:3] setAndSaveText:entry.description];
    [(UILabel*)[cell viewWithTag:1] setText:[NSString stringWithFormat:@"Create Date: %@",[[PAUtility universalDateFormatter]stringFromDate:entry.snapshot.createDate]]];
    [(UILabel*)[cell viewWithTag:2] setText:[NSString stringWithFormat:@"Modif. Date: %@",[[PAUtility universalDateFormatter]stringFromDate:entry.snapshot.modificationDate]]];
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath{
    return true;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return ![(PAFileDocument*)_objects[indexPath.row] snapshot].isProtected;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle==UITableViewCellEditingStyleDelete) {
        [self deleteEntry:_objects[indexPath.row]];
    }
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    PAFileEntry* entry=_objects[indexPath.row];
    if (_selectedDocument&&_selectedDocument.fileURL!=entry.fileURL) {
        [_selectedDocument closeWithCompletionHandler:^(BOOL success){
            //NSLog(@"Did finish closing document success: %d",success);
        }];
    }
    _selectedDocument=[[PAFileDocument alloc] initWithFileURL:entry.fileURL];
    [_selectedDocument openWithCompletionHandler:^(BOOL success) {
        PAFileEditVC* destination=[[self storyboard] instantiateViewControllerWithIdentifier:@"fileEditVC"];
        [destination setFile:[_selectedDocument file]];
        destination.title=[[_selectedDocument.fileURL lastPathComponent] stringByDeletingPathExtension];
        [destination setEnableEditing:!_selectedDocument.snapshot.isProtected];
        [self.navigationController pushViewController:destination animated:true];
    }];
}


#pragma mark - Navigation
-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    return NO;
}

@end
