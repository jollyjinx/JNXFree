/* SortedArray.h created by jolly on Fri 01-Mar-1996 */

@import Foundation;

#define REDBLACKTREE_MULTITHREADED 0

@interface JNXSortedArray : NSMutableArray
{
@private
#if REDBLACKTREE_MULTITHREADED
    NSRecursiveLock	*arrayLock;
#endif
    NSMutableArray 	*embeddedArray;
    int			comparetype;
    NSComparisonResult 		(*comparefunction)(id, id, void *);
    void 		*comparecontext;
    SEL			compareselector;
}

// Due to the fact that NSArray is a Class Cluster I use the 'embedded object' way of using a subclass
+ (JNXSortedArray *)sortedArray;
- (NSMutableArray *)unsortedCopy;
- (void)adjustObjectIdenticalTo:(id)objectToAdjust;
@end
