project(loomexec)

include_directories( ${LOOM_INCLUDE_FOLDERS} )

# Command line loom script compiler.

set (LOOMEXEC_SRC ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp)

add_executable(loomexec ${LOOMEXEC_SRC})

set(LOOMEXECBIN $<TARGET_FILE:${PROJECT_NAME}>)

if (MSVC)
    target_link_libraries(loomexec
        LoomVendor
        LoomCommon
        LoomScript
        "kernel32" "advapi32" "COMCTL32" "COMDLG32" "USER32" "ADVAPI32" "GDI32" "WINMM" "OPENGL32" "WSOCK32" "Ws2_32"
    )

    add_custom_command(TARGET loomexec
        POST_BUILD
        COMMAND echo f | xcopy /F /Y \"${LOOMEXECBIN}\" \"${ARTIFACTS_DIR}/tools/loomexec.exe\" | find /v "File(s) copied"
    )

else ()

    if (LINUX)
    	target_link_libraries(loomexec
            -Wl,--start-group
            LoomVendor
            LoomCommon
            LoomScript
            -Wl,--end-group
        )
    else()
        target_link_libraries(loomexec
            LoomVendor
            LoomCommon
            LoomScript
        )
    endif()

	add_custom_command(TARGET loomexec
        POST_BUILD
        COMMAND mkdir -p ${ARTIFACTS_DIR}/tools
        COMMAND cp ${LOOMEXECBIN} ${ARTIFACTS_DIR}/tools/loomexec
	)

endif()

if (LOOM_BUILD_JIT EQUAL 1)

    target_link_libraries(loomexec luajit)

    if (LINUX)
        target_link_libraries(${PROJECT_NAME} -ldl)
    endif()

endif()
