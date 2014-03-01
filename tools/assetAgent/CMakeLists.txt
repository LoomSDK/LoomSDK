project(assetAgent)

include_directories( ${LOOM_INCLUDE_FOLDERS} )

set (MAINDEMO_SRC
    src/main.cpp
)

set (MAINDEMO_HDR

)


set(CMAKE_OSX_ARCHITECTURES "x86_64")

# We are generating a library for Ruby to load via FFI, and CMake says
# this should be a MODULE not SHARED; see
# http://stackoverflow.com/questions/4845984/difference-between-modules-and-shared-libraries
add_library(${PROJECT_NAME} MODULE ${MAINDEMO_HDR} ${MAINDEMO_SRC})

if (APPLE)
    target_link_libraries(${PROJECT_NAME} 
       LoomVendor
       LoomCommon
       "-framework CoreFoundation"
       "-framework Cocoa"
       "-framework OpenGL"
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
	
	get_target_property(ASSETAGENTBIN ${PROJECT_NAME} LOCATION)
	
    add_custom_command(TARGET ${PROJECT_NAME}
        POST_BUILD
        COMMAND echo f | xcopy /F /Y \"${ASSETAGENTBIN}\" \"${CMAKE_SOURCE_DIR}/artifacts/assetAgent.dll\"
    )
	

endif()

if (LOOM_BUILD_JIT EQUAL 1)
    target_link_libraries(${PROJECT_NAME} ${LOOM_LUAJIT_LIB})
endif()
