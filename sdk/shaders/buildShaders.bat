..\..\artifacts\shaderc.exe -f fs_poscolortex.sc -i . -o fs_poscolortex_hlsl.cpp --bin2c gfShaderPosColorTex --type f --platform windows -p ps_2_0
..\..\artifacts\shaderc.exe -f fs_postex.sc -i . -o fs_postex_hlsl.cpp --bin2c gfShaderPosTex --type f --platform windows -p ps_2_0
..\..\artifacts\shaderc.exe -f vs_poscolortex.sc -i . -o vs_poscolortex_hlsl.cpp --bin2c gvShaderPosColorTex --type v --platform windows -p vs_2_0
..\..\artifacts\shaderc.exe -f vs_postex.sc -i . -o vs_postex_hlsl.cpp --bin2c gvShaderPosTex --type v --platform windows -p vs_2_0
..\..\artifacts\shaderc.exe -f fs_poscolortex.sc -i . -o fs_poscolortex_glsl.cpp --bin2c gfShaderPosColorTex --type f --platform osx
..\..\artifacts\shaderc.exe -f fs_postex.sc -i . -o fs_postex_glsl.cpp --bin2c gfShaderPosTex --type f --platform osx
..\..\artifacts\shaderc.exe -f vs_poscolortex.sc -i . -o vs_poscolortex_glsl.cpp --bin2c gvShaderPosColorTex --type v --platform osx
..\..\artifacts\shaderc.exe -f vs_postex.sc -i . -o vs_postex_glsl.cpp --bin2c gvShaderPosTex --type v --platform osx
@echo Shaders compiled!