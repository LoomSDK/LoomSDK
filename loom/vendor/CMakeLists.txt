if(NOT LOOM_BUILD_IOS EQUAL 1)
    set(CMAKE_OSX_ARCHITECTURES "i386;x86_64")
endif()

project(LoomVendor)

include_directories(
    ${LOOM_INCLUDE_FOLDERS}
    telemetry-01052012/include
    chipmunk-physics/include/chipmunk
    jemalloc-3.4.0/include
    openal-soft/include
    openal-soft/OpenAL32/Include
    minimp3
)

add_definitions(-DCURL_STATICLIB)
add_definitions(-DCURL_DISABLE_LDAP=1)

set (LIBCURL_SRC

    libcurl/src/amigaos.c
    libcurl/src/asyn-ares.c
    libcurl/src/asyn-thread.c
    libcurl/src/axtls.c
    libcurl/src/base64.c
    libcurl/src/bundles.c
    libcurl/src/conncache.c
    libcurl/src/connect.c
    libcurl/src/content_encoding.c
    libcurl/src/cookie.c
    libcurl/src/curl_addrinfo.c
    libcurl/src/curl_darwinssl.c
    libcurl/src/curl_fnmatch.c
    libcurl/src/curl_gethostname.c
    libcurl/src/curl_gssapi.c
    libcurl/src/curl_memrchr.c
    libcurl/src/curl_multibyte.c
    libcurl/src/curl_ntlm.c
    libcurl/src/curl_ntlm_core.c
    libcurl/src/curl_ntlm_msgs.c
    libcurl/src/curl_ntlm_wb.c
    libcurl/src/curl_rand.c
    libcurl/src/curl_rtmp.c
    libcurl/src/curl_sasl.c
    libcurl/src/curl_schannel.c
    libcurl/src/curl_sspi.c
    libcurl/src/curl_threads.c
    libcurl/src/cyassl.c
    libcurl/src/dict.c
    libcurl/src/easy.c
    libcurl/src/escape.c
    libcurl/src/file.c
    libcurl/src/fileinfo.c
    libcurl/src/formdata.c
    libcurl/src/ftp.c
    libcurl/src/ftplistparser.c
    libcurl/src/getenv.c
    libcurl/src/getinfo.c
    libcurl/src/gopher.c
    libcurl/src/gtls.c
    libcurl/src/hash.c
    libcurl/src/hmac.c
    libcurl/src/hostasyn.c
    libcurl/src/hostcheck.c
    libcurl/src/hostip.c
    libcurl/src/hostip4.c
    libcurl/src/hostip6.c
    libcurl/src/hostsyn.c
    libcurl/src/http.c
    libcurl/src/http_chunks.c
    libcurl/src/http_digest.c
    libcurl/src/http_negotiate.c
    libcurl/src/http_negotiate_sspi.c
    libcurl/src/http_proxy.c
    libcurl/src/idn_win32.c
    libcurl/src/if2ip.c
    libcurl/src/imap.c
    libcurl/src/inet_ntop.c
    libcurl/src/inet_pton.c
    libcurl/src/krb4.c
    libcurl/src/krb5.c
    libcurl/src/ldap.c
    libcurl/src/llist.c
    libcurl/src/md4.c
    libcurl/src/md5.c
    libcurl/src/memdebug.c
    libcurl/src/mprintf.c
    libcurl/src/multi.c
    libcurl/src/netrc.c
    libcurl/src/non-ascii.c
    libcurl/src/nonblock.c
    libcurl/src/nss.c
    libcurl/src/nwlib.c
    libcurl/src/nwos.c
    libcurl/src/openldap.c
    libcurl/src/parsedate.c
    libcurl/src/pingpong.c
    libcurl/src/pipeline.c
    libcurl/src/polarssl.c
    libcurl/src/polarssl_threadlock.c
    libcurl/src/pop3.c
    libcurl/src/progress.c
    libcurl/src/qssl.c
    libcurl/src/rawstr.c
    libcurl/src/rtsp.c
    libcurl/src/security.c
    libcurl/src/select.c
    libcurl/src/sendf.c
    libcurl/src/share.c
    libcurl/src/slist.c
    libcurl/src/smtp.c
    libcurl/src/socks.c
    libcurl/src/socks_gssapi.c
    libcurl/src/socks_sspi.c
    libcurl/src/speedcheck.c
    libcurl/src/splay.c
    libcurl/src/ssh.c
    libcurl/src/sslgen.c
    libcurl/src/ssluse.c
    libcurl/src/strdup.c
    libcurl/src/strequal.c
    libcurl/src/strerror.c
    libcurl/src/strtok.c
    libcurl/src/strtoofft.c
    libcurl/src/telnet.c
    libcurl/src/tftp.c
    libcurl/src/timeval.c
    libcurl/src/transfer.c
    libcurl/src/url.c
    libcurl/src/version.c
    libcurl/src/warnless.c
    libcurl/src/wildcard.c

)

set (LIBCURL_HDR

    libcurl/src/amigaos.h
    libcurl/src/arpa_telnet.h
    libcurl/src/asyn.h
    libcurl/src/axtls.h
    libcurl/src/bundles.h
    libcurl/src/config-amigaos.h
    libcurl/src/config-dos.h
    libcurl/src/config-mac.h
    libcurl/src/config-os400.h
    libcurl/src/config-riscos.h
    libcurl/src/config-symbian.h
    libcurl/src/config-tpf.h
    libcurl/src/config-vxworks.h
    libcurl/src/config-win32.h
    libcurl/src/config-win32ce.h
    libcurl/src/conncache.h
    libcurl/src/connect.h
    libcurl/src/content_encoding.h
    libcurl/src/cookie.h
    libcurl/src/curl_addrinfo.h
    libcurl/src/curl_base64.h
    libcurl/src/curl_darwinssl.h
    libcurl/src/curl_fnmatch.h
    libcurl/src/curl_gethostname.h
    libcurl/src/curl_gssapi.h
    libcurl/src/curl_hmac.h
    libcurl/src/curl_ldap.h
    libcurl/src/curl_md4.h
    libcurl/src/curl_md5.h
    libcurl/src/curl_memory.h
    libcurl/src/curl_memrchr.h
    libcurl/src/curl_multibyte.h
    libcurl/src/curl_ntlm.h
    libcurl/src/curl_ntlm_core.h
    libcurl/src/curl_ntlm_msgs.h
    libcurl/src/curl_ntlm_wb.h
    libcurl/src/curl_rand.h
    libcurl/src/curl_rtmp.h
    libcurl/src/curl_sasl.h
    libcurl/src/curl_schannel.h
    libcurl/src/curl_setup.h
    libcurl/src/curl_setup_once.h
    libcurl/src/curl_sspi.h
    libcurl/src/curl_threads.h
    libcurl/src/curlx.h
    libcurl/src/cyassl.h
    libcurl/src/dict.h
    libcurl/src/easyif.h
    libcurl/src/escape.h
    libcurl/src/file.h
    libcurl/src/fileinfo.h
    libcurl/src/formdata.h
    libcurl/src/ftp.h
    libcurl/src/ftplistparser.h
    libcurl/src/getinfo.h
    libcurl/src/gopher.h
    libcurl/src/gtls.h
    libcurl/src/hash.h
    libcurl/src/hostcheck.h
    libcurl/src/hostip.h
    libcurl/src/http.h
    libcurl/src/http_chunks.h
    libcurl/src/http_digest.h
    libcurl/src/http_negotiate.h
    libcurl/src/http_proxy.h
    libcurl/src/if2ip.h
    libcurl/src/imap.h
    libcurl/src/inet_ntop.h
    libcurl/src/inet_pton.h
    libcurl/src/krb4.h
    libcurl/src/llist.h
    libcurl/src/memdebug.h
    libcurl/src/multihandle.h
    libcurl/src/multiif.h
    libcurl/src/netrc.h
    libcurl/src/non-ascii.h
    libcurl/src/nonblock.h
    libcurl/src/nssg.h
    libcurl/src/parsedate.h
    libcurl/src/pingpong.h
    libcurl/src/pipeline.h
    libcurl/src/polarssl.h
    libcurl/src/polarssl_threadlock.h
    libcurl/src/pop3.h
    libcurl/src/progress.h
    libcurl/src/qssl.h
    libcurl/src/rawstr.h
    libcurl/src/rtsp.h
    libcurl/src/select.h
    libcurl/src/sendf.h
    libcurl/src/setup-os400.h
    libcurl/src/setup-vms.h
    libcurl/src/share.h
    libcurl/src/slist.h
    libcurl/src/smtp.h
    libcurl/src/sockaddr.h
    libcurl/src/socks.h
    libcurl/src/speedcheck.h
    libcurl/src/splay.h
    libcurl/src/ssh.h
    libcurl/src/sslgen.h
    libcurl/src/ssluse.h
    libcurl/src/strdup.h
    libcurl/src/strequal.h
    libcurl/src/strerror.h
    libcurl/src/strtok.h
    libcurl/src/strtoofft.h
    libcurl/src/telnet.h
    libcurl/src/tftp.h
    libcurl/src/timeval.h
    libcurl/src/transfer.h
    libcurl/src/url.h
    libcurl/src/urldata.h
    libcurl/src/warnless.h
    libcurl/src/wildcard.h

)


set (CHIPMUNK_SRC

    chipmunk-physics/src/chipmunk.c
    chipmunk-physics/src/cpArbiter.c
    chipmunk-physics/src/cpArray.c
    chipmunk-physics/src/cpBB.c
    chipmunk-physics/src/cpBBTree.c
    chipmunk-physics/src/cpBody.c
    chipmunk-physics/src/cpCollision.c
    chipmunk-physics/src/cpHashSet.c
    chipmunk-physics/src/cpPolyShape.c
    chipmunk-physics/src/cpShape.c
    chipmunk-physics/src/cpSpace.c
    chipmunk-physics/src/cpSpaceComponent.c
    chipmunk-physics/src/cpSpaceHash.c
    chipmunk-physics/src/cpSpaceQuery.c
    chipmunk-physics/src/cpSpaceStep.c
    chipmunk-physics/src/cpSpatialIndex.c
    chipmunk-physics/src/cpSweep1D.c
    chipmunk-physics/src/cpVect.c
    
    chipmunk-physics/src/constraints/cpConstraint.c
    chipmunk-physics/src/constraints/cpDampedRotarySpring.c
    chipmunk-physics/src/constraints/cpDampedSpring.c
    chipmunk-physics/src/constraints/cpGearJoint.c
    chipmunk-physics/src/constraints/cpGrooveJoint.c
    chipmunk-physics/src/constraints/cpPinJoint.c
    chipmunk-physics/src/constraints/cpPivotJoint.c
    chipmunk-physics/src/constraints/cpRatchetJoint.c
    chipmunk-physics/src/constraints/cpRotaryLimitJoint.c
    chipmunk-physics/src/constraints/cpSimpleMotor.c
    chipmunk-physics/src/constraints/cpSlideJoint.c

)

set (CHIPMUNK_HDR

    chipmunk-physics/src/prime.h
    
    chipmunk-physics/include/chipmunk/chipmunk.h
    chipmunk-physics/include/chipmunk/chipmunk_ffi.h
    chipmunk-physics/include/chipmunk/chipmunk_private.h
    chipmunk-physics/include/chipmunk/chipmunk_types.h
    chipmunk-physics/include/chipmunk/chipmunk_unsafe.h
    chipmunk-physics/include/chipmunk/cpArbiter.h
    chipmunk-physics/include/chipmunk/cpBB.h
    chipmunk-physics/include/chipmunk/cpBody.h
    chipmunk-physics/include/chipmunk/cpPolyShape.h
    chipmunk-physics/include/chipmunk/cpShape.h
    chipmunk-physics/include/chipmunk/cpSpace.h
    chipmunk-physics/include/chipmunk/cpSpatialIndex.h
    chipmunk-physics/include/chipmunk/cpVect.h
    
    chipmunk-physics/include/chipmunk/constraints/cpConstraint.h
    chipmunk-physics/include/chipmunk/constraints/cpDampedRotarySpring.h
    chipmunk-physics/include/chipmunk/constraints/cpDampedSpring.h
    chipmunk-physics/include/chipmunk/constraints/cpGearJoint.h
    chipmunk-physics/include/chipmunk/constraints/cpGrooveJoint.h
    chipmunk-physics/include/chipmunk/constraints/cpPinJoint.h
    chipmunk-physics/include/chipmunk/constraints/cpPivotJoint.h
    chipmunk-physics/include/chipmunk/constraints/cpRatchetJoint.h
    chipmunk-physics/include/chipmunk/constraints/cpRotaryLimitJoint.h
    chipmunk-physics/include/chipmunk/constraints/cpSimpleMotor.h
    chipmunk-physics/include/chipmunk/constraints/cpSlideJoint.h
    chipmunk-physics/include/chipmunk/constraints/util.h

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
    stb/stb_truetype.h
)

set (STB_SRC
    stb/stb_image.c
    stb/stb_vorbis.c
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

set( JHEADEXIF_SRC jheadexif/exif.c jheadexif/jhead.c jheadexif/jpgfile.c jheadexif/easyexif.cpp)
    



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


SET_SOURCE_FILES_PROPERTIES( ${CHIPMUNK_SRC} PROPERTIES LANGUAGE CXX)

set (ALL_FILES 
    ${JHEADEXIF_SRC}
    ${SEATEST_HDR} ${SEATEST_SRC} 
    ${STB_HDR} ${STB_SRC} 
    ${JANSSON_HDR} ${JANSSON_SRC} 
    ${CHIPMUNK_HDR} ${CHIPMUNK_SRC} 
    ${LUA_HDR} ${LUA_SRC} 
    ${GLEW_HDR} ${GLEW_SRC}
    ${GELDREICH_HDR} ${GELDREICH_SRC}
    ${JEMALLOC_SRC}
    ${OPENALSOFT_SRC}
    ${MINIMP3_SRC}
)

if (MSVC)
    include_directories( libcurl/include/curl libcurl/include)

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

