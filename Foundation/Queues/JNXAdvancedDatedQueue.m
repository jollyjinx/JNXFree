#import "JNXAdvancedDatedQueue.h"

#define	FIRST_IN_QUEUE_IS_UNKNOWN	0
#define FIRST_IN_QUEUE_IS_KNOWN		1

@interface AdvancedDatedQueueLeaf : NSObject
{
    id		contentObject;
    NSDate	*contentDate;
}
- initWithObject:(id)anObject andDate:(NSDate *)aDate;
- (NSComparisonResult)compare:(id)anObject;
- contentObject;
- (NSDate *) contentDate;
@end

@implementation AdvancedDatedQueueLeaf
{
    id		contentObject;
    NSDate	*contentDate;
}

- (void)dealloc;
{
    [contentObject release];
    [contentDate release];
    [super dealloc];
    //NSLog(@"AdvancedDatedQueueLeaf: -dealloc");
}

- initWithObject:(id)anObject andDate:(NSDate *)aDate;
{
    if( !(self=[super init]) )
		return nil;
		
    NSAssert( contentObject = [anObject retain] , @"AdvancedDatedQueueLeaf: -initWithObject:andDate: got called without Object");
    NSAssert( contentDate = [aDate retain]	, @"AdvancedDatedQueueLeaf: -initWithObject:andDate: got called without Date");
    
    return self;
}


- (NSComparisonResult)compare:(id)anObject;
{
    NSComparisonResult result;
    if( NSOrderedSame == ( result = [contentDate compare:(NSDate *)[anObject contentDate]] ) )
    {
        if(self == anObject) return NSOrderedSame;
        return (void*)self<(void*)anObject?NSOrderedAscending:NSOrderedDescending;
    }
    return result;
}

- contentObject;
{
    return contentObject;
}
- (NSDate *) contentDate;
{
    return contentDate;
}
@end




@implementation JNXAdvancedDatedQueue

- init
{
    [super init];
    
    queueLock			= [[NSConditionLock alloc] initWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
    singlePopLock		= [[NSConditionLock alloc] init];
    queueRedBlackTree	= [[JNXRedBlackTree alloc] init];
    queueDictionary		= [[NSMutableDictionary alloc] init];

    return self;
}

- (void) dealloc
{
    [queueLock release];
    [singlePopLock release];
    [queueRedBlackTree release];
    [queueDictionary release];
    [super dealloc];
}


- pop;
{
    return [self popBeforeDate:[NSDate distantFuture]];
}

- popBeforeDate:(NSDate *)endDate;
{
    NSDate *aDate=endDate;

    if( NO == [singlePopLock lockBeforeDate:endDate] )
    {
        return nil;
    }
        

    while(1)
    {
        if( YES == [queueLock lockWhenCondition:FIRST_IN_QUEUE_IS_UNKNOWN beforeDate:aDate] )
        {
            aDate = (NSDate *)[[[[queueRedBlackTree firstObject] contentDate] retain] autorelease];
            [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
        }
        else
        {
            NSDate	*nowDate;

            [queueLock lock];
            NSAssert2([queueRedBlackTree count] == [queueDictionary count], @"AdvancedDatedQueue popBeforeDate: queueRedBlackTree count:%d, queueDictionary count:%d",[queueRedBlackTree count],[queueDictionary count]);
            nowDate = [NSDate date];
            
            if( 0 == [queueRedBlackTree count] )
            {
                [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
                aDate = endDate;
            }
            else
            {
                AdvancedDatedQueueLeaf	*aLeaf = [queueRedBlackTree firstObject];

                if( NSOrderedDescending == [nowDate compare:(NSDate*)[aLeaf contentDate]] )
                {
                    NSObject *contentObject = [[aLeaf contentObject] retain];

                    [queueRedBlackTree removeObject:aLeaf];
                    [queueDictionary removeObjectForKey:contentObject];

                    NSAssert2([queueRedBlackTree count] == [queueDictionary count], @"AdvancedDatedQueue popBeforeDate: queueRedBlackTree count:%d, queueDictionary count:%d",[queueRedBlackTree count],[queueDictionary count]);
                    [queueLock unlockWithCondition:([queueRedBlackTree count]?FIRST_IN_QUEUE_IS_UNKNOWN:FIRST_IN_QUEUE_IS_KNOWN)];
                    [singlePopLock unlock];

                    return [contentObject autorelease];
                }

                NSAssert2([queueRedBlackTree count] == [queueDictionary count], @"AdvancedDatedQueue popBeforeDate: queueRedBlackTree count:%d, queueDictionary count:%d",[queueRedBlackTree count],[queueDictionary count]);
                [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_UNKNOWN];
            }

            if( NSOrderedDescending == [nowDate compare:endDate] )
            {
                [singlePopLock unlock];
                return nil;
            }
        }
    }
}

- (BOOL)containsObject:(id)anObject;
{
    return ([queueDictionary objectForKey:anObject])?YES:NO;
}


- (void)removeObjectIdenticalTo:(id)anObject;
{
    AdvancedDatedQueueLeaf	*aLeaf;

    [queueLock lock];
    
    NSAssert( aLeaf = [queueDictionary objectForKey:anObject], @"AdvancedDatedQueue: -removeObjectIdenticalTo: got called with unknown Object" );

    [queueDictionary removeObjectForKey:anObject];
    [queueRedBlackTree removeObject:aLeaf];

    if( 0 == [queueRedBlackTree count] )
    {
        [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
    }
    else
    {
        [queueLock unlockWithCondition:(([queueRedBlackTree firstObject]==aLeaf)?FIRST_IN_QUEUE_IS_UNKNOWN:[queueLock condition])];
    }
}


- (void)removeAllObjects;
{
    [queueLock lock];

    [queueDictionary release];
    [queueRedBlackTree release];
    
    queueRedBlackTree	= [[JNXRedBlackTree alloc] init];
    queueDictionary		= [[NSMutableDictionary alloc] init];
    
    [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
}



- (void) push:(id)anObject withDate:(NSDate *)aDate;
{
    AdvancedDatedQueueLeaf	*oldLeaf,*newLeaf;
    int				lockcondition;
    [queueLock lock];
    lockcondition = [queueLock condition];
    
    if( oldLeaf = [queueDictionary objectForKey:anObject] )
    {
        if( [queueRedBlackTree firstObject] == oldLeaf )
        {
            lockcondition = FIRST_IN_QUEUE_IS_UNKNOWN;
        }
        [queueRedBlackTree removeObject:oldLeaf];
        [queueDictionary removeObjectForKey:anObject];
    }

    newLeaf = [[AdvancedDatedQueueLeaf alloc] initWithObject:anObject andDate:aDate];
    [queueRedBlackTree addObject:newLeaf];
    [queueDictionary setObject:newLeaf forKey:anObject];
    [newLeaf release];

    NSAssert2([queueRedBlackTree count] == [queueDictionary count], @"AdvancedDatedQueue push:withDate: queueRedBlackTree count:%d, queueDictionary count:%d",[queueRedBlackTree count],[queueDictionary count]);

    [queueLock unlockWithCondition:(([queueRedBlackTree firstObject]==newLeaf)?FIRST_IN_QUEUE_IS_UNKNOWN:lockcondition)];
}


- (unsigned int) count;
{
    return [queueRedBlackTree count];
}


@end

