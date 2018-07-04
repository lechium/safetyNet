//
//  KBSafetyNet.m
//  safetynet
//
//  Created by Kevin Bradley on 7/4/18.
//  Copyright © 2018 nito. All rights reserved.
//

#import "KBSafetyNet.h"
#include <stdint.h>

@interface KBSafetyNet()

@property (nonatomic, strong) FileMonitor *monitor;
@property (nonatomic, strong) NSString *ourDirectory;

@end

@implementation KBSafetyNet

- (void)stopListening {
    
    [self.monitor stopMonitor];
    
}

- (void)startListening {
    
    self.monitor = [FileMonitor new];
    
    self.ourDirectory = @"/";
    
    NSLog(@"our dir: %@", self.ourDirectory);
    
    
    [self.monitor monitorDir:self.ourDirectory delegate:self];
    [self dirChanged:self.ourDirectory];
}

-(void) dirChanged:(NSString*) aDirName {
    
    NSArray *importantPaths = @[@"var", @"etc", @"tmp"];
    NSFileManager *man = [NSFileManager defaultManager];
    [importantPaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *fullPath = [self.ourDirectory stringByAppendingPathComponent:obj];
        NSDictionary *attributes = [man attributesOfItemAtPath:fullPath error:nil];
        NSString *fileType = attributes[NSFileType];
        if (![fileType isEqualToString:NSFileTypeSymbolicLink]){
            //NSLog(@"full path: %@ attributes: %@", fullPath, attributes);
            //NSLog(@"attrs: %@", attributes);
            NSLog(@"%@ is no longer a symbolic link! you are going to have a bad time!!!", fullPath);
            NSString *privateProper = [@"private" stringByAppendingPathComponent:obj];
            
            if ([obj isEqualToString:@"tmp"]){
                privateProper = [@"private/var" stringByAppendingPathComponent:obj];
            }
            NSLog(@"private proper: %@", privateProper);
            if ([man fileExistsAtPath:fullPath]){
                
                NSLog(@"The folder exists, we will have to move it and put the symbolic link back in place");
                NSUInteger r = arc4random_uniform(16);
                NSString *newPath = [fullPath stringByAppendingPathExtension:[NSString stringWithFormat:@"%lu", r]];
                
                NSLog(@"mv %@ %@", fullPath, newPath);
                [man moveItemAtPath:fullPath toPath:newPath error:nil];
                
                
                //
                //[man createSymbolicLinkAtPath:fullPath withDestinationPath:[@"/private" stringByAppendingPathComponent:obj] error:nil];
            }
            //[man createSymbolicLinkAtPath:fullPath withDestinationPath:[@"/private" stringByAppendingPathComponent:obj] error:nil];
            NSLog(@"ln -s %@ %@", privateProper, fullPath);
            symlink([privateProper UTF8String], [fullPath UTF8String]);
        }
    }];
}

@end
