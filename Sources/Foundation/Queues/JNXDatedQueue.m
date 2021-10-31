
#import "JNXDatedQueue.h"
#import "JNXSortedArray.h"

#define	QUEUE_IS_UNKNOWN	0
#define QUEUE_IS_KNOWN		1

@interface JNXDatedQueueLeaf : NSObject
{
    id		contentObject;
    NSDate	*contentDate;
}
- initWithObject:(id)anObject andDate:(NSDate *)aDate;
- (NSComparisonResult)compare:(id)anObject;
- contentObject;
- (NSDate *) contentDate;
@end

@implementation JNXDatedQueueLeaf
{
    id		contentObject;
    NSDate	*contentDate;
}

- (void)dealloc;
{
    [contentObject release];
    [contentDate release];
    [super dealloc];
}

- initWithObject:(id)anObject andDate:(NSDate *)aDate;
{
    if( !(self=[super init]) )
		return nil;
	
    contentObject	= [anObject retain];
    contentDate		= [aDate retain];
    
    return self;
}

- (NSComparisonResult)compare:(id)anObject;
{
    return [contentDate compare:(NSDate *)[anObject contentDate]];
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


@implementation JNXDatedQueue
{
    NSConditionLock	*queueLock;
    NSLock			*singlePopLock;
    JNXSortedArray 	*queueArray;
}


- init
{
    if( !(self=[super init]) )
		return nil;
		
    queueLock		= [[NSConditionLock alloc] initWithCondition:QUEUE_IS_KNOWN];
    singlePopLock	= [[NSConditionLock alloc] init];
    queueArray		= [[JNXSortedArray alloc] init];
    return self;
}

- (void) dealloc
{
    [queueLock release];
    [singlePopLock release];
    [queueArray release];
    [super dealloc];
}


- pop;
{
    NSDate		*aDate = [NSDate distantFuture];
    JNXDatedQueueLeaf	*aLeaf;
    
    [singlePopLock lock];
    [queueLock lock];
    [queueLock unlockWithCondition:([queueArray count]?QUEUE_IS_UNKNOWN:QUEUE_IS_KNOWN)];
    do
    {
        if( [queueLock lockWhenCondition:QUEUE_IS_UNKNOWN beforeDate:aDate] )
        {
            aDate = (NSDate *)[[queueArray objectAtIndex:0] contentDate];
            [queueLock unlockWithCondition:QUEUE_IS_KNOWN];
        }
    }
    while( NSOrderedDescending == [aDate compare:[NSDate date]] );
      

    [queueLock lock];
    aLeaf = [[[queueArray objectAtIndex:0] retain] autorelease];
    [queueArray removeObjectAtIndex:0];
    [queueLock unlockWithCondition:([queueArray count]?QUEUE_IS_UNKNOWN:QUEUE_IS_KNOWN)];

    [singlePopLock unlock];
    return [aLeaf contentObject];
}


- popBeforeDate:(NSDate *)endDate;
{
    NSDate		*aDate = endDate;
    JNXDatedQueueLeaf	*aLeaf;
    
    [singlePopLock lock];
    [queueLock lock];
    [queueLock unlockWithCondition:([queueArray count]?QUEUE_IS_UNKNOWN:QUEUE_IS_KNOWN)];
    do
    {
        if( [queueLock lockWhenCondition:QUEUE_IS_UNKNOWN beforeDate:aDate] )
        {
            aDate = (NSOrderedAscending == [endDate compare:(NSDate *)[[queueArray objectAtIndex:0] contentDate]] ? endDate :(NSDate *)[[queueArray objectAtIndex:0] contentDate]);
            [queueLock unlockWithCondition:QUEUE_IS_KNOWN];
        }
        else
        {
            if( endDate == aDate )
            {
                [singlePopLock unlock];
                return nil;
            }
        }
    }
    while( NSOrderedDescending == [aDate compare:[NSDate date]] );


    [queueLock lock];
    aLeaf = [[[queueArray objectAtIndex:0] retain] autorelease];
    [queueArray removeObjectAtIndex:0];
    [queueLock unlockWithCondition:([queueArray count]?QUEUE_IS_UNKNOWN:QUEUE_IS_KNOWN)];

    [singlePopLock unlock];
    return [aLeaf contentObject];
}

- (void) push:(id)anObject;
{
    JNXDatedQueueLeaf *aLeaf = [[JNXDatedQueueLeaf alloc] initWithObject:anObject andDate:[NSDate distantPast]];

    [queueLock lock];
    [queueArray addObject:aLeaf];
    [queueLock unlockWithCondition:(([queueArray objectAtIndex:0]==aLeaf)?QUEUE_IS_UNKNOWN:[queueLock condition])];
    [aLeaf release];
}

- (void) push:(id)anObject withDate:(NSDate *)aDate;
{
    JNXDatedQueueLeaf *aLeaf = [[JNXDatedQueueLeaf alloc] initWithObject:anObject andDate:aDate];

    [queueLock lock];
    [queueArray addObject:aLeaf];
    [queueLock unlockWithCondition:(([queueArray objectAtIndex:0]==aLeaf)?QUEUE_IS_UNKNOWN:[queueLock condition])];
    [aLeaf release];
}

- (unsigned int) count;
{
    return [queueArray count];
}
- (BOOL)containsObject:(id)anObject;
{
    return [queueArray containsObject:anObject];
}


@end

