/* AdvancedDatedQueue.h created by jolly on Fri 01-Mar-1996 */

@import Foundation;
#import "JNXRedBlackTree.h"

@interface JNXAdvancedDatedQueue : NSObject
{
    NSConditionLock		*queueLock;
    NSLock				*singlePopLock;
    JNXRedBlackTree 	*queueRedBlackTree;
    NSMutableDictionary	*queueDictionary;
}
- pop;
- popBeforeDate:(NSDate *)endDate;
- (void) push:(id)anObject withDate:(NSDate *)date;
- (BOOL)containsObject:(id)anObject;
- (void)removeObjectIdenticalTo:(id)anObject;
- (void)removeAllObjects;

- (unsigned int) count;

@end

