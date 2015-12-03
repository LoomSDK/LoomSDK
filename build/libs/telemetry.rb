# Relative path of the telemetry client files in the SDK 
$telemetryClient = "telemetry/www/"
# Include these files (Ruby Dir.glob syntax)
# If you change this, you should probably update the
# .gitignore file in tools/telemetry/www/ so people
# downloading the SDK can build straight away
$telemetryClientInclude = [
  "*.*",
  "css/**/*.*",
  "js/**/*.*",
  # Semantic UI
  "semantic/dist/**/*.*",
]
# Exclude these files
# Note that simple paths from .gitignore are already
# automatically excluded (e.g. unnecessary semantic ui files)
$telemetryClientExclude = [
  "semantic.json",
  "LICENSE.txt",
]

# Selectively copy files required for the telemetry client
# based on $telemetryClientInclude and $telemetryClientExclude
def telemetry_client_copy(fromDir, toDir)
  # Enumerate and store all included file paths
  included = []
  $telemetryClientInclude.each do |path|
    included.concat(Dir.glob(File.join(fromDir, path)))
  end
  
  # Enumerate and store all excluded file paths
  excluded = []
  $telemetryClientExclude.each do |path|
    excluded.concat(Dir.glob(File.join(fromDir, path)))
  end
  
  # Add .gitignore to excluded files
  excluded.concat IO.readlines(File.join(fromDir, ".gitignore")).map { |line|
    line.strip
  }.select { |line|
    line.length > 0 && !line.start_with?("#")
  }.map { |line|
    path = File.join(fromDir, line)
  }
  
  # Only process the included files without the excluded ones
  pathExcludedFiles = 0
  clientFiles = (included-excluded).select { |path| 
    sw = path.start_with? *excluded
    pathExcludedFiles += sw ? 1 : 0
    !sw
  }
  
  # Copy each file to the target directory
  clientFiles.each do |fromPath|
    toPath = fromPath.sub(fromDir, File.join(toDir, $telemetryClient))
    cp_r_safe fromPath, toPath
  end
  
  puts "Copied #{clientFiles.length} Telemetry client files (included #{included.length}, excluded #{excluded.length}, path excluded #{pathExcludedFiles})"
  
end