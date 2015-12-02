class Toolchain

  def buildCommand
    raise NotImplementedError
  end

  def name
    raise NotImplementedError
  end

  def cmakeArgs
    raise NotImplementedError
  end

  def arch(target)
    raise NotImplementedError
  end

  def exec(cmd)
    success = Kernel::system cmd
    if !success
      puts "Using working directory: #{Dir.pwd}"
      puts "Error 127 usually means command not found, make sure the following command is available" if $?.exitstatus == 127
      raise "Error #{$?.exitstatus}: #{cmd}"
    end
  end

  def build(target)
    path = target.buildPath(self)
    FileUtils.mkdir_p(path)
    Dir.chdir(path) do
      puts "cmake #{target.sourcePath} #{cmakeArgs(target)} #{target.flags(self)}"
      exec("cmake #{target.sourcePath} #{cmakeArgs(target)} #{target.flags(self)}")
      exec(buildCommand)
    end
  end

end

class WindowsToolchain < Toolchain

  def buildCommand
    return "msbuild /verbosity:m ALL_BUILD.vcxproj /p:Configuration=#{CFG[:BUILD_TARGET]}"
  end

  def name
    return "windows"
  end

  def cmakeArgs(target)
    if target.is64Bit == 1
      return "-G \"#{get_vs_name} Win64\""
    else
      return "-G \"#{get_vs_name}\""
    end
  end

  def arch(target)
    if target.is64Bit == 1
      return "x64"
    else
      return "x86"
    end
  end
  
  def get_reg_value(keyname, valuename)
    access = Win32::Registry::KEY_READ
    begin
      Win32::Registry::HKEY_LOCAL_MACHINE::open(keyname, access) do |reg|
        reg.each{ |name, value| if name == valuename then return value end }
      end
    rescue
      return nil
    end
    return nil
  end

  def get_vs_name()
    if get_reg_value('SOFTWARE\Microsoft\VisualStudio\12.0', 'ShellFolder') != nil then
      return 'Visual Studio 12'
    end
    if get_reg_value('SOFTWARE\Wow6432Node\Microsoft\VisualStudio\12.0', 'ShellFolder') != nil then
      return 'Visual Studio 12'
    end
    if get_reg_value('SOFTWARE\Microsoft\VisualStudio\11.0', 'ShellFolder') != nil then
      return 'Visual Studio 11'
    end
    if get_reg_value('SOFTWARE\Wow6432Node\Microsoft\VisualStudio\11.0', 'ShellFolder') != nil then
      return 'Visual Studio 11'
    end
    if get_reg_value('SOFTWARE\Microsoft\VisualStudio\10.0', 'ShellFolder') != nil then
      return 'Visual Studio 10'
    end
    if get_reg_value('SOFTWARE\Wow6432Node\Microsoft\VisualStudio\10.0', 'ShellFolder') != nil then
       return 'Visual Studio 10'
    end
    if Dir.exists?(File.expand_path("#{ENV['programfiles']}\\Microsoft Visual Studio 12.0\\VC")) then
      return 'Visual Studio 12'
    end
    if Dir.exists?(File.expand_path("#{ENV['programfiles(x86)']}\\Microsoft Visual Studio 12.0\\VC")) then
      return 'Visual Studio 12'
    end
    if Dir.exists?(File.expand_path("#{ENV['programfiles']}\\Microsoft Visual Studio 11.0\\VC")) then
      return 'Visual Studio 11'
    end
    if Dir.exists?(File.expand_path("#{ENV['programfiles(x86)']}\\Microsoft Visual Studio 11.0\\VC")) then
      return 'Visual Studio 11'
    end
    if Dir.exists?(File.expand_path("#{ENV['programfiles']}\\Microsoft Visual Studio 10.0\\VC")) then
      return 'Visual Studio 10'
    end
    if Dir.exists?(File.expand_path("#{ENV['programfiles(x86)']}\\Microsoft Visual Studio 10.0\\VC")) then
      return 'Visual Studio 10'
    end
  end

end

class OSXToolchain < Toolchain

  def name
    return "osx"
  end

  def buildCommand
    return "xcodebuild -configuration #{CFG[:BUILD_TARGET]}"
  end

  def cmakeArgs(target)
    return "-G \"Xcode\""
  end

  def arch(target)
    if target.is64Bit == 1
      return "x64"
    else
      return "x86"
    end
  end

end

class IOSToolchain < Toolchain

  def initialize(signAs)
    @signAs = signAs
    @sdkroot="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS#{CFG[:TARGET_IOS_SDK]}.sdk"
  end

  def name
    return "ios"
  end

  def buildCommand
    return "xcodebuild -configuration #{CFG[:BUILD_TARGET]} CODE_SIGN_IDENTITY=\"#{@signAs}\" CODE_SIGN_RESOURCE_RULES_PATH=#{@sdkroot}/ResourceRules.plist"
  end

  def cmakeArgs(target)
    return "-G \"Xcode\" -DLOOM_BUILD_IOS=1 -DLOOM_IOS_VERSION=#{CFG[:TARGET_IOS_SDK]}"
  end

  def arch(target)
   return "arm"
  end

end

class LinuxToolchain

end

class AndroidToolchain < Toolchain

  def buildCommand
    return "cmake --build ."
  end

  def name
    return "android"
  end

  def cmakeArgs(target)
    if $HOST.name == 'windows'
      generator = "MinGW Makefiles"
      make_arg = "-DCMAKE_MAKE_PROGRAM=\"%ANDROID_NDK%\\prebuilt\\#{$HOST.android_prebuilt_dir}\\bin\\make.exe\""
    else
      generator = "Unix Makefiles"
      make_arg = ""
    end

    return "-G \"#{generator}\" -DCMAKE_TOOLCHAIN_FILE=#{$ROOT}/build/cmake/loom.android.toolchain.cmake -DANDROID_NDK_HOST_X64=#{$HOST.is_x64} -DANDROID_ABI=armeabi-v7a -DANDROID_NATIVE_API_LEVEL=14 #{make_arg}"
  end

  def arch(target)
    return "arm"
  end
  
  def self.apkName()
    #Determine the APK name.
    if CFG[:TARGET_ANDROID_BUILD_TYPE] == "release"
      "LoomDemo-release-unsigned.apk"
    elsif CFG[:TARGET_ANDROID_BUILD_TYPE] == "debug"
      "LoomDemo-debug-unaligned.apk"
    else
      abort("Don't know how to generate the APK name for Android build target type #{CFG[:TARGET_ANDROID_BUILD_TYPE]}! Please update this if block.")
    end
  end
end
