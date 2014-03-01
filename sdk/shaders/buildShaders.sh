../../artifacts/shaderc -f fs_poscolortex.sc -i . -o fs_poscolortex_glsl.cpp --bin2c gfShaderPosColorTex --type f --platform osx
../../artifacts/shaderc -f fs_postex.sc -i . -o fs_postex_glsl.cpp --bin2c gfShaderPosTex --type f --platform osx
../../artifacts/shaderc -f vs_poscolortex.sc -i . -o vs_poscolortex_glsl.cpp --bin2c gvShaderPosColorTex --type v --platform osx
../../artifacts/shaderc -f vs_postex.sc -i . -o vs_postex_glsl.cpp --bin2c gvShaderPosTex --type v --platform osx
echo Shaders compiled!