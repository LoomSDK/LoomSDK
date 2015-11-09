if(NOT LOOM_BUILD_IOS EQUAL 1)
    set(CMAKE_OSX_ARCHITECTURES "i386;x86_64")
endif()

project(LoomVendor)

include_directories(
    ${LOOM_INCLUDE_FOLDERS}
    telemetry-01052012/include
    jemalloc-3.4.0/include
    openal-soft/include
    openal-soft/OpenAL32/Include
    minimp3
    nanosvg/src
    nanovg/src
    .
)

set(BOX2D_SRC

    box2d/Collision/b2BroadPhase.cpp
    box2d/Collision/b2CollideCircle.cpp
    box2d/Collision/b2CollideEdge.cpp
    box2d/Collision/b2CollidePolygon.cpp
    box2d/Collision/b2Collision.cpp
    box2d/Collision/b2Distance.cpp
    box2d/Collision/b2DynamicTree.cpp
    box2d/Collision/b2TimeOfImpact.cpp
    box2d/Collision/Shapes/b2CircleShape.cpp
    box2d/Collision/Shapes/b2EdgeShape.cpp
    box2d/Collision/Shapes/b2ChainShape.cpp
    box2d/Collision/Shapes/b2PolygonShape.cpp
    box2d/Common/b2BlockAllocator.cpp
    box2d/Common/b2Draw.cpp
    box2d/Common/b2Math.cpp
    box2d/Common/b2Settings.cpp
    box2d/Common/b2StackAllocator.cpp
    box2d/Common/b2Timer.cpp
    box2d/Dynamics/b2Body.cpp
    box2d/Dynamics/b2ContactManager.cpp
    box2d/Dynamics/b2Fixture.cpp
    box2d/Dynamics/b2Island.cpp
    box2d/Dynamics/b2World.cpp
    box2d/Dynamics/b2WorldCallbacks.cpp
    box2d/Dynamics/Contacts/b2CircleContact.cpp
    box2d/Dynamics/Contacts/b2Contact.cpp
    box2d/Dynamics/Contacts/b2ContactSolver.cpp
    box2d/Dynamics/Contacts/b2PolygonAndCircleContact.cpp
    box2d/Dynamics/Contacts/b2EdgeAndCircleContact.cpp
    box2d/Dynamics/Contacts/b2EdgeAndPolygonContact.cpp
    box2d/Dynamics/Contacts/b2ChainAndCircleContact.cpp
    box2d/Dynamics/Contacts/b2ChainAndPolygonContact.cpp
    box2d/Dynamics/Contacts/b2PolygonContact.cpp
    box2d/Dynamics/Joints/b2DistanceJoint.cpp
    box2d/Dynamics/Joints/b2FrictionJoint.cpp
    box2d/Dynamics/Joints/b2GearJoint.cpp
    box2d/Dynamics/Joints/b2Joint.cpp
    box2d/Dynamics/Joints/b2MotorJoint.cpp
    box2d/Dynamics/Joints/b2MouseJoint.cpp
    box2d/Dynamics/Joints/b2PrismaticJoint.cpp
    box2d/Dynamics/Joints/b2PulleyJoint.cpp
    box2d/Dynamics/Joints/b2RevoluteJoint.cpp
    box2d/Dynamics/Joints/b2RopeJoint.cpp
    box2d/Dynamics/Joints/b2WeldJoint.cpp
    box2d/Dynamics/Joints/b2WheelJoint.cpp
    box2d/Rope/b2Rope.cpp

)

set(BOX2D_HDR

    box2d/Collision/b2BroadPhase.h
    box2d/Collision/b2Collision.h
    box2d/Collision/b2Distance.h
    box2d/Collision/b2DynamicTree.h
    box2d/Collision/b2TimeOfImpact.h
    box2d/Collision/Shapes/b2CircleShape.h
    box2d/Collision/Shapes/b2EdgeShape.h
    box2d/Collision/Shapes/b2ChainShape.h
    box2d/Collision/Shapes/b2PolygonShape.h
    box2d/Collision/Shapes/b2Shape.h
    box2d/Common/b2BlockAllocator.h
    box2d/Common/b2Draw.h
    box2d/Common/b2GrowableStack.h
    box2d/Common/b2Math.h
    box2d/Common/b2Settings.h
    box2d/Common/b2StackAllocator.h
    box2d/Common/b2Timer.h
    box2d/Dynamics/b2Body.h
    box2d/Dynamics/b2ContactManager.h
    box2d/Dynamics/b2Fixture.h
    box2d/Dynamics/b2Island.h
    box2d/Dynamics/b2TimeStep.h
    box2d/Dynamics/b2World.h
    box2d/Dynamics/b2WorldCallbacks.h
    box2d/Dynamics/Contacts/b2CircleContact.h
    box2d/Dynamics/Contacts/b2Contact.h
    box2d/Dynamics/Contacts/b2ContactSolver.h
    box2d/Dynamics/Contacts/b2PolygonAndCircleContact.h
    box2d/Dynamics/Contacts/b2EdgeAndCircleContact.h
    box2d/Dynamics/Contacts/b2EdgeAndPolygonContact.h
    box2d/Dynamics/Contacts/b2ChainAndCircleContact.h
    box2d/Dynamics/Contacts/b2ChainAndPolygonContact.h
    box2d/Dynamics/Contacts/b2PolygonContact.h
    box2d/Dynamics/Joints/b2DistanceJoint.h
    box2d/Dynamics/Joints/b2FrictionJoint.h
    box2d/Dynamics/Joints/b2GearJoint.h
    box2d/Dynamics/Joints/b2Joint.h
    box2d/Dynamics/Joints/b2MotorJoint.h
    box2d/Dynamics/Joints/b2MouseJoint.h
    box2d/Dynamics/Joints/b2PrismaticJoint.h
    box2d/Dynamics/Joints/b2PulleyJoint.h
    box2d/Dynamics/Joints/b2RevoluteJoint.h
    box2d/Dynamics/Joints/b2RopeJoint.h
    box2d/Dynamics/Joints/b2WeldJoint.h
    box2d/Dynamics/Joints/b2WheelJoint.h
    box2d/Rope/b2Rope.h
    box2d/Box2D.h

)

add_definitions(-DCURL_STATICLIB)
add_definitions(-DCURL_DISABLE_LDAP=1)

file(GLOB LIBCURL_SRC

    libcurl/src/*.c
    libcurl/src/libcurl.rc
    libcurl/src/vtls/*.c

)

file(GLOB LIBCURL_HDR

    libcurl/src/*.h
    libcurl/src/vtls/*.h
)

set (JANSSONROOT ${CMAKE_CURRENT_SOURCE_DIR}/jansson)

set (JANSSON_SRC

    ${JANSSONROOT}/src/dump.c
    ${JANSSONROOT}/src/error.c
    ${JANSSONROOT}/src/hashtable.c
    ${JANSSONROOT}/src/load.c
    ${JANSSONROOT}/src/memory.c
    ${JANSSONROOT}/src/pack_unpack.c
    ${JANSSONROOT}/src/strbuffer.c
    ${JANSSONROOT}/src/strconv.c
    ${JANSSONROOT}/src/utf.c
    ${JANSSONROOT}/src/value.c

)

set (JANSSON_HDR

    ${JANSSONROOT}/jansson.h
    ${JANSSONROOT}/jansson_config.h
    ${JANSSONROOT}/src/hashtable.h
    ${JANSSONROOT}/src/jansson.h
    ${JANSSONROOT}/src/jansson_config.h
    ${JANSSONROOT}/src/jansson_private.h
    ${JANSSONROOT}/src/strbuffer.h
    ${JANSSONROOT}/src/utf.h

)

set (SEATEST_SRC
    
    seatest/seatest.c

)

set (SEATEST_HDR
    
    seatest/seatest.h

)

set (SMSLIB_SRC
    
    smslib/smslib.m

)

set (SMSLIB_HDR
    
    smslib/smslib.h

)


SET(LUAROOT lua/src)

if (LOOM_BUILD_JIT EQUAL 1) 

else()

set (LUA_SRC

    ${LUAROOT}/lapi.c
    ${LUAROOT}/lauxlib.c
    ${LUAROOT}/lbaselib.c
    ${LUAROOT}/lcode.c
    ${LUAROOT}/ldblib.c
    ${LUAROOT}/ldebug.c
    ${LUAROOT}/ldo.c
    ${LUAROOT}/ldump.c
    ${LUAROOT}/lfunc.c
    ${LUAROOT}/lgc.c
    ${LUAROOT}/linit.c
    ${LUAROOT}/liolib.c
    ${LUAROOT}/llex.c
    ${LUAROOT}/lmathlib.c
    ${LUAROOT}/lmem.c
    ${LUAROOT}/loadlib.c
    ${LUAROOT}/lobject.c
    ${LUAROOT}/lopcodes.c
    ${LUAROOT}/loslib.c
    ${LUAROOT}/lparser.c
    ${LUAROOT}/lstate.c
    ${LUAROOT}/lstring.c
    ${LUAROOT}/lstrlib.c
    ${LUAROOT}/ltable.c
    ${LUAROOT}/ltablib.c
    ${LUAROOT}/ltm.c
    ${LUAROOT}/lundump.c
    ${LUAROOT}/lvm.c
    ${LUAROOT}/lzio.c
    ${LUAROOT}/print.c

)

set (LUA_HDR

    ${LUAROOT}/lapi.h
    ${LUAROOT}/lauxlib.h
    ${LUAROOT}/lcode.h
    ${LUAROOT}/ldebug.h
    ${LUAROOT}/ldo.h
    ${LUAROOT}/lfunc.h
    ${LUAROOT}/lgc.h
    ${LUAROOT}/llex.h
    ${LUAROOT}/llimits.h
    ${LUAROOT}/lmem.h
    ${LUAROOT}/lobject.h
    ${LUAROOT}/lopcodes.h
    ${LUAROOT}/lparser.h
    ${LUAROOT}/lstate.h
    ${LUAROOT}/lstring.h
    ${LUAROOT}/ltable.h
    ${LUAROOT}/ltm.h
    ${LUAROOT}/lua.h
    ${LUAROOT}/luaconf.h
    ${LUAROOT}/lualib.h
    ${LUAROOT}/lundump.h
    ${LUAROOT}/lua.hpp
    ${LUAROOT}/lvm.h
    ${LUAROOT}/lzio.h

)

endif()

set (STB_HDR
    stb/stb_gl.h
    stb/stb_image.h
    stb/stb_image_write.h
    stb/stb_truetype.h
)

set (STB_SRC
    stb/stb_image.cpp
    stb/stb_vorbis.c
)

set (JPGD_HDR
    jpgd/jpgd.h
)

set (JPGD_SRC
    jpgd/jpgd.cpp
)

set (GELDREICH_HDR

    geldreich/jpge.h
    geldreich/resampler.h

)

set (GELDREICH_SRC

    geldreich/jpge.cpp
    geldreich/resampler.cpp

)


set (JEMALLOC_ROOT jemalloc-3.4.0)

set (JEMALLOC_SRC
    ${JEMALLOC_ROOT}/src/arena.c
    ${JEMALLOC_ROOT}/src/atomic.c
    ${JEMALLOC_ROOT}/src/base.c
    ${JEMALLOC_ROOT}/src/bitmap.c
    ${JEMALLOC_ROOT}/src/chunk.c
    ${JEMALLOC_ROOT}/src/chunk_dss.c
    ${JEMALLOC_ROOT}/src/chunk_mmap.c
    ${JEMALLOC_ROOT}/src/ckh.c
    ${JEMALLOC_ROOT}/src/ctl.c
    ${JEMALLOC_ROOT}/src/extent.c
    ${JEMALLOC_ROOT}/src/hash.c
    ${JEMALLOC_ROOT}/src/huge.c
    ${JEMALLOC_ROOT}/src/jemalloc.c
    ${JEMALLOC_ROOT}/src/mb.c
    ${JEMALLOC_ROOT}/src/mutex.c
    ${JEMALLOC_ROOT}/src/prof.c
    ${JEMALLOC_ROOT}/src/quarantine.c
    ${JEMALLOC_ROOT}/src/rtree.c
    ${JEMALLOC_ROOT}/src/stats.c
    ${JEMALLOC_ROOT}/src/tcache.c
    ${JEMALLOC_ROOT}/src/tsd.c
    ${JEMALLOC_ROOT}/src/util.c
    ${JEMALLOC_ROOT}/src/zone.c
)

set(OPENALSOFT_ROOT openal-soft)
set(OPENALSOFT_SRC
    ${OPENALSOFT_ROOT}/Alc/backends/wave.c
    ${OPENALSOFT_ROOT}/Alc/backends/null.c
    ${OPENALSOFT_ROOT}/Alc/backends/loopback.c
    ${OPENALSOFT_ROOT}/Alc/ALc.c
    ${OPENALSOFT_ROOT}/Alc/alcConfig.c
    ${OPENALSOFT_ROOT}/Alc/alcDedicated.c
    ${OPENALSOFT_ROOT}/Alc/alcEcho.c
    ${OPENALSOFT_ROOT}/Alc/alcModulator.c
    ${OPENALSOFT_ROOT}/Alc/alcReverb.c
    ${OPENALSOFT_ROOT}/Alc/alcRing.c
    ${OPENALSOFT_ROOT}/Alc/alcThread.c
    ${OPENALSOFT_ROOT}/Alc/ALu.cpp
    ${OPENALSOFT_ROOT}/Alc/bs2b.c
    ${OPENALSOFT_ROOT}/Alc/helpers.c
    ${OPENALSOFT_ROOT}/Alc/hrtf.c
    ${OPENALSOFT_ROOT}/Alc/mixer.c
    ${OPENALSOFT_ROOT}/Alc/panning.c
    ${OPENALSOFT_ROOT}/OpenAL32/alAuxEffectSlot.c
    ${OPENALSOFT_ROOT}/OpenAL32/alBuffer.c
    ${OPENALSOFT_ROOT}/OpenAL32/alEffect.c
    ${OPENALSOFT_ROOT}/OpenAL32/alError.c
    ${OPENALSOFT_ROOT}/OpenAL32/alExtension.c
    ${OPENALSOFT_ROOT}/OpenAL32/alFilter.c
    ${OPENALSOFT_ROOT}/OpenAL32/alListener.c
    ${OPENALSOFT_ROOT}/OpenAL32/alSource.c
    ${OPENALSOFT_ROOT}/OpenAL32/alState.c
    ${OPENALSOFT_ROOT}/OpenAL32/alThunk.c
)

if(APPLE)
    set(OPENALSOFT_SRC
        ${OPENALSOFT_SRC}
        ${OPENALSOFT_ROOT}/Alc/backends/coreaudio.c
    )
endif()

if(ANDROID)
    set(OPENALSOFT_SRC
        ${OPENALSOFT_SRC}
        ${OPENALSOFT_ROOT}/Alc/backends/android.cpp
    )
endif()

if(MSVC)
    set(OPENALSOFT_SRC
        ${OPENALSOFT_SRC}
        ${OPENALSOFT_ROOT}/Alc/backends/dsound.c
    )
endif()

set(MINIMP3_ROOT minimp3)
set(MINIMP3_SRC
    ${MINIMP3_ROOT}/minimp3.c
)

set(ZLIB_HDR
    zlib/include/zconf.h
    zlib/include/zlib.h
    zlib/include/crc32.h
    zlib/include/deflate.h
    zlib/include/gzguts.h
    zlib/include/inffast.h
    zlib/include/inffixed.h
    zlib/include/inflate.h
    zlib/include/inftrees.h
    zlib/include/trees.h
    zlib/include/zutil.h
)

set(ZLIB_SRC
    zlib/source/adler32.c
    zlib/source/compress.c
    zlib/source/crc32.c
    zlib/source/deflate.c
    zlib/source/gzclose.c
    zlib/source/gzlib.c
    zlib/source/gzread.c
    zlib/source/gzwrite.c
    zlib/source/inflate.c
    zlib/source/infback.c
    zlib/source/inftrees.c
    zlib/source/inffast.c
    zlib/source/trees.c
    zlib/source/uncompr.c
    zlib/source/zutil.c
)

set(SQLITE3_SRC 
    sqlite3/sqlite3.c
)

set( JHEADEXIF_SRC jheadexif/exif.c jheadexif/jhead.c jheadexif/jpgfile.c jheadexif/easyexif.cpp)

set (NANOVG_HDR
  nanovg/src/fontstash.h
  nanovg/src/nanovg.h
  nanovg/src/nanovg_lm_gl.h
  nanovg/src/nanovg_lm_gl_utils.h
)
set (NANOVG_SRC nanovg/src/nanovg.c)

set (NANOSVG_HDR
  nanosvg/src/nanosvg.h
  nanosvg/src/nanosvgrast.h
)

if (MSVC)

    set (GLEW_HDR )
    set (GLEW_SRC )

    # Enable SSL
    add_definitions(-DUSE_WINDOWS_SSPI=1 -DUSE_SCHANNEL=1)
    add_definitions(-D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE)

elseif(APPLE)
    if (LOOM_BUILD_IOS EQUAL 1)
        set (GLEW_HDR)
        set (GLEW_SRC)
    else()
        set (GLEW_HDR

            glew-1.7.0/include/GL/glew.h
            glew-1.7.0/include/GL/glxew.h
            glew-1.7.0/include/GL/wglew.h

        )

        set (GLEW_SRC
           glew-1.7.0/src/glew.c
        )    
    endif()
else()
    set (GLEW_HDR)
    set (GLEW_SRC)
endif()


SET_SOURCE_FILES_PROPERTIES( PROPERTIES LANGUAGE CXX)

set (ALL_FILES
    ${BOX2D_HDR} ${BOX2D_SRC}
    ${JHEADEXIF_SRC}
    ${SEATEST_HDR} ${SEATEST_SRC} 
    ${STB_HDR} ${STB_SRC} 
    ${JPGD_HDR} ${JPGD_SRC} 
    ${JANSSON_HDR} ${JANSSON_SRC} 
    ${LUA_HDR} ${LUA_SRC} 
    ${GLEW_HDR} ${GLEW_SRC}
    ${GELDREICH_HDR} ${GELDREICH_SRC}
    ${JEMALLOC_SRC}
    ${OPENALSOFT_SRC}
    ${MINIMP3_SRC}
    ${NANOVG_HDR} ${NANOVG_SRC}
    ${NANOSVG_HDR}
    ${SQLITE3_SRC}
)

if (MSVC)
    include_directories( libcurl/include/curl libcurl/include libcurl/src)

    list (APPEND ALL_FILES 
        ${LIBCURL_HDR} ${LIBCURL_SRC} 
    )

    list (APPEND ALL_FILES 
        ${ZLIB_SRC} ${ZLIB_HDR} 
    )

endif()

if (APPLE)
    list (APPEND ALL_FILES 
        ${SMSLIB_HDR} ${SMSLIB_SRC} 
    )
endif()

add_library(${PROJECT_NAME} ${ALL_FILES})

