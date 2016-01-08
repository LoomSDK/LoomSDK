
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
    
    libName = case toolchain.name
    when "windows"
      "lua51.lib"
    else
      "libluajit-5.1.a"
    end
    
    return "#{buildPath(toolchain, buildTarget)}/lib/#{libName}"
  end
  
  def includePath(toolchain)
    #return "#{buildPath(toolchain)}/include/luajit-2.1"
    return "#{sourcePath}/src"
  end

  def flags(toolchain, buildTarget = nil)
    if toolchain.instance_of? BatchToolchain
      
      args = ""
      platform = toolchain.platform
      
      if platform.instance_of? WindowsToolchain

        vs_install = toolchain.platform.get_vs_install
        
        # %1 - path to vcvarsall.bat
        args += "\"#{vs_install[:install]}VC\\vcvarsall.bat\""

        # %2 - vcvarsall architecture
        args += " " + case arch
        when :x86
          "x86"
        when :x86_64
          "amd64"
        else
          abort("Unsupported architecture: #{arch}")
        end

        # %3 - msvcbuild extra arguments
        args += " " + case buildTarget
        when "Debug"
          "debug"
        else
          '""'
        end
      
        # %4 - directory of output lib
        args += " \"" + File.dirname(libPath(toolchain.platform, buildTarget)) + "\""
        
      elsif platform.instance_of? AndroidToolchain
        
        supported_targets = [
          "Release",
          "Debug",
        ]
        
        buildTarget = "Release" unless supported_targets.include? buildTarget
        
        prebuilt = Pathname.new "#{$ROOT}/loom/vendor/luajit-prebuilt"
        libout_root = Pathname.new buildRoot
        libout = Pathname.new libPath(toolchain, buildTarget)

        relpath = libout.relative_path_from libout_root
        
        args += "\"" + (prebuilt + relpath).to_s.gsub('/', '\\') + "\""
        args += " \"" + (libout.dirname).to_s.gsub('/', '\\') + "\""
        
      end
      
      
      args
    else
      ""
    end
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