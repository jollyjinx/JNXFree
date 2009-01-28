
#import "MTQueue.h"

@implementation MTQueue

DEBUGRETAINCYCLE


- init
{
	DJLOG

	if( !(self=[super init]) )
		return nil;
		
	if( !(queueArray = [[NSMutableArray alloc] init]) )
	{
		[self release];
		return nil;
	}
	
	switch( pthread_mutex_init(&queuelock,NULL) )
	{
		case 0	: break;
		default	: JLog(@"pthread_mutex_init failed"); return nil;
	}
	switch( pthread_cond_init(&queuecondition,NULL) )
	{
		case 0	: break;
		default	: JLog(@"pthread_cond_init failed"); return nil;
	}
	
	arraycounter	= 0;
	
    return self;
}

- (void)dealloc
{
	DJLOG
	
	if( queueArray ) [queueArray release];

	switch( pthread_mutex_destroy(&queuelock) )
	{
		case 0	: break;
		default	: JLog(@"pthread_mutex_destroy failed"); return;
	}
	switch( pthread_cond_destroy(&queuecondition) )
	{
		case 0	: break;
		default	: JLog(@"pthread_mutex_destroy failed"); return;
	}
    [super dealloc];
}



- pop;
{
    id	anObject;
	
	pthread_mutex_lock(&queuelock);
	
	while( arraycounter < 1 )
	{
		pthread_cond_wait(&queuecondition,&queuelock);
	}

    anObject = [[[queueArray objectAtIndex:0] retain] autorelease];
    [queueArray removeObjectAtIndex:0];
	arraycounter--;
	
	pthread_mutex_unlock(&queuelock);
    
    return anObject;
}


- popBeforeDate:(NSDate *)endDate
{
    id	anObject;

	if( [endDate timeIntervalSinceNow] < 0.0 )
	{
		return nil;
	}
	
	pthread_mutex_lock(&queuelock);

	double	endtimeasdouble	= [endDate timeIntervalSince1970];
	
	struct timespec endtime;
	
	endtime.tv_sec	= endtimeasdouble;
	endtime.tv_nsec	= ((double)1000000000.0f) *(endtimeasdouble-(double)( (int)endtimeasdouble));
	

	while( arraycounter < 1 )
	{
	//	JLog(@"endtime: %5.4f %d %d ",(double)endtimeasdouble,endtime.tv_sec,endtime.tv_nsec);
		if( 0 != pthread_cond_timedwait(&queuecondition,&queuelock,&endtime) )
		{
		//	JLog(@"Failed");
			pthread_mutex_unlock(&queuelock);
			return nil;
		}
		//JLog(@"ok");
	}

    anObject = [[[queueArray objectAtIndex:0] retain] autorelease];
    [queueArray removeObjectAtIndex:0];
	arraycounter--;
	
	pthread_mutex_unlock(&queuelock);
    
    return anObject;
}



- popDoNotBlock;
{
    id	anObject=nil;

	pthread_mutex_lock(&queuelock);
    if(arraycounter)
    {
        anObject = [[[queueArray objectAtIndex:0] retain] autorelease];
        [queueArray removeObjectAtIndex:0];
		arraycounter--;
	}
	pthread_mutex_unlock(&queuelock);
    
    return anObject;
}


- (void)push:(id)anObject;
{
	pthread_mutex_lock(&queuelock);
    [queueArray addObject:anObject];
	arraycounter++;
	pthread_mutex_unlock(&queuelock);
	pthread_cond_broadcast(&queuecondition);
}

- (unsigned int) count;
{
	int currentcounter;
	pthread_mutex_lock(&queuelock);
	currentcounter = arraycounter;
	pthread_mutex_unlock(&queuelock);
    return currentcounter;
}


@end
