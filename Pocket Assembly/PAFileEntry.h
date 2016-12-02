//
//  GYFileEntry.h
//  boringtest
//
//  Created by Guanqing Yan on 12/28/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PAFileSnapshot.h"

@interface PAFileEntry : NSObject
@property (strong) NSURL * fileURL;
@property (strong) PAFileSnapshot * snapshot;
@property (assign) UIDocumentState state;
@property (strong) NSFileVersion * version;

- (id)initWithFileURL:(NSURL *)fileURL metadata:(PAFileSnapshot *)snapshot state:(UIDocumentState)state version:(NSFileVersion *)version;
- (NSString *) description;
@end
