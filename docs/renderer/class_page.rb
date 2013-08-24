require 'erb'
require File.expand_path('../page', __FILE__)

class ClassPage < DocumentationPage
  
  def initialize(doc, inherits, subclasses, base_path, relative_base_path, constants, public_fields, protected_fields, public_methods, protected_methods, events)
    @doc = doc
    @superclasses = inherits
    @subclasses = subclasses
    @base_path = base_path
    @relative_base_path = relative_base_path
    @constants = constants
    @public_fields = public_fields
    @protected_fields = protected_fields
    @public_methods = public_methods
    @protected_methods = protected_methods
    @events = events
  end
  
  def url( dest )
      Module::ClassDoc.full_classpath_to_url( dest, @relative_base_path )
  end

  def path_links
    result = ""
    package_path = @doc.data[:package]
    package_path.split(".").each_with_index do |package, index|
      result += "<a href='#{url( package_path.split(".")[0..index].join(".") + ".index" )}'>#{package}</a>."
    end
    result += "<a href='#{@doc.url @relative_base_path}'>#{abbr_path( @doc.data[:name] )}</a>"
  end
  
  def breadcrumbs
    result = "<li><a class='is-perm' href='#{@relative_base_path}/api/index.html'>API Reference</a>"
    package_path = @doc.data[:package]
    package_path.split(".").each_with_index do |package, index|
      result += "<li><a class='is-perm' href='#{url( package_path.split(".")[0..index].join(".") + ".index" )}'>#{package}</a>"
    end
    result += "<li>#{abbr_path( @doc.data[:name] )}"
  end
  
end