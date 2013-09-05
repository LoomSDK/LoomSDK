require File.expand_path('../commentable', __FILE__)

class Module::ClassDoc
  include Module::Commentable

  FIELD_PUBLIC = "public"
  FIELD_PROTECTED = "protected"
  FIELD_PRIVATE = "private"

  attr_accessor :data, :field_hash, :method_hash, :metainfo

	def initialize(data)
    # puts "Got ClassType: #{data[:name]} extends #{data[:baseType]}"
    self.data = data
    self.method_hash = parseMethods
    self.field_hash = parseFields
    self.metainfo = parseMetainfo
  end

  # all superclasses of this class
  def superclasses
    superclasses = []
    iterating_class = self

    while(1)
      break if iterating_class.nil? || iterating_class.data[:name] == "Object"

      # Iterate onto this class's base class.
      iterating_class = $classes_by_package_path[ iterating_class.data[:baseType] ]

      superclasses << iterating_class
    end

    superclasses.delete_if { |x| x == nil }

    superclasses
  end
  
  # The immediate superclass of this class
  def superclass
    $classes_by_package_path[data[:baseType]]
  end
  
  
  # Extract all fields of a type from a class.
  def get_fields( field_type )

    all_fields = field_hash
    superclasses.each do |superclass_doc|
      all_fields.merge! superclass_doc.field_hash
    end
    
    if field_type.nil?
      all_fields
    else
      Hash[ all_fields.select { |key, f| f[:fieldattributes].include?(field_type) && !(f[:fieldattributes].include? "const") && !(f[:docString].include? "@private") && !hidden_from_inherited(f) } ]
    end
  end
  
  # Extract all constants in this class
  def get_constants
    
    all_constants = field_hash
    superclasses.each do |superclass_doc|
      all_constants.merge! superclass_doc.field_hash
    end
    
    Hash[ all_constants.select { |key, f| f[:fieldattributes].include?("const") && !(f[:docString].include? "@private") && !hidden_from_inherited(f) } ]
  end

  # Extract all methods of a type from a class.
  def get_methods( method_type )
    
    all_methods = method_hash
    superclasses.each do |superclass_doc|
      all_methods.merge! superclass_doc.method_hash
    end
    
    if method_type.nil?
      all_methods
    else
      Hash[ all_methods.select { |key, m| m[:methodattributes].include?(method_type) && !(m[:docString].include? "@private") && !hidden_from_inherited(m) } ]
    end
  end
  
  def get_events
    all_events = metainfo[:event] || []
    
    superclasses.each do |superclass_doc|
      all_events += (superclass_doc.metainfo[:event] || [])
    end
    
    all_events
  end
  
  # 
  def hidden_from_inherited(attribute)
    attribute[:defined_by] != self && (attribute[:docString].include? "@hide-from-inherited")
  end
  
  # Determine whether or not the class is native.
  def get_is_native()
    !metainfo[:native].nil?
  end
  
  def deprecated_message
    metainfo[:deprecated][0][:msg] unless metainfo[:deprecated].nil?
  end

  # Determine whether the class is public, private, or protected.
  def get_access_modifier()
    data[:classattributes].first
  end

  # Determine whether this is a class, interface, delegate or enum.
  def get_type()
    data[:type].downcase
  end

  # Check if any attributes are inherited.
  def has_inherited_fields( fields )
    fields.each do |field|
      if package_path != field[:defined_by].package_path
        return true
      end
    end
    false
  end

  # Check if any functions are inherited.
  def has_inherited_methods( methods )
    methods.each do |method|
      if package_path != method[:defined_by].package_path
        return true
      end
    end
    false
  end

  def url(relative_base)
    "#{relative_base}/api/#{package_path.split('.').join('/')}.html"
  end

  def package_path
    "#{data[:package]}.#{data[:name]}"
  end

  def to_s
    data[:name]
  end
  
  def self.full_classpath_to_url(path, relative_base)
    "#{relative_base}/api/#{path.split('.').join('/')}.html"
  end
  
  def object_type(parent_attribute, relative_base)
    str = ""
    if parent_attribute[:type] == "system.NativeDelegate"
      delegate_type = native_delegate_type(parent_attribute)
      str = "<a href='#{Module::ClassDoc.full_classpath_to_url(delegate_type, relative_base)}'>#{delegate_type.split(".").last}</a>" if delegate_type
    elsif !parent_attribute[:templatetypes].nil?
      str += vector_dictionary_links(parent_attribute[:templatetypes], relative_base)
    else
      class_type = parent_attribute[:returntype] || parent_attribute[:type]
      str = "<a href='#{Module::ClassDoc.full_classpath_to_url(class_type, relative_base)}'>#{class_type.split(".").last}</a>"
    end
    str
  end
  
  def native_delegate_type( attribute )
    if attribute[:metainfo]
      delegate_meta = attribute[:metainfo][:OriginalType]
      if delegate_meta
        return delegate_meta[0][1]
      else
        return "system.NativeDelegate"
      end
    end
  end
  
  def vector_dictionary_links(parent_attribute, relative_base)
    class_type = parent_attribute[:type]
    str = "<a href='#{Module::ClassDoc.full_classpath_to_url(class_type, relative_base)}'>#{class_type.split(".").last}</a>.&#60;"
    parent_attribute[:types].each_with_index do |value, index|
      if value.kind_of? Hash
        str += vector_dictionary_links(value, relative_base)
      else
        str += "<a href='#{Module::ClassDoc.full_classpath_to_url(value, relative_base)}'>#{value.split(".").last}</a>"
        str += ", " if index < parent_attribute[:types].length - 1
      end
    end
    str += "&#62; "
  end
  
  private
  
  def parseMethods
    return_hash = {}
    data[:methods].each do |method|
      method[:defined_by] = self
      return_hash[method[:name]] = method
    end
    
    return_hash
  end
  
  def parseFields
    return_hash = {}
    data[:fields].each do |field|
      field[:defined_by] = self
      return_hash[field[:name]] = field
    end
    
    data[:properties].each do |p|
      p[:defined_by] = self
      p[:fieldattributes] = p[:propertyattributes]
      return_hash[p[:name]] = p
    end
    
    return_hash
  end
  
  def parseMetainfo
    return {} if data[:metainfo].nil?
    serialized_metainfo = {}
    data[:metainfo].each do |key, entries|
      next if !key.is_a? String
      serialized_metainfo[key.downcase.to_sym] = []
      entries.each do |raw_entry|
        serialized_entry = {}
        raw_entry.each_slice(2) do |key_value|
          serialized_entry[key_value[0].downcase.to_sym] = key_value[1]
        end
        serialized_metainfo[key.downcase.to_sym] << serialized_entry
      end
    end
    serialized_metainfo
  end
end