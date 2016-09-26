project(winloom)

add_executable(winloom winloom.c)

target_link_libraries(winloom "kernel32" "advapi32" "USER32" "GDI32" )

set(WINLOOMBIN $<TARGET_FILE:${PROJECT_NAME}>)

add_custom_command(TARGET winloom
    POST_BUILD
    COMMAND echo f | xcopy /F /Y \"${WINLOOMBIN}\" \"${ARTIFACTS_DIR}/tools/loom.exe\" | find /v "File(s) copied"
)
