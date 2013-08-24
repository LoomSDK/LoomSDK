#!/usr/bin/env ruby

@is_managed = false
@class_detected = false
@contents = ""
@class_name = ""
@start_index = 0
@end_index = 0
@last_dump = false

def dump_contents

  if(@class_name.empty?)
    return
  end

  output = "package cocos2d\n{\n"

  output += "   [Native(managed)]\n" if @is_managed
  @contents.split("\n").each do |line|
    output += "   #{line}\n"
  end
  output += "}" unless @last_dump
  
  puts @class_name

  File.open("sdk/src/cocos2d/#{@class_name}.ls", 'w') { |file| file.write(output) }

  @contents = ""
  @class_name = ""
  @is_managed = false
  @class_detected = false
end

File.readlines("sdk/src/cocos2d/cocos2d.ls").each_with_index do |line, index|
  if(line.include? "[Native(managed)]")
    @is_managed = true
  end

  if line =~ /public\s*[native]* class (\w+)/
    dump_contents
    @class_detected = true
  end

  if(@class_detected)
    if(@class_name.empty? && !line.include?("[Native(managed)]"))
      @class_name = line.scan(/public\s*[native]* class (\w+)/)[0][0]
    end

    if(!line.strip.empty? && !line.include?("[Native(managed)]"))
      @contents += line
    end
  end
end

@last_dump = true
dump_contents

