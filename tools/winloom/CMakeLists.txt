project(winloom)

add_executable(winloom winloom.c)

target_link_libraries(winloom "kernel32" "advapi32" "USER32" "GDI32" )

get_target_property(WINLOOMBIN winloom LOCATION)

add_custom_command(TARGET winloom
    POST_BUILD
    COMMAND echo f | xcopy /F /Y \"${WINLOOMBIN}\" \"${CMAKE_SOURCE_DIR}/artifacts/loom.exe\"
)

