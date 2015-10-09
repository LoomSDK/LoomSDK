//
//  guid.h
//  LoomEngine
//
//  Created by Dave Fishel on 12/23/14.
//
//

#ifndef _UTILS_GUID_H_
#define _UTILS_GUID_H_

#define LOOM_GUID_SIZE 37

typedef char loom_guid_t[LOOM_GUID_SIZE];

extern "C"
{
    /*
     
     Usage is super simple:
     
     loom_guid_t myGuid;
     loom_generate_guid(myGuid);
     printf("my guid: %s\n", myGuid);
     
     */
    void loom_generate_guid(loom_guid_t out_guid);
};

#endif
