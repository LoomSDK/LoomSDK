class Module::ExampleDoc
  
  attr_accessor :path, :name, :data
  
  def initialize(path)
    self.path = path
    self.name = path
    self.data = Hash.new
    parse_metadata
  end
  
  def parse_metadata
    return unless File.exists?(File.join("examples", path, "README.md"))
    contents = File.open(File.join("examples", path, "README.md"), "r")
    while(1)
      contents.gets
      break if $_.nil? or $_.chomp == "!------"
      matches = $_.scan(/(.*):\s*(.*)/)
      matches.each do |match|
        self.data[match[0].to_sym] = match[1].chomp
      end
    end
  end
  
  def write
    base_path = Pathname.new( OUTPUT_DIR )
    example_dir = File.join(EXAMPLES_OUTPUT_DIR, name)
    
    relative_to_base = base_path.relative_path_from( Pathname.new(example_dir) )
    example_page = ExamplePage.new(example_dir, self, relative_to_base)
    
    File.open(File.join(example_dir, "index.html"), 'w') do |f|
      f.write(example_page.render File.expand_path("templates/example/example_page"))
    end
  end
  
  def to_s
    data[:name]
  end
  
end