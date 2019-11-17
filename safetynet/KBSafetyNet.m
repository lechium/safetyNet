//
//  KBSafetyNet.m
//  safetynet
//
//  Created by Kevin Bradley on 7/4/18.
//  Copyright © 2018 nito. All rights reserved.
//

#import "KBSafetyNet.h"
#include <stdint.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <sys/utsname.h>

@interface NSDistributedNotificationCenter : NSNotificationCenter

+ (id)defaultCenter;

- (void)addObserver:(id)arg1 selector:(SEL)arg2 name:(id)arg3 object:(id)arg4;
- (void)postNotificationName:(id)arg1 object:(id)arg2 userInfo:(id)arg3;

@end

@interface KBSafetyNet()

@property (nonatomic, strong) FileMonitor *monitor;
@property (nonatomic, strong) NSString *ourDirectory;
@property (readwrite, assign) BOOL sleepDisabled;

@end

@implementation KBSafetyNet

- (void)disableSleepIfNecessary {
    
    if (self.sleepDisabled) return;
    struct utsname u;
    uname(&u);
    NSString *machine = [NSString stringWithUTF8String:u.machine];
    if ([machine isEqualToString:@"AppleTV5,3"]){
        
         NSLog(@"\nAttempting to disable sleep...\n");
        
        static IOPMAssertionID assertionID = 0;
        CFStringRef reasonForActivity= CFSTR("safetynet requested to disable system sleep");
        IOPMAssertionCreateWithName(kIOPMAssertPreventUserIdleSystemSleep,
                                    kIOPMAssertionLevelOn, reasonForActivity, &assertionID);
        self.sleepDisabled = true;
    }
    
}

+ (NSString *)singleLineReturnForProcess:(NSString *)call
{
    return [[self returnForProcess:call] componentsJoinedByString:@"\n"];
}

+ (NSArray *)returnForProcess:(NSString *)call
{
    if (call==nil)
        return 0;
    char line[200];
    NSLog(@"\nRunning process: %@\n", call);
    FILE* fp = popen([call UTF8String], "r");
    NSMutableArray *lines = [[NSMutableArray alloc]init];
    if (fp)
    {
        while (fgets(line, sizeof line, fp))
        {
            NSString *s = [NSString stringWithCString:line encoding:NSUTF8StringEncoding];
            s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [lines addObject:s];
        }
    }
    pclose(fp);
    return lines;
}

- (void)stopListening {
    
    [self.monitor stopMonitor];
    
}

- (void)startListening {
    
    self.sleepDisabled = false;
    self.monitor = [FileMonitor new];
    self.ourDirectory = @"/";
    NSLog(@"our dir: %@", self.ourDirectory);
    [self.monitor monitorDir:self.ourDirectory delegate:self];
    [self dirChanged:self.ourDirectory];
    [self disableSleepIfNecessary];
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
            
            NSString *runningTasks = [KBSafetyNet singleLineReturnForProcess:@"/bin/ps awwwx"];
            
            NSLog(@"%@", runningTasks);
            
            NSDictionary *userInfo = @{@"path": fullPath, @"ps": runningTasks};
            
            //NSLog(@"sending userInfo: %@", userInfo);
            
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.nito.safetynetfired" object:nil userInfo:userInfo];
            
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
