class Module::PackageDoc
  
  attr_accessor :path, :sub_packages, :classes, :interfaces, :enums, :structs, :delegates
  
  TYPE_INTERFACE = "INTERFACE"
  TYPE_STRUCT = "STRUCT"
  TYPE_DELEGATE = "DELEGATE"
  TYPE_ENUM = "ENUM"
  TYPE_CLASS = "CLASS"
  
  def initialize(path)
    self.path = path
    self.sub_packages = {}
    self.classes = []
    self.interfaces = []
    self.enums = []
    self.structs = []
    self.delegates = []
  end
  
  def assign_doc(class_doc)
    case class_doc.data[:type]
    when TYPE_INTERFACE
      interfaces << class_doc
    when TYPE_STRUCT
      structs << class_doc
    when TYPE_DELEGATE
      delegates << class_doc
    when TYPE_ENUM
      enums << class_doc
    else
      classes << class_doc
    end
  end
  
  def all_class_docs
    classes.concat interfaces.concat(enums.concat(structs.concat(delegates)))
  end
  
  def write
    package_dir = File.join( API_OUTPUT_DIR, path.split(".") )
    FileUtils.mkdir_p package_dir

    base_path = Pathname.new( OUTPUT_DIR )
    relative_to_base = base_path.relative_path_from( Pathname.new(package_dir) )

    page = PackagePage.new(path, self, relative_to_base)

    File.open(File.join(package_dir, "index.html"), 'w') { |f| f.write(page.render('templates/package_doc')) }
  end
end