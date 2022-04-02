/* RedBlackTree.h created by jolly on Sat 17-Mar-2001 */

@import Foundation;

#import "rb.h"

#define REDBLACKTREE_MULTITHREADED 0

@interface JNXRedBlackTree : NSObject
{
#if REDBLACKTREE_MULTITHREADED
    NSLock	*rbTreeLock;
#endif
    struct bprb_table *rbtree;
    NSComparisonResult		(*comparefunction)(id, id, void *);
    void	*comparecontext;
}
+ redBlackTree;

- initWithCompareFunction:(NSComparisonResult (*)(id, id, void *))acomparefunction context:(void *)acontext;
- initWithCompareSelector:(SEL)aselector;

- (void)addObject:(id)anObject;
- (void)addObjectsFromArray:(NSArray *)anArray;
- (void)removeObject:(id)anObject;
- (BOOL)containsObject:(id)anObject;

- (id)firstObject;
- (id)removeFirstObject;

- (NSUInteger)count;
- (NSEnumerator *)objectEnumerator;
//- (NSEnumerator *)objectEnumeratorStartingBefore:(id)anObject;

@end


@interface JNXRedBlackTreeEnumerator:NSEnumerator
{
    struct bprb_traverser	traverser;
}
- initWithRedBlackTree:(struct bprb_table *)arbtable;
//- initWithRedBlackTree:(struct bprb_table *)arbtree startingBefore:(id)anObject;

- previousObject;
- nextObject;

@end
