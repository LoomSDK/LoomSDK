require File.expand_path('../guide_doc', __FILE__)

class Module::TopicDoc
  
  attr_accessor :path, :sub_topics, :guides
  
  def initialize(path)
    self.path = path
    self.sub_topics = {}
    self.guides = []
  end
  
  def add_guide(guide_doc)
    guides << guide_doc
  end
  
  def write
    topic_dir = File.join(GUIDES_OUTPUT_DIR, path)
    FileUtils.mkdir_p topic_dir

    base_path = Pathname.new( OUTPUT_DIR )
    relative_to_base = base_path.relative_path_from( Pathname.new(topic_dir) )

    page = TopicPage.new(path, self, relative_to_base)

    File.open(File.join(topic_dir, "index.html"), 'w') { |f| f.write(page.render('templates/guide/topic_doc')) }
  end
  
end