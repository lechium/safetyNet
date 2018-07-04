//
//  KBSafetyNet.h
//  safetynet
//
//  Created by Kevin Bradley on 7/4/18.
//  Copyright © 2018 nito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import "FileMonitor.h"

@interface KBSafetyNet : NSObject <FileMonitorDelegate>

- (void)startListening;
- (void)stopListening;

@end
