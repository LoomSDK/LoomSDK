class GuideTree
  
  attr_accessor :root
  
  def initialize
    self.root = Module::TopicDoc.new("")
  end
  
  def []( key )
    super_topic = root
    key.split("/").each do |super_topic_path|
      if super_topic.sub_topics[super_topic_path].nil?
        return nil
      else
        super_topic = super_topic.sub_topics[super_topic_path]
      end
    end
    super_topic
  end
  
  def []=( key, value )
    super_topic = root
    key.split("/").each_with_index do |super_topic_path, index|
      if super_topic.sub_topics[super_topic_path].nil?
        super_topic.sub_topics[super_topic_path] = Module::TopicDoc.new(key.split("/")[0..index].join("/"))
        super_topic = super_topic.sub_topics[super_topic_path]
      else
        super_topic = super_topic.sub_topics[super_topic_path]
      end
    end
    
    super_topic = value
  end
  
  def sidebar_links_json(relative_path)
    data = []
    root.sub_topics.values.each do |sub_topic|
      data << sidebar_links(sub_topic, relative_path)
    end
    JSON.dump(data)
  end
  
  def sidebar_links(topic_doc, relative_path)
    data = {:name => topic_doc.path.split("_").last, :link => []}
    topic_doc.sub_topics.values.each do |sub_topic|
      data[:link] << sidebar_links(sub_topic, relative_path)
    end
    
    topic_doc.guides.each do |guide_doc|
      data[:link] << {:name => guide_doc.data[:title], :link => guide_doc.url(relative_path)}
    end
    data
  end
  
  def each(&block)
    block_for_topics(root, block)
  end
  
  def block_for_topics(topic_doc, block)
    topic_doc.sub_topics.sort.each do |key, sub_topic|
      block_for_topics sub_topic, block
    end
    
    block.call topic_doc
  end
  
  def to_s
    topic_to_string(root)
  end
  
  def topic_to_string(topic_doc)
    str = "#{topic_doc.path == "" ? "root" : topic_doc.path} => { :sub_topics => {"
    unless topic_doc.sub_topics.empty?
      topic_doc.sub_topics.sort.each do |key, sub_topic|
        str += ":#{key} => {#{topic_to_string sub_topic}}"
      end
    end
       
    str += "}, :guides => ["
    topic_doc.guides.each do |guide_doc|
      str += ":#{guide_doc.name} => #{guide_doc.path} "
    end     
    str += "]}"    
  end
end