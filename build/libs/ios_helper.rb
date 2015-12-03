def has_ios_sdk(version)
    #kinda hacky, lookup clang
    system "xcrun --sdk iphoneos#{version} --find clang &> /dev/null"
end

def check_ios_sdk_version!(version)
  # XCode version check
  if ! has_ios_sdk(version)
    abort("iOS SDK version #{version} is not installed. Please adjust the settings in Rakefile if you have a different version installed or set the environment variable IOS_SDK.")
  end
end