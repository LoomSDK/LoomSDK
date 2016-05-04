/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

extern "C"
{

#include "loom/common/platform/platform.h"
#if LOOM_PLATFORM_IS_APPLE == 1
#import "Foundation/Foundation.h"

const char* platform_getResourceDirectory() 
{    
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];    
    
    static char path[1024];
    
    NSFileManager *filemgr;
    const char *cString;
    
    filemgr =[NSFileManager defaultManager];
    
    cString = [resourcePath UTF8String];    
    
    strcpy(path, cString);
    
    return path;    
}

const char* platform_getWorkingDirectory() {
    
    static char path[1024];
    
    const char *cString;
    NSFileManager *filemgr;
    NSString *currentPath;
    
    filemgr =[NSFileManager defaultManager];
    currentPath = [filemgr currentDirectoryPath];
    [filemgr release];
    
    cString = [currentPath UTF8String];    
    strcpy(path, cString);
    
    [currentPath release];
    
    return path;
    
}

void platform_changeDirectoryDocuments() {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];    
    
    if ([fileManager changeCurrentDirectoryPath: documentsDirectory] == NO)
    {
        // Directory does not exist Ð take appropriate action
        NSLog(@"Unabled to change directory");
    }
    
}

void platform_changeDirectory(const char* folder) {
    
    NSFileManager* filemgr =[NSFileManager defaultManager];
    
    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];        
    
    resourcePath = [resourcePath stringByAppendingString:@"/assets"];
    
    NSLog(@"%@", resourcePath);
    
    if ([filemgr changeCurrentDirectoryPath: resourcePath] == NO)
    {
        // Directory does not exist Ð take appropriate action
        NSLog(@"Unabled to change directory");
    }
    
    [filemgr release];    
}



#if LOOM_PLATFORM == LOOM_PLATFORM_OSX

/**
@brief   Get the writeable path
@return  The path that can write/read file
*/
const char* platform_getWritablePath() 
{    

    static char path[1024];
    // save to document folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (paths) 
    {
        NSString *documentsDirectory = [paths objectAtIndex:0];
        if (documentsDirectory)
        {
            snprintf(path, 1023, "%s", [documentsDirectory UTF8String]);    
            return path;
        }
    }

    return "";

}
    
const char* platform_getSettingsPath(const char *appName)
{
    
    static char path[1024];
    // save to document folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if (paths)
    {
        NSString *appSupportDirectory = [paths objectAtIndex:0];
        if (appSupportDirectory)
        {
            snprintf(path, 1023, "%s/%s/", [appSupportDirectory UTF8String], appName);
            return path;
        }
    }
    
    return "";

}


#elif LOOM_PLATFORM == LOOM_PLATFORM_IOS

const char* platform_getWritablePath()
{
    static char path[1024];

    // save to caches folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

    if (paths) 
    {
        NSString *documentsDirectory = [paths objectAtIndex:0];
        snprintf(path, 1023, "%s", [documentsDirectory UTF8String]);    
        return path;
    }

    return "";
}

#endif

#endif

}