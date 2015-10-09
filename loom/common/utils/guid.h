//
//  guid.h
//  LoomEngine
//
//  Created by Dave Fishel on 12/23/14.
//
//

#ifndef __LoomEngine__guid__
#define __LoomEngine__guid__

typedef char loom_guid_t[37];

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
