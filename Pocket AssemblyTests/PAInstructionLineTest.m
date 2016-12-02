//
//  PAInstructionLineTest.m
//  Pocket Assembly
//
//  Created by Guanqing Yan on 1/28/16.
//  Copyright © 2016 G. Yan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PAInstructionLine.h"

@interface PAInstructionLineTest : XCTestCase

@end

@implementation PAInstructionLineTest

- (void)testFieldAccessible {
    PAInstructionLine* l = [[PAInstructionLine alloc] init];
    NSObject* testObj = [[NSObject alloc] init];
    NSString* testStr = @"str";
    Word testWrd = 0xdead;
    [l setInsturctionType:PAEndDirective];
    [l setArgument:testObj];
    [l setInstructionlabel:testStr];
    [l setInstrution:testWrd];
    XCTAssertEqualObjects(l.argument, testObj);
    XCTAssertEqualObjects(l.instructionlabel, testStr);
    XCTAssertEqual(l.instrution, 0xdead);
    XCTAssertEqual(l.insturctionType, PAEndDirective);
}


@end
