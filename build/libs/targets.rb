
class Target

  def name
    raise NotImplementedError
  end

  def is64Bit
    raise NotImplementedError
  end

  def sourcePath
    raise NotImplementedError
  end

  def flags(toolchain)
  end

  def buildPath(toolchain)
    return "#{$ROOT}/build/#{name}-#{toolchain.name}-#{toolchain.arch(self)}"
  end

end

class LuaJITTarget < Target

  def initialize(is64Bit)
    @is64Bit = is64Bit
  end

  def name
    return "luajit"
  end

  def is64Bit
    return @is64Bit
  end

  def sourcePath
    return "#{$ROOT}/loom/vendor/luajit"
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
  def initialize(is64Bit, luajit)
    @is64Bit = is64Bit
    @luajit = luajit
  end

  def name
    return "loom"
  end

  def is64Bit
    return @is64Bit
  end

  def sourcePath
    return "#{$ROOT}"
  end

  def flags(toolchain)
    is_debug = CFG[:BUILD_TARGET] == "Debug" ? "1" : "0"
    return "-DLOOM_BUILD_JIT=#{CFG[:USE_LUA_JIT]} -DLOOM_BUILD_64BIT=#{@is64Bit} -DLUA_GC_PROFILE_ENABLED=#{CFG[:ENABLE_LUA_GC_PROFILE]} -DLOOM_BUILD_NUMCORES=#{$HOST.num_cores} -DLOOM_IS_DEBUG=#{is_debug} -DLOOM_BUILD_ADMOB=#{CFG[:BUILD_ADMOB]} -DLOOM_BUILD_FACEBOOK=#{CFG[:BUILD_FACEBOOK]} -DLUAJIT_BUILD_DIR=\"#{@luajit.buildPath(toolchain)}\""
  end

end