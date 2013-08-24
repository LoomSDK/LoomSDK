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

#ifndef __CCCONFIGURATION_H__
#define __CCCONFIGURATION_H__

#include "cocoa/CCObject.h"
#include "CCGL.h"
#include <string>

NS_CC_BEGIN

/**
 * @addtogroup global
 * @{
 */

/**
 * @brief CCConfiguration contains some openGL variables
 * @since v0.99.0
 */
class CC_DLL CCConfiguration : public CCObject
{
public:
    /** returns a shared instance of CCConfiguration */
    static CCConfiguration *sharedConfiguration(void);

    /** purge the shared instance of CCConfiguration */
    static void purgeConfiguration(void);

public:

    bool init(void);

private:
    // TODO: Hide this again for script.
    CCConfiguration(void);

    static CCConfiguration *s_gSharedConfiguration;

protected:
};

// end of global group
/// @}

NS_CC_END
#endif // __CCCONFIGURATION_H__
