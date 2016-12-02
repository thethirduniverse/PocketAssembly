//
//  GYFileDocument.m
//  boringtest
//
//  Created by Guanqing Yan on 12/26/14.
//  Copyright (c) 2014 G. Yan. All rights reserved.
//

#import "PAFileDocument.h"
#import "PAFileSnapshot.h"

@interface PAFileDocument()
@property (strong,nonatomic) NSData* file;
@property (strong,nonatomic) NSFileWrapper* wrapper;
@end

@implementation PAFileDocument
@synthesize file = _file;

-(id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError{
    if (self.file==nil||self.snapshot==nil) {
        return nil;
    }
    NSMutableDictionary* wrappers = [NSMutableDictionary dictionary];
    [self encodeObject:self.snapshot toWrappers:wrappers preferredFilename:kSnapshotKey];
    NSFileWrapper* contentWrapper=[[NSFileWrapper alloc] initRegularFileWithContents:self.file];
    [wrappers setObject:contentWrapper forKey:kContentKey];
    return [[NSFileWrapper alloc] initDirectoryWithFileWrappers:wrappers];
}

- (void)encodeObject:(id<NSCoding>)object toWrappers:(NSMutableDictionary *)wrappers preferredFilename:(NSString *)preferredFilename {
    @autoreleasepool {
        NSMutableData * data = [NSMutableData data];
        NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:object forKey:@"data"];
        [archiver finishEncoding];
        NSFileWrapper * wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
        [wrappers setObject:wrapper forKey:preferredFilename];
    }
}

- (id)decodeObjectFromWrapperWithPreferredFilename:(NSString *)preferredFilename {
    
    NSFileWrapper * fileWrapper = [self.wrapper.fileWrappers objectForKey:preferredFilename];
    if (!fileWrapper) {
        NSLog(@"Unexpected error: Couldn't find %@ in file wrapper!", preferredFilename);
        return nil;
    }
    
    NSData * data = [fileWrapper regularFileContents];
    NSKeyedUnarchiver * unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    //PAfilesnapshot used to be called GYFileSnapshot
    [unarchiver setClass:[PAFileSnapshot class] forClassName:@"GYFileSnapshot"];
    id object = [unarchiver decodeObjectForKey:@"data"];
    return object;
    
}


-(PAFileSnapshot*)snapshot{
    if (!_snapshot) {
        if (self.wrapper!=nil) {
            self.snapshot=[self decodeObjectFromWrapperWithPreferredFilename:kSnapshotKey];
        }else{
            self.snapshot=[[PAFileSnapshot alloc] init];
        }
    }
    return _snapshot;
}

-(NSData*)file{
    if(!_file){
        if (self.wrapper!=nil) {
            NSFileWrapper* wrapper=[self.wrapper.fileWrappers objectForKey:kContentKey];
            _file=[wrapper regularFileContents];
        }else{
            _file=[[NSMutableData alloc]init];
        }
    }
    return _file;
}

-(void)setFile:(NSData *)file{
    if ([_file isEqualToData:file]) {
        return;
    }
    _file=file;
}

-(BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError{
    self.wrapper=(NSFileWrapper*)contents;
    self.file=nil;
    self.snapshot=nil;
    return YES;
}

-(NSString*)description{
    return [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
}

@end
