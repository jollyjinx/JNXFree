
#import <Cocoa/Cocoa.h>
#include <pthread.h>

#define MTQUEUE_END_OBJECT	@"MTQueueEndObjectString"

@interface MTQueue : NSObject
{
    NSMutableArray		*queueArray;
	uint32_t			arraycounter;

	pthread_mutex_t		queuelock;
	pthread_cond_t		queuecondition;
}
- init;
- pop;
- popBeforeDate:(NSDate *)endDate;
- popDoNotBlock;
- (void) push:(id)anObject;
- (unsigned int) count;

@end
