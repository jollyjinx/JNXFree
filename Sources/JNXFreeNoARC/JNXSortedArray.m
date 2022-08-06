/* SortedArray.m created by jolly on Fri 01-Mar-1996 */

#import "JNXSortedArray.h"

#define COMPARE_FUNCTION 1
#define COMPARE_SELECTOR 2

#if REDBLACKTREE_MULTITHREADED
#define RB_LOCK_ALLOCINIT	arrayLock	= [[NSRecursiveLock alloc] init];
#define RB_LOCK_RELEASE		[arrayLock release];
#define RB_LOCK_LOCK		[arrayLock lock];
#define RB_LOCK_UNLOCK		[arrayLock unlock];
#else
#define RB_LOCK_ALLOCINIT
#define RB_LOCK_RELEASE	
#define RB_LOCK_LOCK	
#define RB_LOCK_UNLOCK	
#endif


@implementation JNXSortedArray


// NSObject methods

- (id)init
{
    if( !(self=[super init]) )
		return nil;
		
    embeddedArray = [[NSMutableArray alloc] init];
    RB_LOCK_ALLOCINIT
    comparetype = COMPARE_SELECTOR;
    compareselector = @selector(compare:);
    return self;
}

- (void)dealloc
{
    [embeddedArray release];
    RB_LOCK_RELEASE
    [super dealloc];
}


// NSArray Simple

- (NSUInteger)count;
{
    return [embeddedArray count];
}

- (id)objectAtIndex:(NSUInteger)index;
{
    return [embeddedArray objectAtIndex:index];
}


// NSArray (NSCreationMethods)

+ array
{
    return [[[self alloc] init] autorelease];
}

+ (id)arrayWithContentsOfFile:(NSString *)path;
{
    NSArray 	*unsortedArray = [NSArray arrayWithContentsOfFile:path];
    JNXSortedArray *sortedArray = [self array];
    [sortedArray addObjectsFromArray:unsortedArray];
    return sortedArray;
}

+ (id)arrayWithObject:(id)anObject;
{
    JNXSortedArray *sortedArray = [self array];
    [sortedArray addObject:anObject];
    return sortedArray;
}

+ (id)arrayWithObjects:(id)firstObj, ...;
{
    JNXSortedArray *sortedArray = [self array];
    id 		anObject;
    va_list 	ap;

    va_start(ap, firstObj);
    if(firstObj)
    {
        [sortedArray addObject:firstObj];
        while( (anObject = va_arg(ap, id)) )
        {
            [sortedArray addObject:anObject];
        }
    }
    va_end(ap);
    return sortedArray;
}

- (id)initWithArray:(NSArray *)array;
{
    [[self init] addObjectsFromArray:array];
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path;
{
    NSArray 	*unsortedArray = [NSArray arrayWithContentsOfFile:(NSString *)path];

    [[self init] addObjectsFromArray:unsortedArray];
    return self;
}

- (id)initWithObjects:(id *)objects count:(NSUInteger)count;
{
    [self init];
    while(count--)
    {
        [self addObject:objects[count]];
    }
    return self;
}

- (id)initWithObjects:(id)firstObj, ...;
{
    id		anObject;
    va_list 	ap;

    [self init];
    va_start(ap, firstObj);
    while( anObject = va_arg(ap, id) )
    {
        [self addObject:anObject];
    }
    va_end(ap);
    return self;
}


#if !defined(STRICT_OPENSTEP)

+ (id)arrayWithArray:(NSArray *)array;
{
    JNXSortedArray *sortedArray = [JNXSortedArray array];
    [sortedArray addObjectsFromArray:array];
    return sortedArray;
}

+ (id)arrayWithObjects:(id *)objs count:(NSUInteger)cnt;
{
    JNXSortedArray *sortedArray = [JNXSortedArray array];
    [sortedArray initWithObjects:objs count:cnt];
    return sortedArray;
}

#endif 

// New Methods to SortedArray

+ (JNXSortedArray *)sortedArray
{
    return (JNXSortedArray *)[[[self alloc] init] autorelease];
}

- (NSMutableArray *)unsortedCopy;
{
    return [[embeddedArray mutableCopy] autorelease];
}


- (void)adjustObjectIdenticalTo:(id)objectToAdjust;
{
    RB_LOCK_LOCK
    [embeddedArray removeObjectIdenticalTo:[objectToAdjust retain]];
    [self addObject:objectToAdjust];
    [objectToAdjust release];
    RB_LOCK_UNLOCK
}

// NSMutable Array simple functions;


- (void)addObject:(id)anObject;
{
    NSUInteger	min = 0;
    NSUInteger max ;
    NSUInteger mom;
    RB_LOCK_LOCK
    max = [embeddedArray count]-1;
    if( -1 == max)
    {
        [embeddedArray addObject:anObject];
    }
    else
    {
        mom = max/2;

        if( COMPARE_FUNCTION == comparetype )
        {
            while( 1 )
            {
                switch( comparefunction([embeddedArray objectAtIndex:mom],anObject,comparecontext) )
                {
                    case NSOrderedDescending:
                    {
                        max = mom-1;
                        if( max<=min )
                        {
                            switch( comparefunction([embeddedArray objectAtIndex:min],anObject,comparecontext) )
                            {
                                case NSOrderedDescending:	[embeddedArray insertObject:anObject atIndex:min];break;
                                case NSOrderedAscending:	[embeddedArray insertObject:anObject atIndex:min+1];break;
                                case NSOrderedSame:		[embeddedArray insertObject:anObject atIndex:min];break;
                            }
                            RB_LOCK_UNLOCK
                            return;
                        }
                        break;
                    }
                    case NSOrderedAscending:
                    {
                        min = mom+1;
                        if( min>=max )
                        {
                            switch( comparefunction([embeddedArray objectAtIndex:max],anObject,comparecontext) )
                            {
                                case NSOrderedDescending:	[embeddedArray insertObject:anObject atIndex:max];break;
                                case NSOrderedAscending:	[embeddedArray insertObject:anObject atIndex:max+1];break;
                                case NSOrderedSame:		[embeddedArray insertObject:anObject atIndex:max];break;
                            }
                            RB_LOCK_UNLOCK
                            return;
                        }
                        break;
                    }
                    case NSOrderedSame: {[embeddedArray insertObject:anObject atIndex:mom]; RB_LOCK_UNLOCK return;}
                    default: { NSLog(@"SortedArray: comparefuntion returned wrong value - no Object inserted."); return;}
                }
                mom= (min+max)/2;
            }
        }
        else
        {
            while( 1 )
            {
                switch( (NSComparisonResult)[[embeddedArray objectAtIndex:mom] performSelector:compareselector withObject:anObject] )
                {
                    case NSOrderedDescending:
                    {
                        max = mom-1;
                        if( max<=min )
                        {
                            switch( (NSComparisonResult)([[embeddedArray objectAtIndex:min] performSelector:compareselector
                                                                                        withObject:anObject]) )
                            {
                                case NSOrderedDescending:	[embeddedArray insertObject:anObject atIndex:min];break;
                                case NSOrderedAscending:	[embeddedArray insertObject:anObject atIndex:min+1];break;
                                case NSOrderedSame:		[embeddedArray insertObject:anObject atIndex:min];break;
                            }
                            RB_LOCK_UNLOCK
                            return;
                        }
                        break;
                    }
                    case NSOrderedAscending:
                    {
                        min = mom+1;
                        if( min>=max )
                        {
                            switch( (NSComparisonResult)([[embeddedArray objectAtIndex:max] performSelector:compareselector
                                                                                        withObject:anObject]) )
                            {
                                case NSOrderedDescending:	[embeddedArray insertObject:anObject atIndex:max];break;
                                case NSOrderedAscending:	[embeddedArray insertObject:anObject atIndex:max+1];break;
                                case NSOrderedSame:		[embeddedArray insertObject:anObject atIndex:max];break;
                            }
                            RB_LOCK_UNLOCK
                            return;
                        }
                        break;
                    }
                    case NSOrderedSame: {[embeddedArray insertObject:anObject atIndex:mom]; RB_LOCK_UNLOCK return;}
                    default: { NSLog(@"SortedArray: comparemethod returned wrong value - no Object inserted."); return;}
                }
                mom= (min+max)/2;
            }
        }
    }
    RB_LOCK_UNLOCK
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    [self addObject:anObject];
}


- (NSUInteger)indexOfObject:(id)anObject;
{
    NSUInteger	min = 0;
    NSUInteger max ;
    NSUInteger mom;
    RB_LOCK_LOCK
    max = [embeddedArray count]-1;
    if( -1 == max)
    {
        return -1;
    }
    else
    {
        mom = max/2;

        if( COMPARE_FUNCTION == comparetype )
        {
            while( 1 )
            {
                switch( comparefunction([embeddedArray objectAtIndex:mom],anObject,comparecontext) )
                {
                    case NSOrderedDescending:
                    {
                        max = mom-1;
                        if( max<=min )
                        {
                            switch( comparefunction([embeddedArray objectAtIndex:min],anObject,comparecontext) )
                            {
                                case NSOrderedSame: { RB_LOCK_UNLOCK return min;}
                                default: break;
                            }
                            RB_LOCK_UNLOCK
                            return -1;
                        }
                        break;
                    }
                    case NSOrderedAscending:
                    {
                        min = mom+1;
                        if( min>=max )
                        {
                            switch( comparefunction([embeddedArray objectAtIndex:max],anObject,comparecontext) )
                            {
                                case NSOrderedSame: { RB_LOCK_UNLOCK return max;}
                                default: break;
                            }
                            RB_LOCK_UNLOCK
                            return -1;
                        }
                        break;
                    }
                    case NSOrderedSame: { RB_LOCK_UNLOCK return mom;}
                    default: { NSLog(@"SortedArray: comparefuntion returned wrong value - no Object found."); return -1;}
                }
                mom= (min+max)/2;
            }
        }
        else
        {
            while( 1 )
            {
                switch( (NSComparisonResult)([[embeddedArray objectAtIndex:mom] performSelector:compareselector withObject:anObject]) )
                {
                    case NSOrderedDescending:
                    {
                        max = mom-1;
                        if( max<=min )
                        {
                            switch( (NSComparisonResult)([[embeddedArray objectAtIndex:min] performSelector:compareselector
                                                                                        withObject:anObject]) )
                            {
                                case NSOrderedSame: { RB_LOCK_UNLOCK return min;}
                                default: break;
                            }
                            RB_LOCK_UNLOCK
                            return -1;
                        }
                        break;
                    }
                    case NSOrderedAscending:
                    {
                        min = mom+1;
                        if( min>=max )
                        {
                            switch( (NSComparisonResult)([[embeddedArray objectAtIndex:max] performSelector:compareselector
                                                                                        withObject:anObject]) )
                            {
                                case NSOrderedSame: { RB_LOCK_UNLOCK return max;}
                                default: break;
                            }
                            RB_LOCK_UNLOCK
                            return -1;
                        }
                        break;
                    }
                    case NSOrderedSame: { RB_LOCK_UNLOCK return mom;}
                    default: { NSLog(@"SortedArray: comparefuntion returned wrong value - no Object found."); return -1;}
                }
                mom= (min+max)/2;
            }
        }
    }
    RB_LOCK_UNLOCK
	return -1;
}



- (void)removeObject:(id)anObject;
{
    RB_LOCK_LOCK
    [embeddedArray removeObject:anObject];
    RB_LOCK_UNLOCK
}

- (void)removeObjectIdenticalTo:(id)anObject;
{
    RB_LOCK_LOCK
    [embeddedArray removeObjectIdenticalTo:anObject];
    RB_LOCK_UNLOCK
}

- (void)removeLastObject
{
    RB_LOCK_LOCK
    [embeddedArray removeLastObject];
    RB_LOCK_UNLOCK
}

- (void)removeObjectAtIndex:(NSUInteger)index;
{
    RB_LOCK_LOCK
    [embeddedArray removeObjectAtIndex:index];
    RB_LOCK_UNLOCK
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
{
    RB_LOCK_LOCK
    [embeddedArray removeObjectAtIndex:index];
    [self addObject:anObject];
    RB_LOCK_UNLOCK
}
// NSMutableArray (NSMutableArrayCreation)

+ (id)arrayWithCapacity:(NSUInteger)numItems;
{
    return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (id)initWithCapacity:(NSUInteger)numItems;
{
    embeddedArray = [[NSMutableArray alloc] initWithCapacity:numItems];
	RB_LOCK_ALLOCINIT
    comparetype = COMPARE_SELECTOR;
    compareselector =@selector(compare:);
    return self;
}

// Overridden Methods
- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray range:(NSRange)otherRange;
{
    RB_LOCK_LOCK
    [embeddedArray removeObjectsInRange:range];
    [self addObjectsFromArray:[otherArray subarrayWithRange:otherRange]];
    RB_LOCK_UNLOCK
}

- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray;
{
    RB_LOCK_LOCK
    [embeddedArray removeObjectsInRange:range];
    [self addObjectsFromArray:otherArray];
    RB_LOCK_UNLOCK
}

- (void)sortUsingFunction:(NSComparisonResult (*)(id, id, void *))compare context:(void *)context;
{
    comparetype = COMPARE_FUNCTION;
    comparefunction = compare;
    comparecontext = context;
    RB_LOCK_LOCK
    [embeddedArray sortUsingFunction:compare context:context];
    RB_LOCK_UNLOCK
}

- (void)sortUsingSelector:(SEL)aSelector;
{
    comparetype = COMPARE_SELECTOR;
    compareselector =aSelector;
    RB_LOCK_LOCK
    [embeddedArray sortUsingSelector:aSelector];
    RB_LOCK_UNLOCK
}


@end
