#!/usr/bin/env ruby
require 'timeout'
require 'optparse'

begin
  if ARGV[0] then @example_dir = ARGV[0] else throw end
rescue
  puts "Usage: ./example_runner.rb path_to_example_dir [options]"
  exit(1)
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ./example_runner.rb path_to_example_dir [-options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-a", "--android", "Run on android device") do |a|
    options[:android] = a
  end

  opts.on("-i", "--ios", "Run on ios device") do |a|
    options[:ios] = a
  end
end.parse!

def exec_with_timeout(cmd, timeout)
  pid = Process.spawn(cmd) 
  begin
    Timeout.timeout(timeout) do
      Process.waitpid pid
      $?.exitstatus == 0
    end
  rescue Timeout::Error
    puts "Killing process"
    Process.kill 15, pid
    true
  end
end

failed = []
Dir.chdir(@example_dir) do
  Dir.glob("*").each do |example|
    if File.directory? example
      Dir.chdir(example) do
        puts "Processing #{example}... "
        system("loom use latest --firehose")

        if options[:android]
          if !exec_with_timeout("loom run --android", 30)
            puts "failed"
            failed << example
          end
        elsif options[:ios]
          if !exec_with_timeout("loom run --ios", 30)
            puts "failed"
            failed << example
          end
        else
          if !exec_with_timeout("loom run --noconsole", 3.5)
            puts "failed"
            failed << example
          end
        end
      end
    end
  end
end

unless failed.empty? 
  puts "===================================================================="
  puts "- FAILURES -"
  puts failed
  puts "===================================================================="
else
  puts "===================================================================="
  puts "All Examples Successfully Compiled and Ran"
end