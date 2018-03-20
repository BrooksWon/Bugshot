//
//  BSKBackgroundTimer.h
//
//  Created by Michael Ash on 6/23/10.
//

#import <dispatch/dispatch.h>
#import <Foundation/Foundation.h>

typedef enum {
    BSKBackgroundTimerCoalesce, // subsequent calls with charged timer can only reduce the time until firing, not extend; default value
    BSKBackgroundTimerDelay // subsequent calls replace the existing time, potentially extending it
} BSKBackgroundTimerBehavior;

@interface BSKBackgroundTimer : NSObject {
    __unsafe_unretained id _obj;
    dispatch_queue_t _queue;
    dispatch_source_t _timer;
    BSKBackgroundTimerBehavior _behavior;
    NSTimeInterval _nextFireTime;
}

@property (assign) id obj;
@property (strong, readonly) dispatch_queue_t queue;

- (id)initWithObject:(id)obj behavior:(BSKBackgroundTimerBehavior)behavior queueLabel:(char const *)queueLabel;
- (void)setTargetQueue:(dispatch_queue_t)target;
- (void)afterDelay:(NSTimeInterval)delay do:(void (^)(id self))block;
- (void)performWhileLocked:(void (^)(void))block;
- (void)cancel;

@end
