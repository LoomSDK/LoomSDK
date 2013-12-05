/****************************************************************************
*  Copyright (c) 2010-2012 cocos2d-x.org
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
#include "CCUserDefault.h"
#include "platform/CCCommon.h"
#include "platform/CCFileUtils.h"
#include "loom/common/xml/tinyxml2.h"
#include "loom/common/config/applicationConfig.h"

#include <stdlib.h>

// root name of xml
#define USERDEFAULT_ROOT_NAME    "userDefaultRoot"

#define XML_FILE_NAME            "UserDefault.xml"

using namespace std;

NS_CC_BEGIN

/**
 * implements of CCUserDefault
 */

CCUserDefault *CCUserDefault::m_spUserDefault          = 0;
string        CCUserDefault::m_sFilePath               = string("");
bool          CCUserDefault::m_sbIsFilePathInitialized = false;

/**
 * If the user invoke delete CCUserDefault::sharedUserDefault(), should set m_spUserDefault
 * to null to avoid error when he invoke CCUserDefault::sharedUserDefault() later.
 */
CCUserDefault::~CCUserDefault()
{
    CC_SAFE_DELETE(m_spUserDefault);
    delete m_document;
    m_spUserDefault = NULL;
}


CCUserDefault::CCUserDefault()
{
    m_document = new tinyxml2::XMLDocument();
}


void CCUserDefault::purgeSharedUserDefault()
{
    m_spUserDefault = NULL;
}


bool CCUserDefault::getBoolForKey(const char *pKey, bool defaultValue)
{
    const char *value = getValueForKey(pKey);

    bool ret = defaultValue;

    if (value)
    {
        ret = (!strcmp(value, "true"));
    }

    return ret;
}


int CCUserDefault::getIntegerForKey(const char *pKey, int defaultValue)
{
    const char *value = getValueForKey(pKey);

    int ret = defaultValue;

    if (value)
    {
        ret = atoi(value);
    }

    return ret;
}


float CCUserDefault::getFloatForKey(const char *pKey, float defaultValue)
{
    float ret = (float)getDoubleForKey(pKey, (double)defaultValue);

    return ret;
}


double CCUserDefault::getDoubleForKey(const char *pKey, double defaultValue)
{
    const char *value = getValueForKey(pKey);

    double ret = defaultValue;

    if (value)
    {
        ret = atof(value);
    }

    return ret;
}


const char *CCUserDefault::getStringForKey(const char *pKey, const char *defaultValue)
{
    const char *value = getValueForKey(pKey);

    if (!value)
    {
        value = defaultValue;
    }

    return value;
}


void CCUserDefault::setBoolForKey(const char *pKey, bool value)
{
    // save bool value as string

    if (true == value)
    {
        setStringForKey(pKey, "true");
    }
    else
    {
        setStringForKey(pKey, "false");
    }
}


void CCUserDefault::setIntegerForKey(const char *pKey, int value)
{
    // check key
    if (!pKey)
    {
        return;
    }

    // format the value
    char tmp[50];
    memset(tmp, 0, 50);
    sprintf(tmp, "%d", value);

    setValueForKey(pKey, tmp);
}


void CCUserDefault::setFloatForKey(const char *pKey, float value)
{
    setDoubleForKey(pKey, value);
}


void CCUserDefault::setDoubleForKey(const char *pKey, double value)
{
    // check key
    if (!pKey)
    {
        return;
    }

    // format the value
    char tmp[50];
    memset(tmp, 0, 50);
    sprintf(tmp, "%f", value);

    setValueForKey(pKey, tmp);
}


void CCUserDefault::setStringForKey(const char *pKey, const char *value)
{
    // check key
    if (!pKey)
    {
        return;
    }

    setValueForKey(pKey, value);
}


CCUserDefault *CCUserDefault::sharedUserDefault()
{
    initXMLFilePath();

    if (!m_spUserDefault)
    {
        m_spUserDefault = new CCUserDefault();
    }

    // only create xml file one time
    // the file exists after the program exit
    if ((!m_spUserDefault->isXMLFileExist()) && (!m_spUserDefault->createXMLFile()))
    {
        return NULL;
    }

    return m_spUserDefault;
}


bool CCUserDefault::isXMLFileExist()
{
    FILE *fp  = fopen(m_sFilePath.c_str(), "r");
    bool bRet = false;

    if (fp)
    {
        bRet = true;
        fclose(fp);
    }

    return bRet;
}


void CCUserDefault::initXMLFilePath()
{
    if (!m_sbIsFilePathInitialized)
    {
        m_sFilePath += CCFileUtils::sharedFileUtils()->getWriteablePath() + LoomApplicationConfig::applicationId().c_str() + XML_FILE_NAME;
        m_sbIsFilePathInitialized = true;
    }
}


// create new xml file
bool CCUserDefault::createXMLFile()
{
    bool bRet = false;
    tinyxml2::XMLDocument *pDoc = m_document;

    if (NULL == pDoc)
    {
        // no deletion because pDoc is null :)
        return false;
    }
    tinyxml2::XMLDeclaration *pDeclaration = pDoc->NewDeclaration("1.0");
    if (NULL == pDeclaration)
    {
        delete pDoc;
        return false;
    }
    pDoc->LinkEndChild(pDeclaration);
    tinyxml2::XMLElement *pRootEle = pDoc->NewElement(USERDEFAULT_ROOT_NAME);
    if (NULL == pRootEle)
    {
        delete pDoc;
        return false;
    }
    pDoc->LinkEndChild(pRootEle);
    bRet = tinyxml2::XML_SUCCESS == pDoc->SaveFile(m_sFilePath.c_str());

    return bRet;
}


const string& CCUserDefault::getXMLFilePath()
{
    return m_sFilePath;
}


void CCUserDefault::flush()
{
}


tinyxml2::XMLElement *CCUserDefault::getXMLNodeForKey(const char *pKey)
{
    tinyxml2::XMLElement *curNode = NULL;

    // check the key value
    if (!pKey)
    {
        return NULL;
    }

    // See if we have the file.
    tinyxml2::XMLDocument *xmlDoc = sharedUserDefault()->m_document;
    if(xmlDoc && xmlDoc->RootElement())
    {
        // find the node
        return xmlDoc->RootElement()->FirstChildElement(pKey);
    }
    
    do
    {
        unsigned long         nSize;
        const char            *pXmlBuffer = (const char *)CCFileUtils::sharedFileUtils()->getFileData(sharedUserDefault()->getXMLFilePath().c_str(), "rb", &nSize);
        if (NULL == pXmlBuffer)
        {
            CCLOG("can not read xml file");
            break;
        }
        xmlDoc->Parse(pXmlBuffer);
        // get root node
        if (NULL == xmlDoc->RootElement())
        {
            CCLOG("read root node error");
            break;
        }
        // find the node
        curNode = xmlDoc->RootElement()->FirstChildElement(pKey);
    } while (0);

    return curNode;
}


void CCUserDefault::setValueForKey(const char *pKey, const char *pValue)
{
    tinyxml2::XMLElement  *node;

    // check the params
    if (!pKey || !pValue)
    {
        return;
    }
    // find the node
    node = getXMLNodeForKey(pKey);
    
    // if node exist, change the content
    if (node)
    {
        // If no first child, create one.
        if (!node->FirstChild())
        {
            node->LinkEndChild(sharedUserDefault()->m_document->NewText(pValue));
        }
        else
        {
            node->FirstChild()->SetValue(pValue);
        }
    }
    else
    {
        if (sharedUserDefault()->m_document->RootElement())
        {
            tinyxml2::XMLElement *tmpNode = sharedUserDefault()->m_document->NewElement(pKey);
            sharedUserDefault()->m_document->RootElement()->LinkEndChild(tmpNode);
            tinyxml2::XMLText *content = sharedUserDefault()->m_document->NewText(pValue);
            tmpNode->LinkEndChild(content);
        }
    }


    // save file and free doc
    if (sharedUserDefault()->m_document)
    {
        sharedUserDefault()->m_document->SaveFile(CCUserDefault::sharedUserDefault()->getXMLFilePath().c_str());
    }
}


const char *CCUserDefault::getValueForKey(const char *pKey)
{
    const char           *value = NULL;
    tinyxml2::XMLElement *node = getXMLNodeForKey(pKey);

    // find the node
    if (node && node->FirstChild())
    {
        value = (const char *)(node->FirstChild()->Value());
    }

    return value;
}


NS_CC_END
