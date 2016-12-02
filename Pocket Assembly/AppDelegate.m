//
//  AppDelegate.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/8/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "AppDelegate.h"
#import "PAFileDocument.h"
#import "PAFileSnapshot.h"
#import "PAUtility.h"
#import "PAInterfaceVC.h"

@interface AppDelegate ()<UIAlertViewDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    if (![[NSUserDefaults standardUserDefaults] valueForKey:@"DefaultsInitialized"]) {
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:true] forKey:@"DefaultsInitialized"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:4] forKey:@"TextSize"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:4] forKey:@"CodeFont"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:true] forKey:@"AutoloadOS"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:true] forKey:@"ShowVideoOutput"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:true] forKey:@"PlaySound"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:true] forKey:@"AutoReturn"];
        
        NSString* originalOSPath = [[NSBundle mainBundle] pathForResource:@"lc3os" ofType:@"txt"];
        NSURL* rootURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
        NSURL* newOSURL=[rootURL URLByAppendingPathComponent:[NSString stringWithFormat:@"lc3os.%@",GY_FILE_EXTENSION]];
        
        NSFileManager* fm = [NSFileManager defaultManager];
        NSString* path =[rootURL path];
        NSDirectoryEnumerator* en = [fm enumeratorAtPath:path];
        NSError* err = nil;
        BOOL res;
        
        NSString* file;
        while (file = [en nextObject]) {
            if ([[file pathExtension] isEqualToString:GY_FILE_EXTENSION]) {
                res = [fm removeItemAtPath:[path stringByAppendingPathComponent:file] error:&err];
                if (!res && err) {
                    NSLog(@"Error occurred while deleting file %@", err);
                }
            }
        }
        
        PAFileDocument* document = [[PAFileDocument alloc]initWithFileURL:newOSURL];
        document.file=[[NSFileManager defaultManager] contentsAtPath:originalOSPath];
        document.snapshot=[[PAFileSnapshot alloc] init];
        document.snapshot.createDate=[[NSDate alloc]init];
        document.snapshot.modificationDate=[[NSDate alloc]init];
        document.snapshot.isProtected=true;
        [document saveToURL:newOSURL forSaveOperation:UIDocumentSaveForCreating completionHandler:nil];
    }
    if (![[NSUserDefaults standardUserDefaults] valueForKey:@"DefaultsInitialized_1.1"]) {
        //add a sample program
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:true] forKey:@"DefaultsInitialized_1.1"];
        NSString* originalSamplePath = [[NSBundle mainBundle] pathForResource:@"printDec" ofType:@"txt"];
        NSURL* rootURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
        NSURL* newSampleURL=[rootURL URLByAppendingPathComponent:[NSString stringWithFormat:@"printDec_sample.%@",GY_FILE_EXTENSION]];
        PAFileDocument* document = [[PAFileDocument alloc]initWithFileURL:newSampleURL];
        document.file=[[NSFileManager defaultManager] contentsAtPath:originalSamplePath];
        document.snapshot=[[PAFileSnapshot alloc] init];
        document.snapshot.createDate=[[NSDate alloc]init];
        document.snapshot.modificationDate=[[NSDate alloc]init];
        [document saveToURL:newSampleURL forSaveOperation:UIDocumentSaveForCreating completionHandler:nil];
    }
    if (![[NSUserDefaults standardUserDefaults] valueForKey:@"DefaultsInitialized_1.2"]) {
        //change isProtected propery to true to prevent it from being changed
        //previously this is done by checking if the filename is 'lc3os'
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:true] forKey:@"DefaultsInitialized_1.2"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:true] forKey:@"UseCustomTextView"];
        NSURL* rootURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
        NSURL* OSURL=[rootURL URLByAppendingPathComponent:[NSString stringWithFormat:@"lc3os.%@",GY_FILE_EXTENSION]];
        PAFileDocument* os = [[PAFileDocument alloc] initWithFileURL:OSURL];
        [os openWithCompletionHandler:^(BOOL success) {
            if (!success) {
                NSLog(@"defaults initializing 1.2 : attempt to open os failed");
                return;
            }
            os.snapshot.isProtected=true;
            [os saveToURL:os.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success){
                if (!success) {
                    NSLog(@"defaults initializing 1.2 : attempt to save os failed");
                    return;
                }
            }];
        }];
    }
    
    if(![[NSUserDefaults standardUserDefaults] valueForKey:@"DefaultsInitialized_1.3"]){
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:true] forKey:@"DefaultsInitialized_1.3"];
        [[NSUserDefaults standardUserDefaults] setValue:@(3) forKey:@"OpenCount"];
    }
    
    int openCount = [[[NSUserDefaults standardUserDefaults] valueForKey:@"OpenCount"] intValue] - 1;
    if (openCount==0) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue]>=8.0) {
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Please Rate This App!"
                                                  message:nil
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *go = [UIAlertAction
                                           actionWithTitle:@"Rate"
                                           style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action)
                                       {
                                           [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/pocket-assembly/id959802466?ls=1&mt=8"]];
                                           [[NSUserDefaults standardUserDefaults] setValue:@(0) forKey:@"OpenCount"];
                                       }];
            UIAlertAction *later = [UIAlertAction
                                                 actionWithTitle:@"Later"
                                                 style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action)
                                                 {
                                                     [[NSUserDefaults standardUserDefaults] setValue:@(3) forKey:@"OpenCount"];
                                                 }];
            UIAlertAction *never = [UIAlertAction
                                                   actionWithTitle:@"Never"
                                                   style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action)
                                                   {
                                                       [[NSUserDefaults standardUserDefaults] setValue:@(0) forKey:@"OpenCount"];
                                                   }];
            [alertController addAction:go];
            [alertController addAction:later];
            [alertController addAction:never];
            [alertController.view setTintColor:[PAUtility tintDarkPurple]];
            [self.mainInterface presentAlertWhenReady:alertController];
        }
        else{
            [[[UIAlertView alloc] initWithTitle:@"Please Rate This App!" message:@"Your feed back can help us make the app better." delegate:self cancelButtonTitle:@"Never" otherButtonTitles:@"Rate",@"Later", nil] show];
        }
    }
    else if(openCount > 0){
        [[NSUserDefaults standardUserDefaults] setValue:@(openCount) forKey:@"OpenCount"];
    }
    return YES;
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0: //never
            [[NSUserDefaults standardUserDefaults] setValue:@(0) forKey:@"OpenCount"];
            break;
        case 1: //rate
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/pocket-assembly/id959802466?ls=1&mt=8"]];
            [[NSUserDefaults standardUserDefaults] setValue:@(0) forKey:@"OpenCount"];
            break;
        case 2: //later
            [[NSUserDefaults standardUserDefaults] setValue:@(3) forKey:@"OpenCount"];
            break;
        default:
            break;
    }
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation{
    [self.mainInterface loadFileWithURL:url];
    return true;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
