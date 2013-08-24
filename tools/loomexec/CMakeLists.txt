project(loomexec)

include_directories( ${LOOM_INCLUDE_FOLDERS} )

# Command line loom script compiler.

set (LOOMEXEC_SRC ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp)

add_executable(loomexec ${LOOMEXEC_SRC})

get_target_property(LOOMEXECBIN loomexec LOCATION)

if (MSVC)
    target_link_libraries(loomexec
        LoomVendor
        LoomCommon
        LoomScript
        "kernel32" "advapi32" "COMCTL32" "COMDLG32" "USER32" "ADVAPI32" "GDI32" "WINMM" "OPENGL32" "WSOCK32" "Ws2_32" 
        ${CMAKE_SOURCE_DIR}/loom/vendor/zlib/lib/win32/zlibstatic.lib
    )

    add_custom_command(TARGET loomexec
        POST_BUILD
        COMMAND echo f | xcopy /F /Y \"${LOOMEXECBIN}\" \"${CMAKE_SOURCE_DIR}/artifacts/loomexec.exe\"
    )

else ()

	target_link_libraries(loomexec
	    LoomVendor 
	    LoomCommon 
	    LoomScript
	)

	add_custom_command(TARGET loomexec
    	POST_BUILD
    	COMMAND mkdir -p ${CMAKE_SOURCE_DIR}/artifacts
    	COMMAND cp ${LOOMEXECBIN} ${CMAKE_SOURCE_DIR}/artifacts/loomexec
	)


endif()


if (LOOM_BUILD_JIT EQUAL 1)

    target_link_libraries(loomexec ${LOOM_LUAJIT_LIB})

    if (LINUX)
        target_link_libraries(${PROJECT_NAME} -ldl)
    endif()

endif()

