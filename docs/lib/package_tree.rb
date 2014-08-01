require File.expand_path('../package_doc', __FILE__)

class PackageTree
  
  attr_accessor :root_package
  
  def initialize
    self.root_package = Module::PackageDoc.new("")
    root_package.path = ""
  end
  
  def []( key )
    super_package = root_package
    key.split(".").each do |super_package_path|
      if super_package.sub_packages[super_package_path.to_sym].nil?
        return nil
      else
        super_package = super_package.sub_packages[super_package_path.to_sym]
      end
    end
    super_package
  end
  
  def []=( key, value )
    super_package = root_package
    key.split(".").each_with_index do |super_package_path, index|
      if super_package.sub_packages[super_package_path.to_sym].nil?
        super_package.sub_packages[super_package_path.to_sym] = Module::PackageDoc.new(key.split(".")[0..index].join("."))
        super_package = super_package.sub_packages[super_package_path.to_sym]
      else
        super_package = super_package.sub_packages[super_package_path.to_sym]
      end
    end
    
    super_package = value
  end
  
  def sidebar_links_json(relative_path)
    data = []
    self.root_package.sub_packages.values.each do |sub_package|
      data << sidebar_links(sub_package, relative_path)
    end
    JSON.dump(data)
  end
  
  def sidebar_links(package, relative_path)
    packagename = package.path.split(".").last
    data = {:name => packagename, :link => []}
    data[:link] << {:name => "Index", :link => package.url(relative_path) }
    package.sub_packages.values.each do |sub_package|
      data[:link] << sidebar_links(sub_package, relative_path)
    end
    data
  end

  def each(&block)
    root_package.sub_packages.each do |key, package_doc|
      block_for_packages package_doc, block
    end
    
    block.call root_package
  end
  
  def block_for_packages(package_doc, block)
    package_doc.sub_packages.each do |key, sub_package|
      block_for_packages sub_package, block
    end
    
    block.call package_doc
  end
  
  def to_s
    root_package.sub_packages.each do |key, package_doc|
      package_to_string package_doc
    end
  end
  
  def package_to_string(package_doc)
    package_doc.sub_packages.each do |key, sub_package|
      package_to_string sub_package
    end
                
  end
end