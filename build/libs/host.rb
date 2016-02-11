require 'rbconfig'
include RbConfig

require 'toolchains'

ho = CONFIG['host_os']

class Host

  def self.create()
    case CONFIG['host_os']
      when /mswin|windows|mingw32/i
        return WindowsHost.new()
      when /darwin/i
        return OSXHost.new()
      when /linux-gnu/i
        return LinuxHost.new()
      else
        abort("Unknown host config: Config::CONFIG['host_os']: #{Config::CONFIG['host_os']}")
      end
    end
    
    def num_cores()
      @NUM_CORES
    end
    
    def is_x64()
      @ISX64
    end
    
    def arch()
      if @ISX64
        "x64"
      else
        "x86"
      end
    end
    
    def toolchain()
      raise NotImplementedError
    end
    
    def open(file)
      raise NotImplementedError
    end
end

class WindowsHost < Host

  def initialize()
    require 'win32/registry'

    @NUM_CORES = ENV['NUMBER_OF_PROCESSORS']
    # This gets the true architecture of the machine, not the target architecture of the currently executing binary (that is what %PROCESSOR_ARCHITECTURE% returns)
    # => Valid values seem to only be "AMD64", "IA64", or "x86"
    proc_arch = `reg query "HKLM\\System\\CurrentControlSet\\Control\\Session Manager\\Environment" /v PROCESSOR_ARCHITECTURE`
    if proc_arch =~ /\.*64/
      @ISX64 = '1'
      @ANDROID_PREBUILT_DIR = 'windows-x86_64'
    else
      @ISX64 = '0'
      @ANDROID_PREBUILT_DIR = 'windows'
    end
  end

  def name()
    "windows"
  end

  def toolchain()
    WindowsToolchain.new()
  end
  
  def open(file)
    `start #{file}`
  end

  def android_prebuilt_dir()
    @ANDROID_PREBUILT_DIR
  end
end

class OSXHost < Host

  def initialize()
    @NUM_CORES = Integer(`sysctl hw.ncpu | awk '{print $2}'`)
    arch = `uname -m`.chomp
    if arch == 'x86_64' then
      @ISX64 = '1'
    elsif arch == 'i386' then
      @ISX64 = '0'
    else
      abort("Unsupported OSX/Linux platform #{arch}!")
    end
  end

  def name()
    "osx"
  end
  
  def toolchain()
    OSXToolchain.new()
  end

  def open(file)
    `exec #{file}`
  end

end

class LinuxHost < Host

  def initialize()
    @NUM_CORES = Integer(`cat /proc/cpuinfo | grep processor | wc -l`)
    arch = `uname -m`.chomp
    if arch == 'x86_64' then
      @ISX64 = '1'
    elsif arch == 'i686' then
      @ISX64 = '0'
    else
      abort("Unsupported OSX/Linux platform #{arch}!")
    end
  end

  def name()
    "linux"
  end

  def toolchain()
    LinuxToolchain.new()
  end
  
  def open(file)
    `xdg-open #{file}`
  end

end
