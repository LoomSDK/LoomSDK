#!/usr/bin/env ruby

require "fileutils"

def prepare(srcdir, templatedir, name, url, branch, dir, template, dry = false)

  raise "Need to specify the name of the library dir" unless name && !name.empty?
  raise "Need to specify the URL of the remote Git repository for the library" unless url && !name.empty?
  branch = "master" if branch.nil? || branch.empty?
  dir = "vendor" if dir.nil? || dir.empty?
  template = name if template.nil? || template.empty?
  template = File.join templatedir, template
  
  def git(dry, cmd)
    c = "git "+cmd
    puts c
    unless dry
      unless system c
        raise "GIT ERROR"
      end
    end
  end

  postfix = "-gittemp"

  parent = File.join srcdir, dir
  d = File.join parent, name
  dpt = d+postfix
  
  unless File.directory? parent
    puts "Lib parent dir #{parent} not found"
    return false
  end
  
  unless File.directory? d
    puts "Lib dir #{d} not found"
    return false
  end
  
  unless File.directory? template
    puts "Template dir #{template} not found"
    return false
  end

  puts "DRY RUN" if dry

  unless dry
    if File.directory? dpt
      puts "Removing previously leftover git dir #{dpt}"
      FileUtils.rm_r dpt
    end
  end

  puts "Creating temporary dir #{dpt}"
  FileUtils.mkdir_p dpt unless dry

  template_abs = File.join Dir.pwd, template

  begin
    Dir.chdir(dry ? Dir.pwd : dpt) do
      git dry, "init --template=#{template_abs}"
      git dry, "config core.sparsecheckout true"
      git dry, "remote add -f origin #{url}"
      git dry, "pull origin #{branch}"
    end
  rescue Exception => e
    puts "Exception with git: #{e}"
    puts "Git dir left at #{dpt} (removed on next run)"
    puts "Original dir left unchanged at #{d}"
    return false
  end

  puts "Copying files from #{d} to #{dpt}"
  FileUtils.cp_r File.join(d, "."), dpt unless dry

  puts "Removing dir #{d}"
  FileUtils.rm_r d unless dry

  puts "Renaming dir from #{dpt} to #{d}"
  File.rename dpt, d unless dry

  return true
end


if __FILE__ == $0
  require 'optparse'
  name = ""
  url = ""
  branch = ""
  dir = ""
  template = ""
  dry = false

  OptionParser.new do |opts|
    opts.banner = "Usage: ./prepare.rb NAME URL [options]"
    opts.on("-b", "--branch [BRANCH_NAME]", "The remote branch name (default #{branch})") do |v| branch = v end
    opts.on("-d", "--dir [DIR_PATH]", "The directory containing the library (default #{dir})") do |v| dir = v end
    opts.on("-t", "--template [TEMPLATE_PATH]", "The template directory used for git init (default equal to name)") do |v| template = v end
    opts.on("-r", "--dry", "Dry run, only print changes") do dry = true end
  end.parse!

  name = ARGV.shift
  url = ARGV.shift

  loom = File.join "..", "..", "loom"
  
  success = prepare(loom, "", name, url, branch, dir, template, dry)
  exit success ? 0 : 1
end