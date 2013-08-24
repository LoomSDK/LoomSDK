require 'rubygems'
require 'json'
require 'erb'

require File.expand_path('../module', __FILE__)

class LoomLib

  attr_accessor :parsed, :modules

  def initialize(path)
    file = File.open(path, 'r')
    contents = file.read
    file.close

    self.parsed = JSON.parse(contents, :symbolize_names => true)

    self.modules = parsed[:modules].map { |m| Module.new(m) }
  end

  def debug?
    parsed[:debugbuild]
  end

  def jit?
    parsed[:jit]
  end

  def name
    parsed[:name]
  end
end