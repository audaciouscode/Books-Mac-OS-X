
#ifndef _DEBUG_MACROS_H_
#define _DEBUG_MACROS_H_

#ifndef DEBUG
	#define DEBUG										1
#endif

#ifndef FUNCTION_IO_LOGGING
    #define FUNCTION_IO_LOGGING                         0
#endif


#if DEBUG
	#include <stdio.h>
	#include <syslog.h>
	#include <string.h>
	
	static const char * rFILE(const char * inStr) { 
		int count = strlen(inStr); 
		while (count && *(inStr + count - 1) != '/')
			count--;
		return inStr + count;
	}
	
	#define d_syslog(...)       syslog(LOG_INFO, __VA_ARGS__)
	
	#define DEBUGMSG(...)       do {	char tempstr[256];                                                                  \
										sprintf(tempstr, __VA_ARGS__);                                                      \
										fprintf(stderr, "%s:%d:%s %s\n", rFILE(__FILE__), __LINE__, __func__, tempstr);     \
								} while (0)
								
	#define BAILERR( x )        do {                                                                                            \
									OSStatus tErr = (x);																		\
									if ( tErr ) {                                                                               \
										fprintf(stderr, "%s:%d:%s ### Err %ld\n", rFILE(__FILE__), __LINE__, __func__, tErr);	\
										goto bail;                                                                              \
									}                                                                                           \
								} while (0)
								
	#define BAILSETERR( x )     do {                                                                                            \
									err = (x);	                                                                             	\
									if ( err ) {                                                                                \
										fprintf(stderr, "%s:%d:%s ### Err %ld\n", rFILE(__FILE__), __LINE__, __func__, err);  	\
										goto bail;                                                                              \
									}                                                                                           \
								} while (0)
								
	#define BAILIFTRUE( x, errCode )    do {																			\
											if ( (x) ) {                                                                \
												err = errCode;  														\
												if (err != noErr)                                                   	\
													fprintf(stderr, "%s:%d:%s ### Err %ld\n",                           \
														rFILE(__FILE__), __LINE__, __func__, err);             			\
												goto bail;                                              				\
											}                                                                           \
										} while (0)
								
	#define DEBUGERR( x )       do { 																							\
									OSStatus tErr = (x);                                                                    	\
									if ( tErr )                                                                             	\
										fprintf(stderr, "%s:%d:%s ### Err %ld\n", rFILE(__FILE__), __LINE__, __func__, tErr);	\
								} while (0)
								
	#define DEBUGSTR(...)       do {    char tempstr[256];                  \
										sprintf(tempstr, __VA_ARGS__);      \
										fprintf(stderr, "%s\n", tempstr);   \
								} while (0)
	
	#define MSG_ON_ERROR(...)   do { if (err) fprintf(stderr, __VA_ARGS__); } while (0)

	#include <assert.h>
	
	#define ASSERT(x)	assert(x)

	#define TRESPASS()                                                                      			\
			do																							\
			{																							\
				fprintf(stderr,"should not be here (%s:%d:%s)\n", rFILE(__FILE__), __LINE__, __func__);	\
				assert(0);																				\
			}																							\
			while (0)

	#define DEBUG_ONLY(x)	x
#else
    #define d_syslog(...)
    #define DEBUGMSG(...)
    #define BAILERR(x)                  do { OSStatus tErr = (x); if (tErr) goto bail; } while (0)
    #define BAILSETERR(x)               do { err = (x); if (err) { goto bail; } } while (0)
    #define BAILIFTRUE(x, errCode)      do { err = (x); if (err) { err = errCode; goto bail; } } while (0)
    #define DEBUGERR( x ) 
    #define DEBUGSTR(...)
    #define ASSERT(x)
    #define TRESPASS()
    #define MSG_ON_ERROR(...)
    #define DEBUG_ONLY(x)
#endif

#define SILENTBAILSETERR(x)             do { err = (x); if (err) { goto bail; } } while (0)

#if FUNCTION_IO_LOGGING
    #define FUNC_ENTRY()                DEBUGSTR("->%s", __func__)
    #define FUNC_EXIT()                 DEBUGSTR("<-%s", __func__)
#else
    #define FUNC_ENTRY()
    #define FUNC_EXIT()
#endif

#endif	/* _DEBUG_MACROS_H_ */

