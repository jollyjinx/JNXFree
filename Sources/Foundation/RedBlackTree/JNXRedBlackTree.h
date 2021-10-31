/* RedBlackTree.h created by jolly on Sat 17-Mar-2001 */

#import <Foundation/Foundation.h>
#import "rb.h"

#define REDBLACKTREE_MULTITHREADED 0

@interface JNXRedBlackTree : NSObject
{
#if REDBLACKTREE_MULTITHREADED
    NSLock	*rbTreeLock;
#endif
    struct rb_table *rbtree;
    int		(*comparefunction)(id, id, void *);
    void	*comparecontext;
}
+ redBlackTree;

- initWithCompareFunction:(int (*)(id, id, void *))acomparefunction context:(void *)acontext;
- initWithCompareSelector:(SEL)aselector;

- (void)addObject:(id)anObject;
- (void)addObjectsFromArray:(NSArray *)anArray;
- (void)removeObject:(id)anObject;
- (BOOL)containsObject:(id)anObject;

- (id)firstObject;
- (id)removeFirstObject;

- (unsigned int)count;
- (NSEnumerator *)objectEnumerator;
- (NSEnumerator *)objectEnumeratorStartingBefore:(id)anObject;

@end


@interface JNXRedBlackTreeEnumerator:NSEnumerator
{
    struct rb_traverser	traverser;
}
- initWithRedBlackTree:(struct rb_table *)arbtable;
- initWithRedBlackTree:(struct rb_table *)arbtree startingBefore:(id)anObject;

- previousObject;
- nextObject;

@end
