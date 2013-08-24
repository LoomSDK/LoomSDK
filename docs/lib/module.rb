require File.expand_path('../class_doc', __FILE__)

class Module

  attr_accessor :data, :types, :type_hash

	def initialize(data)
    #puts "got Module Data"
    self.data = data
    self.types = data[:types].map { |t| Module::ClassDoc.new(t) }

    self.type_hash = {}
    types.each do |t|
      #puts "Setting #{t.data[:package]}.#{t.data[:name]}"
      self.type_hash["#{t.data[:package]}.#{t.data[:name]}"] = t
    end
  end

  # def method_missing(m, *args, &block)
  #   if data[m.to_sym]
  #     data[m.to_sym]
  #   else
  #     #puts "missing: #{m}"
  #     super
  #   end
  # end
end