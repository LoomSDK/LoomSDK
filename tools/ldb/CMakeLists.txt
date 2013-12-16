project(ldb)

include_directories( ${LOOM_INCLUDE_FOLDERS} )

# COMMAND LINE LDB

set (LDB_SRC 

    ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp

)

set (LDB_HDR 

)
    
add_executable(ldb 
    
    ${LDB_HDR} ${LDB_SRC}
    
)
    

if (MSVC)

   target_link_libraries(ldb
    LoomVendor
    LoomCommon
    LoomScript
    LoomCore
    "kernel32" "advapi32" "COMCTL32" "COMDLG32" "USER32" "ADVAPI32" "GDI32" "WINMM" "OPENGL32" "WSOCK32" "Ws2_32" 
    )
	
	get_target_property(LDBBIN ldb LOCATION)
	
    add_custom_command(TARGET ${PROJECT_NAME}
        POST_BUILD
        COMMAND echo f | xcopy /F /Y \"${LDBBIN}\" \"${CMAKE_SOURCE_DIR}/artifacts/ldb.exe\"
    )	
    
else ()
   target_link_libraries(ldb
       LoomVendor
       LoomCommon
       LoomScript
       LoomCore
   )
   get_target_property(LDBBIN ldb LOCATION)
     
    add_custom_command(TARGET ldb
        POST_BUILD
        COMMAND mkdir -p ${CMAKE_SOURCE_DIR}/artifacts
        COMMAND cp ${LDBBIN} ${CMAKE_SOURCE_DIR}/artifacts/ldb
    )

endif(MSVC)

if (LOOM_BUILD_JIT EQUAL 1)
    target_link_libraries(ldb ${LOOM_LUAJIT_LIB})

    if (LINUX)
        target_link_libraries(${PROJECT_NAME} -ldl)
    endif()
    
endif()

