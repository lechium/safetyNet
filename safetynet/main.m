//
//  main.m
//  safetynet
//
//  Created by Kevin Bradley on 7/4/18.
//  Copyright © 2018 nito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KBSafetyNet.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        
        KBSafetyNet *sn = [KBSafetyNet new];
        [sn startListening];
        
        CFRunLoopRun();
    }
    return 0;
}
