shaderc="../../artifacts/shaderc"
bgfx="../../loom/vendor/bgfx/src"
common="--varyingdef $bgfx/varying.def.sc -i .;$bgfx/"

error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo "Shader error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Shader error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  exit "${code}"
}
trap 'error ${LINENO}' ERR

$shaderc $common --type vertex   -f vs_postex.sc      --bin2c gvShaderPosTex      -o vs_postex_hlsl.cpp      --platform windows -p vs_3_0 
$shaderc $common --type fragment -f fs_pstex.sc      --bin2c gfShaderPosTex      -o fs_postex_hlsl.cpp      --platform windows -p ps_3_0 
$shaderc $common --type vertex   -f vs_poscolortex.sc --bin2c gvShaderPosColorTex -o vs_poscolortex_hlsl.cpp --platform windows -p vs_3_0 
$shaderc $common --type fragment -f fs_poscolortex.sc --bin2c gfShaderPosColorTex -o fs_poscolortex_hlsl.cpp --platform windows -p ps_3_0 

$shaderc $common --type vertex   -f vs_postex.sc      --bin2c gvShaderPosTex      -o vs_postex_glsl.cpp      --platform osx
$shaderc $common --type fragment -f fs_postex.sc      --bin2c gfShaderPosTex      -o fs_postex_glsl.cpp      --platform osx
$shaderc $common --type vertex   -f vs_poscolortex.sc --bin2c gvShaderPosColorTex -o vs_poscolortex_glsl.cpp --platform osx
$shaderc $common --type fragment -f fs_poscolortex.sc --bin2c gfShaderPosColorTex -o fs_poscolortex_glsl.cpp --platform osx

echo Shaders compiled!
