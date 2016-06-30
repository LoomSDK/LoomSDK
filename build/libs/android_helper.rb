def get_android_api_id(api_ver)

  api_name = "android-#{api_ver}"
  
  if $HOST.name == "windows"
    grep = "findstr"
  else
    grep = "grep"
  end

  api_id = `android list target | #{grep} "#{api_name}"`

  if api_id.empty?
    puts "===================================================================="
    puts " ERROR :: Unable to find android SDK '#{api_name}', is it installed?"
    puts "===================================================================="
    exit(1)
  else
    api_id = api_id.split(" ")[1]
  end
  
  api_id
end

def decompile_apk (file, destination)
  puts "Decompiling APK #{file} to #{destination}..."
  sh "java -jar tools/apktool/apktool.jar d -f #{file} -o #{destination}"
end
