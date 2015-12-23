
RUBY_REQUIRED_VERSION = '1.8.7'
CMAKE_REQUIRED_VERSION = '3.0.0'

def version_outdated?(current, required)
  (Gem::Version.new(current.dup) < Gem::Version.new(required.dup))
end

def check_versions()

  # Ruby version check
  ruby_err = "LoomSDK requires ruby version #{RUBY_REQUIRED_VERSION} or newer.\nPlease go to https://www.ruby-lang.org/en/downloads/ and install the latest version."
  abort(ruby_err) if version_outdated?(RUBY_VERSION, RUBY_REQUIRED_VERSION)

  # CMake version check
  $CMAKE_VERSION = %x[cmake --version].lines.first.gsub("cmake version ", "")
  cmake_err = "LoomSDK requires CMake version #{CMAKE_REQUIRED_VERSION} or above.\nPlease go to http://www.cmake.org/ and install the latest version."
  abort(cmake_err) if (!installed?('cmake') || version_outdated?($CMAKE_VERSION, CMAKE_REQUIRED_VERSION))

end

def installed?(tool)
  cmd = "which #{tool}" unless ($HOST.is_a? WindowsHost)
  cmd = "where #{tool} > nul 2>&1" if ($HOST.is_a? WindowsHost)
  %x(#{cmd})
  return ($? == 0)
end

# TODO remove
def writeStub(platform)
  FileUtils.mkdir_p("artifacts")
  File.open("artifacts/README.#{platform.downcase}", "w") {|f| f.write("#{platform} is not supported right now.")}
end

def cp_r_safe(src, dst)
  if File.exists? src
    FileUtils.mkdir_p(dst)
    FileUtils.cp_r(src, dst)
  end
end

def cp_safe(src, dst)
  if File.exists? src
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
  end
end

def unzip_file (file, destination)
  Zip::File.open(file) do |zip_file|
    zip_file.each do |f|
      f_path=File.join(destination, f.name)
      FileUtils.mkdir_p(File.dirname(f_path))
      zip_file.extract(f, f_path) unless File.exist?(f_path)
    end
  end
end