project(ldb)

include_directories( ${LOOM_INCLUDE_FOLDERS} )

# COMMAND LINE LDB

set (LDB_SRC ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp)
add_executable(ldb ${LDB_SRC})
set(LDBBIN $<TARGET_FILE:${PROJECT_NAME}>)

if (MSVC)

    target_link_libraries(ldb
        LoomVendor
        LoomCommon
        LoomScript
        LoomCore
        "kernel32" "advapi32" "COMCTL32" "COMDLG32" "USER32" "ADVAPI32" "GDI32" "WINMM" "OPENGL32" "WSOCK32" "Ws2_32"
    )

    add_custom_command(TARGET ${PROJECT_NAME}
        POST_BUILD
        COMMAND echo f | xcopy /F /Y \"${LDBBIN}\" \"${ARTIFACTS_DIR}/tools/ldb.exe\"
    )

else ()

    if (LINUX)
        target_link_libraries(ldb
            -Wl,--start-group
            LoomVendor
            LoomCommon
            LoomScript
            LoomCore
            -Wl,--end-group
        )
    else()
        target_link_libraries(ldb
            LoomVendor
            LoomCommon
            LoomScript
            LoomCore
        )
    endif()

    add_custom_command(TARGET ldb
        POST_BUILD
        COMMAND mkdir -p ${ARTIFACTS_DIR}/tools
        COMMAND cp ${LDBBIN} ${ARTIFACTS_DIR}/tools/ldb
    )

endif(MSVC)

if (LOOM_BUILD_JIT EQUAL 1)
    target_link_libraries(ldb luajit)

    if (LINUX)
        target_link_libraries(${PROJECT_NAME} -ldl)
    endif()

endif()

