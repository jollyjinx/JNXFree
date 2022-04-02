/*
 *  osversion.c
 *
 *  Created by Patrick  Stein on 4.3.08.
 *  Copyright 2006-2009 Jinx.de. All rights reserved.
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <sys/sysctl.h>
#include <strings.h>

#include "osversion.h"

int osversion(void)
{
	static int	currentosversion = JNX_OSVERSION_UNKNOWN;
	
	if( JNX_OSVERSION_UNKNOWN != currentosversion )
	{
		return currentosversion;
	}

	char	osname[255];
	size_t	len = sizeof(osname);

	bzero(osname,sizeof(osname));
	
    int mib[] = { CTL_KERN, KERN_OSRELEASE };

	if(		(-1 == sysctl(mib,sizeof(mib)/sizeof(int), NULL, &len, NULL, 0))
		||	( len > 255 )
		||	(-1 == sysctl(mib,sizeof(mib)/sizeof(int), &osname, &len, NULL, 0)) )
	{
		fprintf(stderr,"osversion() unable to sysctl.\n");
		return -1;
	}

	int osversionmajor,osversionminor,patchlevel;
	
	if( 3 == sscanf(osname,"%d.%d.%d",&osversionmajor,&osversionminor,&patchlevel) )
	{
		if( osversionmajor < 0xFF )
		{			
			if( osversionminor	> 0xFF )	osversionminor	= 0xFF;
			if( patchlevel		> 0xFF )	patchlevel		= 0xFF;
			
			currentosversion = (osversionmajor << 16 ) + (osversionminor << 8) +	patchlevel;
		}
	}
	if( -1 == currentosversion ) 
	{
		fprintf(stderr,"Unknown system version:%d\n",currentosversion);
		currentosversion = JNX_OSVERSION_UNKNOWN;
	}
	#if DEBUG
		fprintf(stderr,"osversion() :%x\n",currentosversion);
	#endif
	return currentosversion;
}
