
class Target

  attr_reader :arch
  attr_reader :wordSize
  
  def name
    raise NotImplementedError
  end
  
  def is64Bit
    $ARCHS[arch][:is64Bit]
  end

  def sourcePath
    raise NotImplementedError
  end

  def flags(toolchain)
  end
  
  def buildName(toolchain, buildTarget = nil)
    return "#{name}-#{toolchain.name}-#{toolchain.arch(self)}" + (buildTarget ? "/" + buildTarget : "");
  end
  
  def buildRoot
    return "#{$ROOT}/build"
  end

  def buildPath(toolchain, buildTarget = nil)
    return "#{buildRoot}/#{buildName(toolchain, buildTarget)}"
  end

end

class LuaJITTarget < Target

  def initialize(arch)
    @arch = arch
  end

  def name
    return "luajit"
  end

  def sourcePath
    return "#{$ROOT}/loom/vendor/luajit"
  end
  
  def libPath(toolchain, buildTarget)
    #return "#{buildPath(toolchain)}/lib"
    
    libName = case name
    when "windows"
      "luajit51.lib"
    else
      "libluajit-5.1.a"
    end
    
    return "#{buildPath(toolchain, buildTarget)}/lib/#{libName}"
  end
  
  def includePath(toolchain)
    #return "#{buildPath(toolchain)}/include/luajit-2.1"
    return "#{sourcePath}/src"
  end

  def flags(toolchain)
    if toolchain.instance_of? WindowsToolchain
      os = "LUAJIT_OS_WINDOWS"
    elsif toolchain.instance_of? AndroidToolchain or toolchain.instance_of? LinuxToolchain
      os = "LUAJIT_OS_LINUX"
    else
      os = "LUAJIT_OS_OSX"
    end
    return "-DLUAJIT_X64=#{@is64Bit} -DLUA_TARGET_ARCH=#{toolchain.arch(self)} -DLUAJIT_OS=#{os} -DLUA_GC_PROFILE_ENABLED=#{CFG[:ENABLE_LUA_GC_PROFILE]}"
  end

end

class LuaJITBootstrapTarget < LuaJITTarget

  def initialize(is64Bit, targetToolchain)
    super is64Bit
    @targetToolchain = targetToolchain
  end

  def name
    return "luajit-bootstrap"
  end

  def flags(toolchain)
    return "#{super(@targetToolchain)} -DBOOTSTRAP_ONLY=1 -DCMAKE_OSX_ARCHITECTURES=i386"
  end

  def buildPath(toolchain)
    return super @targetToolchain
  end

end

class LuaJITLibTarget < LuaJITTarget

  def initialize(is64Bit, bootstrap)
    super is64Bit
    @bootstrap = bootstrap
  end

  def flags(toolchain)
    return "#{super} -DTARGET_ONLY=1 -DBOOTSTRAP_PATH=\"#{@bootstrap.buildPath(toolchain)}\""
  end

end

class LoomTarget < Target
  def initialize(arch, luajit)
    @arch = arch
    @luajit = luajit
  end

  def name
    return "loom"
  end

  def sourcePath
    return "#{$ROOT}"
  end

  def flags(toolchain)
    is_debug = CFG[:BUILD_TARGET] == "Debug" ? "1" : "0"
    
    flagstr =
      "-DLOOM_BUILD_JIT=#{CFG[:USE_LUA_JIT]} "\
      "-DLOOM_BUILD_64BIT=#{is64Bit ? 1 : 0} "\
      "-DLUA_GC_PROFILE_ENABLED=#{CFG[:ENABLE_LUA_GC_PROFILE]} "\
      "-DLOOM_BUILD_NUMCORES=#{$HOST.num_cores} "\
      "-DLOOM_IS_DEBUG=#{is_debug} "\
      "-DLOOM_BUILD_ADMOB=#{CFG[:BUILD_ADMOB]} "\
      "-DLOOM_BUILD_FACEBOOK=#{CFG[:BUILD_FACEBOOK]} "\
      "-DLUAJIT_LIB=\"#{@luajit.libPath(toolchain, CFG[:BUILD_TARGET]).shellescape}\" "\
      "-DLUAJIT_LIB_DEBUG=\"#{@luajit.libPath(toolchain, "Debug").shellescape}\" "\
      "-DLUAJIT_LIB_RELEASE=\"#{@luajit.libPath(toolchain, "Release").shellescape}\" "\
      "-DLUAJIT_LIB_RELMINSIZE=\"#{@luajit.libPath(toolchain, "Release").shellescape}\" "\
      "-DLUAJIT_LIB_RELWITHDEBINFO=\"#{@luajit.libPath(toolchain, "Release").shellescape}\" "\
      "-DLUAJIT_INCLUDE_DIR=\"#{@luajit.includePath(toolchain).shellescape}\""
    return flagstr
  end

end