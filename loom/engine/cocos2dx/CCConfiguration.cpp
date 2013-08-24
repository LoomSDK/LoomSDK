/****************************************************************************
*  Copyright (c) 2010-2012 cocos2d-x.org
*  Copyright (c) 2010      Ricardo Quesada
*
*  http://www.cocos2d-x.org
*
*  Permission is hereby granted, free of charge, to any person obtaining a copy
*  of this software and associated documentation files (the "Software"), to deal
*  in the Software without restriction, including without limitation the rights
*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*  copies of the Software, and to permit persons to whom the Software is
*  furnished to do so, subject to the following conditions:
*
*  The above copyright notice and this permission notice shall be included in
*  all copies or substantial portions of the Software.
*
*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
*  THE SOFTWARE.
****************************************************************************/

#include "CCConfiguration.h"
#include "ccMacros.h"
#include "ccConfig.h"
#include <string.h>

using namespace std;

NS_CC_BEGIN

CCConfiguration *CCConfiguration::s_gSharedConfiguration = NULL;

CCConfiguration::CCConfiguration(void)
{
}


bool CCConfiguration::init(void)
{
    bool bEnableProfilers = false;

#if CC_ENABLE_PROFILERS
    bEnableProfilers = true;
#else
    bEnableProfilers = false;
#endif

    CCLOG("cocos2d: compiled with Profiling Support: %s",
          bEnableProfilers ? "YES - *** Disable it when you finish profiling ***" : "NO");

    return true;
}


CCConfiguration *CCConfiguration::sharedConfiguration(void)
{
    if (!s_gSharedConfiguration)
    {
        s_gSharedConfiguration = new CCConfiguration();
        s_gSharedConfiguration->init();
    }

    return s_gSharedConfiguration;
}


void CCConfiguration::purgeConfiguration(void)
{
    CC_SAFE_RELEASE_NULL(s_gSharedConfiguration);
}


NS_CC_END
