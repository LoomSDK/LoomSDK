
 include_directories( ${LOOM_INCLUDE_FOLDERS} 
                     ${CMAKE_SOURCE_DIR}/loom/graphics/internal/bx/include )					 

include_directories(glsl-optimizer/include glsl-optimizer/src/mesa glsl-optimizer/src/mapi glsl-optimizer/src/glsl fcpp)

if (MSVC) 

include_directories( glsl-optimizer/include/c99)

add_definitions( -D__STDC__ -D__STDC_VERSION__=199901L -Dstrdup=_strdup -Dalloca=_alloca -Disascii=__isascii)

add_definitions (/wd4291)

else()

include_directories(${CMAKE_SOURCE_DIR}/loom/graphics/internal/bx/include/compat/osx)

#-- glsl-optimizer has bugs if strict aliasing is used.
add_definitions( -fno-strict-aliasing )

endif()

# fcpp
add_definitions(-DNINCLUDE=64 -DNWORK=65536 -DNBUFF=65536)

file (GLOB SRC_FILES glsl-optimizer/src/mesa/program/*.c 
					 glsl-optimizer/src/glsl/*.c 
				     glsl-optimizer/src/glsl/*.cpp 
				     glsl-optimizer/src/glsl/glcpp/*.c )

set (SRC_FILES ${SRC_FILES} fcpp/cpp1.c fcpp/cpp2.c fcpp/cpp3.c fcpp/cpp4.c fcpp/cpp5.c fcpp/cpp6.c )

list(REMOVE_ITEM SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/glsl-optimizer/src/glsl/glcpp/glcpp.c)
list(REMOVE_ITEM SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/glsl-optimizer/src/glsl/ir_set_program_inouts.cpp)
list(REMOVE_ITEM SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/glsl-optimizer/src/glsl/main.cpp)
list(REMOVE_ITEM SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/glsl-optimizer/src/glsl/builtin_stubs.cpp)
list(REMOVE_ITEM SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/glsl-optimizer/src/glsl/glsl_lexer.ll)


add_executable(shaderc shaderc.cpp ${SRC_FILES})

get_target_property(SHADERCBIN shaderc LOCATION)

if (MSVC)

	target_link_libraries(shaderc d3dx9 d3dcompiler dxguid)

 	add_custom_command(TARGET shaderc
        POST_BUILD
        COMMAND echo f | xcopy /F /Y \"${SHADERCBIN}\" \"${CMAKE_SOURCE_DIR}/artifacts/shaderc.exe\"
    )


else()

add_custom_command(TARGET shaderc
    POST_BUILD
    COMMAND mkdir -p ${CMAKE_SOURCE_DIR}/artifacts
    COMMAND cp ${SHADERCBIN} ${CMAKE_SOURCE_DIR}/artifacts/shaderc
)

endif()
