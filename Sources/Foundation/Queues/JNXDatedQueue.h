/* DatedQueue.h created by jolly on Sat Fri 01-Mar-1996 */

#import <Foundation/Foundation.h>
#import <JNXFree/JNXFree.h>

@class JNXSortedArray

@interface JNXDatedQueue : NSObject
{
    NSConditionLock	*queueLock;
    NSLock			*singlePopLock;
    JNXSortedArray 	*queueArray;
}
- pop;
- popBeforeDate:(NSDate *)endDate;
- (void) push:(id)anObject;
- (void) push:(id)anObject withDate:(NSDate *)date;
- (unsigned int) count;
- (BOOL)containsObject:(id)anObject;

@end

