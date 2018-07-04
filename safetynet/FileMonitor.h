#import <Foundation/Foundation.h>


@protocol FileMonitorDelegate <NSObject>
@required
-(void) dirChanged:(NSString*) aDirName;
@end

@interface FileMonitor : NSObject

- (void) monitorDir:(NSString*) aDir delegate:(id<FileMonitorDelegate>) aDelegate;

- (void)stopMonitor;

@end
