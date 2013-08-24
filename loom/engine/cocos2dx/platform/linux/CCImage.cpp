#include <string.h>

#include <vector>
#include <string>
#include <sstream>

#include "CCFileUtils.h"

#include "CCPlatformMacros.h"
#include "CCImage.h"
#include "CCStdC.h"
#define __CC_PLATFORM_IMAGE_CPP__
#include "platform/CCImageCommon_cpp.h"

NS_CC_BEGIN


bool CCImage::initWithString(
    const char *pText,
    int        nWidth /* = 0*/,
    int        nHeight /* = 0*/,
    ETextAlign eAlignMask /* = kAlignCenter*/,
    const char *pFontName /* = nil*/,
    int        nSize /* = 0*/)
{
    return false;
}


NS_CC_END
