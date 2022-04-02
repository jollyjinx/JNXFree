/*
 *  osversion.h
 *
 *  Created by Patrick  Stein on 4.3.08.
 *  Copyright 2006-2009 Jinx.de. All rights reserved.
 *
 */
 
enum JNX_OS_VERSIONS {
	JNX_OSVERSION_UNKNOWN		=	-1,
	JNX_OSVERSION_10_04_00		=	0x080000,
	JNX_OSVERSION_10_05_00		=	0x090000,
	JNX_OSVERSION_10_06_00		=	0x0A0000,
    JNX_OSVERSION_10_06_06      =   0x0A0600,
    JNX_OSVERSION_10_07_00      =   0x0B0000,
};


int osversion(void);
