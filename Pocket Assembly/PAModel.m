//
//  GYPAModel.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 12/12/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PAModel.h"
#import "PABidirectionalDictionary.h"
#import "PAMemoryLocationCell.h"
#import "PARegistersDisplayCell.h"
#import "PAInstructionLine.h"
#import "PAFileModel.h"
#import "PAFileDocument.h"
#import "PAMdlDcdExctnOperation.h"

@interface PAModel()
{
    Word* _registers;
    Word* _memory;
    //Word _registers[8];
    //Word _memory[USHRT_MAX];
}
@property (nonatomic,strong) NSOperationQueue* defaultQueue;
@property (nonatomic,strong) PAMdlDcdExctnOperation* currentOperation;
@property (nonatomic,strong) PABidirectionalDictionary* labels;
@property (nonatomic,strong) NSMutableSet* breakPoints;
@end

@implementation PAModel

#pragma mark Utility
-(instancetype)init{
    self=[super init];
    [self initialize];
    return self;
}

-(void)initialize{
    _labels=[[PABidirectionalDictionary alloc]init];
    _breakPoints=[[NSMutableSet alloc]init];
    self.defaultQueue = [[NSOperationQueue alloc]init];
    _registers = malloc(8*sizeof(Word));
    _memory = malloc(USHRT_MAX*sizeof(Word));
    [self clearModel];
}

-(void)dealloc{
    free(_memory);
    free(_registers);
}

-(void)clearModel{
    if (self.delegate) {
        [self.delegate modelDidBecomeBusy];
    }
    for (int i=0; i<65536; i++) {
        _memory[i]=0;
    }
    [self initializeRegisters];
    [self initMemory];
    [self.labels reset];
    [self initializeBreakPoint];
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"AutoloadOS"] boolValue]) {
        PAFileDocument* os = [[PAFileDocument alloc] initWithFileURL:[PAUtility OSURL]];
        [os openWithCompletionHandler:^(BOOL success) {
            NSData* osData = os.file;
            PAError* error = nil;
            PAFileModel* fm = [PAFileModel fileModelWithContent:[[NSString alloc] initWithData:osData encoding:NSUTF8StringEncoding] Error:&error];
            if (!fm) {
                if (self.delegate) {
                    [self.delegate didFailLoadingFileWithError:error];
                    [self.delegate modelDidBecomeRelaxed];
                }
            }
            [self loadFile:fm showAlert:false];
            [os closeWithCompletionHandler:^(BOOL success) {
            }];
        }];
    }
    if (self.delegate) {
        [self.delegate modelDidBecomeRelaxed];
        [self.delegate modelDidClear];
    }
}
-(void)initializeRegisters{
    self.PC=0;
    self.CC=2;//z
    self.MPR=0;
    self.PSR=0;
    for (int i=0; i<8; i++) {
        _registers[i]=0;
    }
}
#pragma mark Model Execution
-(void)continueExecutionUsingMode:(PAExecuteMode)mode{
    if (_currentOperation==nil||[_currentOperation isFinished]) {
        _currentOperation = [[PAMdlDcdExctnOperation alloc]initWithModel:self Mode:mode];
        [self.defaultQueue addOperation:_currentOperation];
        if (self.delegate) {
            [self.delegate modelDidBecomeBusy];
        }
    }
}
-(void)suspend{
    [self.currentOperation cancel];
}
#pragma mark Memory
-(void)initMemory{
    _memory[Display_Status_Register]=0xFFFF;
}
-(Word)memoryFromLocation:(Word)location{
    return _memory[location];
}
-(void)setMemoryAtLocation:(Word)location newValue:(Word)nv{
    if (location==Display_Data_Register) {
        if (self.delegate) {
            [self.delegate outputChar:nv];
        }
    }
    else if(location==Display_Status_Register){
        NSLog(@"attempt to change the content of display status register");
        return;
    }
    else if(location==Keyboard_Status_Register){
        NSLog(@"attempt to change the content of keyboard status register");
        return;
    }
    else if(location==Keyboard_Data_Register){
        NSLog(@"attempt to change the content of keyboard data register");
        return;
    }
    _memory[location]=nv;
}
#pragma mark Labels
-(NSString*)labelAtLocation:(Word)location{
    return [self.labels stringForWord:location];
}
//-(NSNumber*)locationOfLabel:(NSString*)label{
//    return [self.labels wordForString:label];
//}
#pragma mark Files
-(BOOL)loadFile:(PAFileModel*)fileModel showAlert:(BOOL)alert{
    if (fileModel==nil) {
        return false;
    }
    if (self.delegate) {
        [self.delegate modelDidBecomeBusy];
    }
    
    [self.labels mergeWith:fileModel.symbolTable];
    Word currentAddress = fileModel.startPosition;
    for (int i=0; i<fileModel.machineCodes.count; i++,currentAddress++) {
        _memory[currentAddress]=[fileModel.machineCodes[i] unsignedShortValue];
    }
    
    if (self.delegate) {
        [self.delegate didFinishLoadingFileModel:fileModel showAlert:alert];
        [self.delegate modelDidBecomeRelaxed];
    }
    return true;
    
}
#pragma mark Breakpoints
-(BOOL)isAtBreakPoint{
    return [[self breakPoints] containsObject:@(self.PC)];
}
-(void)addBreakPoint:(Word)address{
    if (![self.breakPoints containsObject:@(address)]) {
        [self.breakPoints addObject:@(address)];
    }
}
-(void)removeBreakPoint:(Word)address{
    [self.breakPoints removeObject:@(address)];
}
-(BOOL)isAtBreakPoint:(Word)address{
    return [self.breakPoints containsObject:@(address)];
}
-(void)initializeBreakPoint{
    [self.breakPoints removeAllObjects];
    [self.breakPoints addObject:@512];
}
#pragma mark IO

-(void)keyboardDidEnterCharacter:(char)character{
    _memory[Keyboard_Data_Register]=(Word)character;
    [self setKeyboardStatus:true];
}
-(void)setKeyboardStatus:(BOOL)ready{
    if (ready) {
        _memory[Keyboard_Status_Register]=0xffff;
    }
    else{
        _memory[Keyboard_Status_Register]=0x0000;
    }
}

#pragma mark Interpret content of memory
/*
 Returns a interpretation for memory content of the given index path.
 This will try to interpret the memory even if it is not 
 supposed to be an instruction. In other words, it returns the effect of 
 the memory content if it were executed.
 */
-(NSString*)interpretationForIndexPath:(NSIndexPath*) p{
    Word address = [PAUtility locationFromIndexPath:p];
    Word mry = [self memoryFromLocation:address];
    NSString *interpretation;
    Word labelAddress;
    NSString* tempLabel;
    switch (mry&INSTRUCTION_MASK) {
        case ADD_INS:
            //immediate 5
            if (mry&_5_MASK) {
                interpretation=[NSString stringWithFormat:@"ADD, R%d, R%d, %d",(mry&_9_11_MASK)>>_9_11_SHFTBIT,(mry&_6_8_MASK)>>_6_8_SHFTBIT,[PAUtility sext_5:mry&_0_4_MASK]];
            }
            //offset
            else{
                interpretation=[NSString stringWithFormat:@"ADD, R%d, R%d, R%d",(mry&_9_11_MASK)>>_9_11_SHFTBIT,(mry&_6_8_MASK)>>_6_8_SHFTBIT,(mry&_0_2_MASK)];
            }
            break;
        case AND_INS:
            //immediate 5
            if (mry&_5_MASK) {
                interpretation=[NSString stringWithFormat:@"AND, R%d, R%d, %d",(mry&_9_11_MASK)>>_9_11_SHFTBIT,(mry&_6_8_MASK)>>_6_8_SHFTBIT,[PAUtility sext_5:mry&_0_4_MASK]];
            }
            //offset
            else{
                interpretation=[NSString stringWithFormat:@"AND, R%d, R%d, R%d",(mry&_9_11_MASK)>>_9_11_SHFTBIT,(mry&_6_8_MASK)>>_6_8_SHFTBIT,(mry&_0_2_MASK)];
            }
            break;
        case BR_INS:
            interpretation=@"BR";
            if (mry&_11_MASK) {
                interpretation=[interpretation stringByAppendingString:@"n"];
            }
            if (mry&_10_MASK) {
                interpretation=[interpretation stringByAppendingString:@"z"];
            }
            if (mry&_9_MASK) {
                interpretation=[interpretation stringByAppendingString:@"p"];
            }
            interpretation=[interpretation stringByAppendingString:@", "];
            labelAddress=address+1+[PAUtility sext_9:(mry&_0_8_MASK)];

            tempLabel=[self.labels stringForWord:labelAddress];
            if (tempLabel!=nil) {
                 interpretation=[interpretation stringByAppendingString:tempLabel];
            }
            else{
                interpretation=[interpretation stringByAppendingFormat:@"%X",labelAddress];
            }
            break;
        case JMP_INS:
            interpretation = [NSString stringWithFormat:@"JMP, R%d",(mry&_6_8_MASK)>>_6_8_SHFTBIT];
            break;
        case JSR_INS:
            //JSR
            if (mry&_11_MASK) {
                labelAddress=address+1+[PAUtility sext_11:(mry&_0_10_MASK)];
                tempLabel=[self.labels stringForWord:labelAddress];
                if (tempLabel!=nil) {
                    interpretation = [NSString stringWithFormat:@"JSR, %@",tempLabel];
                }
                else{
                    interpretation = [NSString stringWithFormat:@"JSR, %X",labelAddress];
                }
            }
            //JSRR
            else{
                interpretation=[NSString stringWithFormat:@"JSRR, R%d",(mry&_6_8_MASK)>>_6_8_SHFTBIT];
            }
            break;
        case LD_INS:
            labelAddress=address+1+[PAUtility sext_9:(mry&_0_8_MASK)];
            tempLabel=[self.labels stringForWord:labelAddress];
            if (tempLabel!=nil) {
                interpretation=[NSString stringWithFormat:@"LD, R%d, %@",(mry&_9_11_MASK)>>_9_11_SHFTBIT,tempLabel];
            }
            else{
                interpretation=[NSString stringWithFormat:@"LD, R%d, %X",(mry&_9_11_MASK)>>_9_11_SHFTBIT,labelAddress];
            }
            break;
        case LDI_INS:
            labelAddress=address+1+[PAUtility sext_9:(mry&_0_8_MASK)];
            tempLabel=[self.labels stringForWord:labelAddress];
            if (tempLabel!=nil) {
                interpretation=[NSString stringWithFormat:@"LDI, R%d, %@",(mry&_9_11_MASK)>>_9_11_SHFTBIT,tempLabel];
            }
            else{
                interpretation=[NSString stringWithFormat:@"LDI, R%d, %X",(mry&_9_11_MASK)>>_9_11_SHFTBIT,labelAddress];
            }
            break;
        case LDR_INS:
            interpretation=[NSString stringWithFormat:@"LDR, R%d, R%d, %d",(mry&_9_11_MASK)>>_9_11_SHFTBIT,(mry&_6_8_MASK)>>_6_8_SHFTBIT,mry&_0_5_MASK];
            break;
        case LEA_INS:
            labelAddress=address+1+[PAUtility sext_9:(mry&_0_8_MASK)];
            tempLabel=[self.labels stringForWord:labelAddress];
            if (tempLabel!=nil) {
                interpretation=[NSString stringWithFormat:@"LEA, R%d, %@",(mry&_9_11_MASK)>>_9_11_SHFTBIT,tempLabel];
            }
            else{
                interpretation=[NSString stringWithFormat:@"LEA, R%d, %X",(mry&_9_11_MASK)>>_9_11_SHFTBIT,labelAddress];
            }
            break;
        case NOT_INS:
            interpretation=[NSString stringWithFormat:@"NOT, R%d, R%d",(mry&_9_11_MASK)>>_9_11_SHFTBIT,(mry&_6_8_MASK)>>_6_8_SHFTBIT];
            break;
        case RTI_INS:
            interpretation=@"RTI (unsupported)";
            break;
        case ST_INS:
            labelAddress=address+1+[PAUtility sext_9:(mry&_0_8_MASK)];
            tempLabel=[self.labels stringForWord:labelAddress];
            if (tempLabel!=nil) {
                interpretation=[NSString stringWithFormat:@"ST, R%d, %@",(mry&_9_11_MASK)>>_9_11_SHFTBIT,tempLabel];
            }
            else{
                interpretation=[NSString stringWithFormat:@"ST, R%d, %X",(mry&_9_11_MASK)>>_9_11_SHFTBIT,labelAddress];
            }
            break;
        case STI_INS:
            labelAddress=address+1+[PAUtility sext_9:(mry&_0_8_MASK)];
            tempLabel=[self.labels stringForWord:labelAddress];
            if (tempLabel!=nil) {
                interpretation=[NSString stringWithFormat:@"STI, R%d, %@",(mry&_9_11_MASK)>>_9_11_SHFTBIT,tempLabel];
            }
            else{
                interpretation=[NSString stringWithFormat:@"STI, R%d, %X",(mry&_9_11_MASK)>>_9_11_SHFTBIT,labelAddress];
            }
            break;
        case STR_INS:
            interpretation=[NSString stringWithFormat:@"STR, R%d, R%d, %d",(mry&_9_11_MASK)>>_9_11_SHFTBIT,(mry&_6_8_MASK)>>_6_8_SHFTBIT,mry&_0_5_MASK];
            break;
        case TRAP_INS:
            interpretation=[NSString stringWithFormat:@"TRAP, x%X",mry&_0_7_MASK];
            break;
        default:
            break;
    }
    
    return interpretation;
}

#pragma mark PAMdlDcdExctnOperationDelegate
-(void) operationDidFinish{
    if (self.delegate) {
        [self.delegate didFinishExecutionWithPC:self.PC];
        [self.delegate modelDidBecomeRelaxed];
    }
    else{
        NSLog(@"PAModel has no delegate");
    }
}

#pragma mark UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [PAUtility memorySectionLengths][section];
}
//-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//    return [[PAUtility memorySectionTitles] objectAtIndex:section];
//}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [[PAUtility memorySectionTitles] count];
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    PAMemoryLocationCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    Word ml=[PAUtility locationFromIndexPath:indexPath];
    [cell configureWithAddress:ml Label:[self.labels stringForWord:ml] Content:_memory[ml] Interpretation:[self interpretationForIndexPath:indexPath]];
    if ([[self breakPoints] containsObject:@([PAUtility locationFromIndexPath:indexPath])]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else{
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    return cell;
}

#pragma mark UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 12;
}
-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    PARegistersDisplayCell* cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    Word word;
    switch (indexPath.item) {
        case PC_Collection_Index:
            word=self.PC;
            break;
        case CC_Collection_Index:
            word=self.CC;
            break;
        case MPR_Collection_Index:
            word=self.MPR;
            break;
        case PSR_Collection_Index:
            word=self.PSR;
            break;
        default:
            word=self.registers[indexPath.item];
            break;
    }
    [cell configureWithTitle:indexPath.item Value:word];
    return cell;
}


@end