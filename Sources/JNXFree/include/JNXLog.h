// Creator: Patrick Stein aka jolly@jinx.de
#ifdef __OBJC__

#ifndef __JNXLOG__
#define __JNXLOG__

#ifndef DEBUG
#define DEBUG 0
#endif

#define FIXRANGE(A,MIN,MAX)		\
{								\
	if( A < MIN )				\
	{							\
		A = MIN;				\
	}							\
	else if( A >MAX )			\
	{							\
		A = MAX;				\
	}							\
}


@import Foundation;

#if MAC_OS_X_VERSION_10_5 && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5)
#else	
	#define NSInteger int
#endif	




	#ifndef JLog
		#define JLine(...)			([NSString stringWithFormat:@"\t(%p.%04i)%s %@",self,__LINE__,__PRETTY_FUNCTION__,[NSString stringWithFormat:__VA_ARGS__ ]])
		#define JLineC(...)			([NSString stringWithFormat:@"\t(%p.%04i)%@ %s(): %@",NULL,__LINE__,[[NSString stringWithUTF8String:__FILE__]lastPathComponent],__FUNCTION__,[NSString stringWithFormat:__VA_ARGS__ ]])

		#define JLog(...)           NSLog(@"\t(%p.%04i)%s %@",self,__LINE__,__PRETTY_FUNCTION__,[NSString stringWithFormat:__VA_ARGS__ ])
		#define JLogC(...)          NSLog(@"\t(%p.%04i)%@ %s(): %@",NULL,__LINE__,[[NSString stringWithUTF8String:__FILE__] lastPathComponent],__FUNCTION__,[NSString stringWithFormat:__VA_ARGS__ ])

		#define DJLog		if(DEBUG)JLog
		#define DJLogC		if(DEBUG)JLogC
		
		#define D2JLog		if(DEBUG>1)JLog
		#define D2JLogC		if(DEBUG>1)JLogC
		
		#define D3JLog		if(DEBUG>2)JLog
		#define D3JLogC		if(DEBUG>2)JLogC

		#define DJLOG		if(DEBUG)DJLog(@"");
		#define D2JLOG		if(DEBUG>1)DJLog(@"");
		#define D3JLOG		if(DEBUG>2)DJLog(@"");
	#endif


	#ifndef DNSLog
		#define DNSLog		if(DEBUG)JLogC
		#define D2NSLog		if(DEBUG>1)JLogC
	#endif



	#ifdef DEBUGRETAIN
	#define DEBUGRETAINCYCLE	\
	- retain\
	{\
		[super retain];\
		JLog(@"%d",[self retainCount]);\
		return self;\
	}\
	\
	- (void)release\
	{\
		JLog(@"%d",[self retainCount]-1);\
		[super release];\
	}\
	- autorelease\
	{\
		[super autorelease];\
		JLog(@"%d",[self retainCount]);\
		return self;\
	}\

	#else
	#define DEBUGRETAINCYCLE
	#endif


	#if NDEBUG
	#define TIMELOG(nsstring)
	#else 
	#define TIMELOG(nsstring)	\
	{																														\
		static CFAbsoluteTime	timeloglasttime	= 0;																		\
		CFAbsoluteTime			timelogtimenow		= CFAbsoluteTimeGetCurrent();											\
		NSLog(@"%@ %3.2fHz %8.4fms",nsstring,1.0/(timelogtimenow-timeloglasttime),(timelogtimenow-timeloglasttime)*1000.0);	\
		timeloglasttime = timelogtimenow;																									\
	}
	#endif
#endif

#endif
