project(assetAgent)

include_directories(
    ${LOOM_INCLUDE_FOLDERS}
    include/
    vendor/civetweb/include
)

add_definitions(-DUSE_WEBSOCKET)

set (AGENT_SRC
    src/main.cpp
    src/telemetryServer.cpp
    vendor/civetweb/src/civetweb.c
)

set (AGENT_HDR
    vendor/civetweb/include/civetweb.h
)

# We are generating a library for Ruby to load via FFI, and CMake says
# this should be a MODULE not SHARED; see
# http://stackoverflow.com/questions/4845984/difference-between-modules-and-shared-libraries
add_library(${PROJECT_NAME} MODULE ${AGENT_HDR} ${AGENT_SRC})

if (APPLE)

    target_link_libraries(${PROJECT_NAME} 
       LoomVendor
       LoomCommon
       "-framework CoreFoundation"
       "-framework Cocoa"
       "-framework OpenGL"
       # zlib library required by utByteArray
       "-lz"
    )

    set_target_properties(${PROJECT_NAME} PROPERTIES
      XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT "dwarf-with-dsym"
      XCODE_ATTRIBUTE_INFOPLIST_PREPROCESS YES
    )

elseif(LINUX)

    target_link_libraries(${PROJECT_NAME} 
       LoomVendor
       LoomCommon
       LoomScript
       LoomCore
    )

elseif(MSVC)

    target_link_libraries(${PROJECT_NAME} 
       LoomVendor
       LoomCommon
       LoomScript
       LoomCore
       "kernel32" "advapi32" "COMCTL32" "COMDLG32" "USER32" "ADVAPI32" "GDI32" "WINMM" "WSOCK32" "Ws2_32" 
    )

    if (LOOM_TELEMETRY)
        target_link_libraries(${PROJECT_NAME} "telemetry32.link" "telemetry64.link")
    endif()

    set(ASSETAGENTBIN $<TARGET_FILE:${PROJECT_NAME}>)

    add_custom_command(TARGET ${PROJECT_NAME}
        POST_BUILD
        COMMAND echo f | xcopy /F /Y \"${ASSETAGENTBIN}\" \"${CMAKE_SOURCE_DIR}/artifacts/assetAgent.dll\"
    )

endif()

if (LOOM_BUILD_JIT EQUAL 1)
    target_link_libraries(${PROJECT_NAME} luajit)
endif()
