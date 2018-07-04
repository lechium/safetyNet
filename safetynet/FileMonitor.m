#import <fcntl.h>
#import <unistd.h>
#import <sys/event.h>

#import "FileMonitor.h"
//#import "LogMacros.h"


@interface FileMonitor ()

@property (nonatomic, assign, readonly) CFFileDescriptorRef _fileDes;
@property (nonatomic, retain) NSArray* fns;

@end

@implementation FileMonitor

static int                  _dirFD;
static CFFileDescriptorRef  _fileDes;
static id<FileMonitorDelegate> _delegate;
static NSString *_watchedDir;

static void KQCallback(CFFileDescriptorRef kqRef, CFOptionFlags callBackTypes, void *info){
    

    if(_delegate){
        [_delegate dirChanged:_watchedDir];
    }
    
    // Pull the native FD around which the CFFileDescriptor was wrapped
    int kq = CFFileDescriptorGetNativeDescriptor(_fileDes);
    if (kq < 0){
        return;
    }
    
    // If we pull a single available event out of the queue, assume the directory was updated
    struct kevent event;
    struct timespec timeout = {0, 0};
    if (kevent(kq, NULL, 0, &event, 1, &timeout) == 1){
        if( _delegate ){
            [_delegate dirChanged:_watchedDir];
        }else{
            NSLog(@"Callback with NO delegate set");
        }
    }
    
    // issue callback request
    CFFileDescriptorEnableCallBacks(_fileDes, kCFFileDescriptorReadCallBack);
}

#pragma mark -
#pragma mark View lifecycle


- (void) monitorDir:(NSString*) aDir delegate:(id<FileMonitorDelegate>) aDelegate{
    //ASSERT(aDir);
    //ASSERT(aDelegate);
    _watchedDir = aDir;
    _delegate = aDelegate;
    
    NSError *error;
    
    self.fns = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:aDir error:&error];
    if (error){
        NSLog(@"%@", error);
    }
    //LOG_IF_NSERROR(error);
    [self startMonitor];
}

- (void)startMonitor {
    // One ping only
    if (_fileDes != NULL){
        NSLog(@"kernel queue was null");
        return;
    }
    
    // Open an event-only file descriptor associated with the directory
    int dirFD = open([ _watchedDir fileSystemRepresentation], O_EVTONLY);
    if (dirFD < 0) {
        NSLog(@"could not open file descriptor");
        return;
    }
    
    // Create a new kernel event queue
    int kq = kqueue();
    if (kq < 0){
        NSLog(@"could not open kernel queue");
        close(dirFD);
        return;
    }
    
    // Set up a kevent to monitor
    struct kevent eventToAdd;                   // Register an (ident, filter) pair with the kqueue
    eventToAdd.ident  = dirFD;                  // The object to watch (the directory FD)
    eventToAdd.filter = EVFILT_VNODE;           // Watch for certain events on the VNODE spec'd by ident
    eventToAdd.flags  = EV_ADD | EV_CLEAR;      // Add a resetting kevent
    eventToAdd.fflags = NOTE_WRITE;             // The events to watch for on the VNODE spec'd by ident (writes)
    eventToAdd.data   = 0;                      // No filter-specific data
    eventToAdd.udata  = NULL;                   // No user data
    
    // Add a kevent to monitor
    if (kevent(kq, &eventToAdd, 1, NULL, 0, NULL)){
        close(kq);
        close(dirFD);
        return;
    }
    
    // Wrap a CFFileDescriptor around a native FD
    CFFileDescriptorContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    _fileDes = CFFileDescriptorCreate(NULL,     // Use the default allocator
                                      kq,         // Wrap the kqueue
                                      true,       // Close the CFFileDescriptor if kq is invalidated
                                      KQCallback, // Fxn to call on activity
                                      &context);  // Supply a context to set the callback's "info" argument
    if (_fileDes == NULL){
        close(kq);
        close(dirFD);
        return;
    }
    
    // Spin out a pluggable run loop source from the CFFileDescriptorRef
    // Add it to the current run loop, then release it
    CFRunLoopSourceRef rls = CFFileDescriptorCreateRunLoopSource(NULL, _fileDes, 0);
    if (rls == NULL){
        CFRelease(_fileDes); _fileDes = NULL;
        close(kq);
        close(dirFD);
        return;
    }
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    CFRelease(rls);
    
    // Store the directory FD for later closing
    _dirFD = dirFD;
    
    // issue callback request
    CFFileDescriptorEnableCallBacks(_fileDes, kCFFileDescriptorReadCallBack);
}

- (void)stopMonitor{
    if (_fileDes)
    {
        close(_dirFD);
        CFFileDescriptorInvalidate(_fileDes);
        CFRelease(_fileDes);
        _fileDes = NULL;
    }
}

- (void)restartMonitor{
    [self stopMonitor];
    [self startMonitor];
}

- (void)dealloc{
    [self stopMonitor];
}

@end
