#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "shadowsocks.h"
#import "config.h"

FOUNDATION_EXPORT double ShadowSocks_libev_iOSVersionNumber;
FOUNDATION_EXPORT const unsigned char ShadowSocks_libev_iOSVersionString[];

