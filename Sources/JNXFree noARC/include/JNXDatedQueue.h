/* DatedQueue.h created by jolly on Sat Fri 01-Mar-1996 */

@import Foundation;

@class JNXSortedArray;

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
- (NSUInteger) count;
- (BOOL)containsObject:(id)anObject;

@end

