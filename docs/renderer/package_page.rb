require 'erb'
require File.expand_path('../page', __FILE__)

class PackagePage < DocumentationPage
  
  def initialize(package_path, doc, relative_to_base)
    @package_path = package_path
    @doc = doc
    @relative_base_path = relative_to_base
  end
  
  def url( dest )
    "#{@relative_base_path}/api/#{dest.split('.').join('/')}/index.html"
  end
  
  def package_links( package_doc )
    if package_doc.path == ""
      return "<a href='#{@relative_base_path}/api/index.html'>api</a>"
    end
    result = ""
    package_path = package_doc.path
    package_path.split(".").each_with_index do |package, index|
      result += "<a href='#{url( package_path.split(".")[0..index].join(".") )}'>#{package}</a>" + (package_path.split(".").last == package ? "" : ".")
    end
    result
  end
  
  def breadcrumbs
    result = "<li><a class='is-perm' href='#{@relative_base_path}/api/index.html'>API Reference</a>"
    package_path = @doc.path
    package_path.split(".").each_with_index do |package, index|
      if package != package_path.split(".").last
        result += "<li><a class='is-perm' href='#{url( package_path.split(".")[0..index].join(".") )}'>#{package}</a>"
      else
        result += "<li>#{package}"
      end
    end
    result
  end
end