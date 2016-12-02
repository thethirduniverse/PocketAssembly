//
//  GYFileEntry.m
//  boringtest
//
//  Created by Guanqing Yan on 12/28/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PAFileEntry.h"

@implementation PAFileEntry
- (id)initWithFileURL:(NSURL *)fileURL metadata:(PAFileSnapshot *)snapshot state:(UIDocumentState)state version:(NSFileVersion *)version {
    
    if ((self = [super init])) {
        self.fileURL = fileURL;
        self.snapshot = snapshot;
        self.state = state;
        self.version = version;
    }
    return self;
    
}

- (NSString *) description {
    return [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
}
@end
