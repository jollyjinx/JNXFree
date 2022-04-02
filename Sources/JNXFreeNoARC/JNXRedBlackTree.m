/* RedBlackTree.m created by jolly on Sat 17-Mar-2001 */

@import Foundation;

#import "JNXRedBlackTree.h"

#if REDBLACKTREE_MULTITHREADED
#define RB_LOCK_ALLOCINIT	rbTreeLock	= [[NSLock alloc] init];
#define RB_LOCK_RELEASE		[rbTreeLock release];
#define RB_LOCK_LOCK		[rbTreeLock lock];
#define RB_LOCK_UNLOCK		[rbTreeLock unlock];
#else
#define RB_LOCK_ALLOCINIT
#define RB_LOCK_RELEASE	
#define RB_LOCK_LOCK	
#define RB_LOCK_UNLOCK	
#endif


static  NSComparisonResult compareviamethod(id objectA,id objectB,SEL aselector)
{
    //NSLog(@"comparing");
    //NSLog(@"%@ %@",objectA,objectB);
    return (NSComparisonResult)[objectA performSelector:aselector withObject:objectB];
}

static void releaseobjectmethod(id objectA)
{
    [objectA release];
}


@implementation JNXRedBlackTree

+ redBlackTree
{
    return [[[self alloc] init] autorelease];
}

- init
{
    return [self initWithCompareSelector:@selector(compare:)];
}

- initWithCompareFunction:(NSComparisonResult (*)(id, id, void *))acomparefunction context:(void *)acontext;
{
    if( !(self=[super init]) )
	{
		return nil;
	}
    RB_LOCK_ALLOCINIT

    comparefunction	= acomparefunction;
    comparecontext	= acontext;

    rbtree = bprb_create((bprb_comparison_func *)acomparefunction,acontext,NULL);
    
    return self;
}

- initWithCompareSelector:(SEL)aselector;
{
    return [self initWithCompareFunction:(NSComparisonResult (*)(id, id, void *))compareviamethod context:(void *)aselector];
}


- (void)dealloc
{
	RB_LOCK_RELEASE

    bprb_destroy(rbtree,(bprb_item_func *)releaseobjectmethod);

    [super dealloc];
}

- (struct bprb_table*)_rbtree
{
	return rbtree;
}

- (void)addObject:(id)anObject;
{
    RB_LOCK_LOCK

    if( NULL == bprb_insert(rbtree,anObject) )
    {
        [anObject retain];
    }
    RB_LOCK_UNLOCK
}

- (void)addObjectsFromArray:(NSArray *)anArray;
{
	NSUInteger count = [anArray count];
	
    RB_LOCK_LOCK
	for(NSUInteger i=0; i<count; i++)
	{
		id anObject = [anArray objectAtIndex:i];
		
		if( NULL == bprb_insert(rbtree,anObject) )
		{
			[anObject retain];
		}
	}
    RB_LOCK_UNLOCK
}


- (void)removeObject:(id)anObject;
{
    RB_LOCK_LOCK
    if( bprb_delete(rbtree,anObject) )
    {
        [anObject release];
    }
    RB_LOCK_UNLOCK
}

- (BOOL)containsObject:(id)anObject;
{
    BOOL	containsobject;
    RB_LOCK_LOCK
    containsobject=bprb_find(rbtree,anObject)?YES:NO;
    RB_LOCK_UNLOCK
    return containsobject;
}

- (id)firstObject;
{
    id	firstObject;
    struct bprb_traverser	traverser;
  
    RB_LOCK_LOCK
    firstObject =  (id)bprb_t_first(&traverser,rbtree);
    RB_LOCK_UNLOCK
    return firstObject;
}

- (id)removeFirstObject;
{
    id	firstObject;
    struct bprb_traverser	traverser;
  
    RB_LOCK_LOCK
    if( (firstObject = (id)bprb_t_first(&traverser,rbtree)) )
    {
        bprb_delete(rbtree,(void*)firstObject);
    }
    RB_LOCK_UNLOCK
    return [firstObject autorelease];   
}


- (NSUInteger)count;
{
    NSUInteger count;
    RB_LOCK_LOCK
    count=(NSUInteger)bprb_count(rbtree);
    RB_LOCK_UNLOCK
    return count;
}

- (NSEnumerator *)objectEnumerator;
{
    return [[[JNXRedBlackTreeEnumerator alloc] initWithRedBlackTree:rbtree] autorelease];
}
//- (NSEnumerator *)objectEnumeratorStartingBefore:(id)anObject;
//{
//    return [[[JNXRedBlackTreeEnumerator alloc] initWithRedBlackTree:rbtree startingBefore:anObject] autorelease];
//}

- (NSString *)description
{
	NSEnumerator *enumerator = [self objectEnumerator];
	
	NSMutableString	*outputString = [NSMutableString stringWithFormat:@"RedBlackTree contains:%ld\n(\n",[self count]];
	id anObject;
	
	while( anObject = [enumerator nextObject] )
	{
		[outputString appendFormat:@"\t%@\n",anObject];
	}
	[outputString appendString:@")\n"];
	
	return outputString;
}

@end

@implementation JNXRedBlackTreeEnumerator

- initWithRedBlackTree:(struct bprb_table *)arbtree;
{
    self = [super init];
    bprb_t_init(&traverser,arbtree);
    return self;
}

//- initWithRedBlackTree:(struct bprb_table *)arbtree startingBefore:(id)anObject;
//{
//    self = [super init];
//    bprb_t_find_startsbefore(&traverser,arbtree,anObject);
//    return self;
//}

- previousObject;
{
	return (id)bprb_t_prev(&traverser);
}
- nextObject;
{
    return (id)bprb_t_next(&traverser);
}

@end

