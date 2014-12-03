set shaderc=..\..\artifacts\shaderc.exe
set bgfx=..\..\loom\vendor\bgfx\src
set common=--varyingdef %bgfx%\varying.def.sc -i .;%bgfx%\

%shaderc% %common% --type vertex   -f vs_postex.sc      --bin2c gvShaderPosTex      -o vs_postex_hlsl.cpp      --platform windows -p vs_3_0 || goto :error
%shaderc% %common% --type fragment -f fs_postex.sc      --bin2c gfShaderPosTex      -o fs_postex_hlsl.cpp      --platform windows -p ps_3_0 || goto :error 
%shaderc% %common% --type vertex   -f vs_poscolortex.sc --bin2c gvShaderPosColorTex -o vs_poscolortex_hlsl.cpp --platform windows -p vs_3_0 || goto :error
%shaderc% %common% --type fragment -f fs_poscolortex.sc --bin2c gfShaderPosColorTex -o fs_poscolortex_hlsl.cpp --platform windows -p ps_3_0 || goto :error

%shaderc% %common% --type vertex   -f vs_postex.sc      --bin2c gvShaderPosTex      -o vs_postex_glsl.cpp      --platform osx || goto :error
%shaderc% %common% --type fragment -f fs_postex.sc       --bin2c gfShaderPosTex      -o fs_postex_glsl.cpp      --platform osx || goto :error
%shaderc% %common% --type vertex   -f vs_poscolortex.sc --bin2c gvShaderPosColorTex -o vs_poscolortex_glsl.cpp --platform osx || goto :error
%shaderc% %common% --type fragment -f fs_poscolortex.sc --bin2c gfShaderPosColorTex -o fs_poscolortex_glsl.cpp --platform osx || goto :error

@echo.
@echo Shaders compiled!
@goto :eof

:error
@echo.
@echo Shader error!