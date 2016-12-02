//
//  PAFileModelTest.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 1/28/16.
//  Copyright © 2016 G. Yan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PAFileModel.h"
#import "PAError.h"

@interface PAFileModelTest : XCTestCase

@end

@implementation PAFileModelTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//literal at this point cannot be empty
- (void)testNumberFromLiteral {
    int num;
    BOOL result;
    
    //garbage value
    result = [PAFileModel numberFromLiteral:@"garbage " :&num];
    XCTAssertFalse(result);
    
    //decimal
    result = [PAFileModel numberFromLiteral:@"#32" :&num];
    XCTAssert(result);
    XCTAssertEqual(num, 32);
    
    //decimal fail
    result = [PAFileModel numberFromLiteral:@"#32A" :&num];
    XCTAssertFalse(result);
    
    //decimal
    result = [PAFileModel numberFromLiteral:@"789" :&num];
    XCTAssert(result);
    XCTAssertEqual(num, 789);
    
    //decimal fail
    result = [PAFileModel numberFromLiteral:@"789r" :&num];
    XCTAssertFalse(result);
    
    //hex
    result = [PAFileModel numberFromLiteral:@"xdead" :&num];
    XCTAssert(result);
    XCTAssertEqual(num, 0xdead);
    
    //hex capital & mix
    result = [PAFileModel numberFromLiteral:@"XdeAd" :&num];
    XCTAssert(result);
    XCTAssertEqual(num, 0xdead);
    
    //hex capital & mix
    result = [PAFileModel numberFromLiteral:@"0XdeAa" :&num];
    XCTAssert(result);
    XCTAssertEqual(num, 0xdeaa);
    
    //hex capital & mix
    result = [PAFileModel numberFromLiteral:@"0xdeAa" :&num];
    XCTAssert(result);
    XCTAssertEqual(num, 0xdeaa);
    
    //hex fail
    result = [PAFileModel numberFromLiteral:@"0xdafg" :&num];
    XCTAssertFalse(result);
}

-(void)testRegisterNum{
    Word num;
    BOOL result;
    
    result = [PAFileModel registerNum:@"A8" :&num];
    XCTAssertFalse(result);

    result = [PAFileModel registerNum:@"R-" :&num];
    XCTAssertFalse(result);
    
    result = [PAFileModel registerNum:@"R0" :&num];
    XCTAssertTrue(result);
    XCTAssertEqual(num, 0);

    result = [PAFileModel registerNum:@"R7" :&num];
    XCTAssertTrue(result);
    XCTAssertEqual(num, 7);
}

-(void)testCheckRange{
    PAError* error;
    
    //len 5, fail
    error = [PAFileModel checkRangeOfNumber:(1<<4) withLength:PANumberLength5];
    XCTAssertNotNil(error);
    error = [PAFileModel checkRangeOfNumber:(-(1<<4)-1) withLength:PANumberLength5];
    XCTAssertNotNil(error);
    
    //len 5, success
    error = [PAFileModel checkRangeOfNumber:((1<<4)-1) withLength:PANumberLength5];
    XCTAssertNil(error);
    error = [PAFileModel checkRangeOfNumber:(-(1<<4)) withLength:PANumberLength5];
    XCTAssertNil(error);
    
    //len 16, fail
    error = [PAFileModel checkRangeOfNumber:(1<<15) withLength:PANumberLength16];
    XCTAssertNotNil(error);
    error = [PAFileModel checkRangeOfNumber:(-(1<<15)-1) withLength:PANumberLength16];
    XCTAssertNotNil(error);
    
    //len 16, success
    error = [PAFileModel checkRangeOfNumber:((1<<15)-1) withLength:PANumberLength16];
    XCTAssertNil(error);
    error = [PAFileModel checkRangeOfNumber:(-(1<<15)) withLength:PANumberLength16];
    XCTAssertNil(error);
}

-(void)testCheckStringLiteral{
    //success
    XCTAssertEqualObjects([PAFileModel checkStringLiteral:@"\"a\\n\\\"\\\\ \\t\""], @"a\n\"\\ \t");
    //unmatched
    XCTAssertNil([PAFileModel checkStringLiteral:@"\"\\\\kj"]);
}

-(void)testComponentFromType{
    PAError* error;
    NSArray* res;
    
    //param length mismatch
    XCTAssertNil([PAFileModel component:(@[@"a",@"b"]) fromType:@"BAD" numberLength:0 Error:NULL]);
    
    //success
    res = [PAFileModel component:@[@"ADD", @"R2", @"#4", @"\"asd\"", @"lab"] fromType:@"RNSL" numberLength:PANumberLength5 Error:&error];
    NSLog(@"!!!%@",error);
    XCTAssertEqualObjects(res, (@[@2, @4, @"asd", @"lab"]));
    
    //register failure
    error = nil;
    res = [PAFileModel component:@[@"ADD", @"R9"] fromType:@"R" numberLength:PANumberLength5 Error:&error];
    XCTAssertNil(res);
    XCTAssertNotNil(error);
    
    //not a num
    error = nil;
    res = [PAFileModel component:@[@"ADD", @"kjlsdb"] fromType:@"N" numberLength:PANumberLength5 Error:&error];
    XCTAssertNil(res);
    XCTAssertNotNil(error);
    
    //num out of range
    error = nil;
    res = [PAFileModel component:@[@"ADD", @"k#16"] fromType:@"N" numberLength:PANumberLength5 Error:&error];
    XCTAssertNil(res);
    XCTAssertNotNil(error);
    
    //invalid string
    error = nil;
    res = [PAFileModel component:@[@"ADD", @"\"\\\""] fromType:@"S" numberLength:PANumberLength5 Error:&error];
    XCTAssertNil(res);
    XCTAssertNotNil(error);
}


@end
