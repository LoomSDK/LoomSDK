
set (LOOM_VENDOR ${CMAKE_SOURCE_DIR}/loom/vendor)
set (BX_INCLUDE ${LOOM_VENDOR}/bx/include)
set (BGFX ${LOOM_VENDOR}/bgfx)
set (BGFX_INCLUDE ${BGFX}/include)
set (BGFX_THIRDPARTY ${BGFX}/3rdparty)
set (SHADERC ${BGFX}/tools/shaderc)
set (GLSL_OPTIMIZER ${BGFX_THIRDPARTY}/glsl-optimizer)
set (FCPP ${BGFX_THIRDPARTY}/fcpp)

include_directories( ${LOOM_INCLUDE_FOLDERS} ${BX_INCLUDE} ${BGFX_INCLUDE} )					 

include_directories(
  ${GLSL_OPTIMIZER}/include
  ${GLSL_OPTIMIZER}/src
  ${GLSL_OPTIMIZER}/src/mesa
  ${GLSL_OPTIMIZER}/src/getopt
  ${GLSL_OPTIMIZER}/src/glsl
  ${FCPP}
)

if (MSVC) 

include_directories( ${GLSL_OPTIMIZER}/include/c99)

add_definitions( -D__STDC__ -D__STDC_VERSION__=199901L -Dstrdup=_strdup -Dalloca=_alloca -Disascii=__isascii)

add_definitions (/wd4291)

else()

include_directories(${BX_INCLUDE}/compat/osx)

#-- glsl-optimizer has bugs if strict aliasing is used.
add_definitions( -fno-strict-aliasing )

endif()

# fcpp
add_definitions(-DNINCLUDE=64 -DNWORK=65536 -DNBUFF=65536)

file (GLOB SRC_FILES
  ${BGFX}/src/vertexdecl.cpp
  ${GLSL_OPTIMIZER}/src/mesa/program/*.c 
  ${GLSL_OPTIMIZER}/src/mesa/main/*.c 
  ${GLSL_OPTIMIZER}/src/getopt/*.c 
  ${GLSL_OPTIMIZER}/src/util/*.c 
	${GLSL_OPTIMIZER}/src/glsl/*.c 
	${GLSL_OPTIMIZER}/src/glsl/*.cpp 
	${GLSL_OPTIMIZER}/src/glsl/glcpp/*.c
)

set (SRC_FILES ${SRC_FILES} ${FCPP}/cpp1.c ${FCPP}/cpp2.c ${FCPP}/cpp3.c ${FCPP}/cpp4.c ${FCPP}/cpp5.c ${FCPP}/cpp6.c )

list(REMOVE_ITEM SRC_FILES ${GLSL_OPTIMIZER}/src/glsl/glcpp/glcpp.c)
list(REMOVE_ITEM SRC_FILES ${GLSL_OPTIMIZER}/src/glsl/ir_set_program_inouts.cpp)
list(REMOVE_ITEM SRC_FILES ${GLSL_OPTIMIZER}/src/glsl/main.cpp)
list(REMOVE_ITEM SRC_FILES ${GLSL_OPTIMIZER}/src/glsl/builtin_stubs.cpp)
list(REMOVE_ITEM SRC_FILES ${GLSL_OPTIMIZER}/src/glsl/glsl_lexer.ll)


add_executable(shaderc ${SHADERC}/shaderc.cpp ${SRC_FILES})

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
