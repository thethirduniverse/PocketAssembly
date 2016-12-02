//
//  GYPAModel.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/12/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PAUtility.h"
#import "PAMdlDcdExctnOperation.h"
@class PAFileModel;

/*Delegate methods used to signal the state of model*/
@protocol PAModelDelegate <NSObject>
@required
-(void)didFailLoadingFileWithError:(PAError*)error;
-(void)didFinishLoadingFileModel:(PAFileModel*)model showAlert:(BOOL)alert;
-(void)didFinishExecutionWithPC:(Word)pc;
-(void)outputChar:(Word)character;
-(void)modelDidBecomeBusy;
-(void)modelDidBecomeRelaxed;
-(void)modelDidClear;
@end

@interface PAModel : NSObject <UITableViewDataSource,UICollectionViewDataSource,PAMdlDcdExctnOperationDelegate>

/*model execution*/
-(void)continueExecutionUsingMode:(PAExecuteMode)mode;
-(void)suspend; /*suspends the execution*/

/*accessor and setter for memory*/
-(Word)memoryFromLocation:(Word)location;
-(void)setMemoryAtLocation:(Word)location newValue:(Word)nv;

/*accessor of labels*/
-(NSString*)labelAtLocation:(Word)location;
//-(NSNumber*)locationOfLabel:(NSString*)label;//return nil if not found

/*loading file*/
-(BOOL)loadFile:(PAFileModel*)file showAlert:(BOOL)alert;

/*breakpoint management*/
-(BOOL)isAtBreakPoint;
-(void)addBreakPoint:(Word)address;
-(void)removeBreakPoint:(Word)address;
-(BOOL)isAtBreakPoint:(Word)address;
-(void)initializeBreakPoint;
/*clear the model, set everything to 0*/
-(void)clearModel;
-(void)initializeRegisters;

/*keyboard input*/
-(void)keyboardDidEnterCharacter:(char)character;
-(void)setKeyboardStatus:(BOOL)ready;

@property (assign,nonatomic) NSObject<PAModelDelegate>* delegate;
@property (nonatomic) Word PC;
@property (nonatomic) Word CC;
@property (nonatomic) Word MPR;
@property (nonatomic) Word PSR;
@property (readonly) Word* registers;
@property (readonly) Word* memory;
@end
