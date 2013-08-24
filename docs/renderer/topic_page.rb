require 'erb'
require File.expand_path('../page', __FILE__)

class TopicPage < DocumentationPage
  
  def initialize(topic_path, doc, relative_to_base)
    @topic_path = topic_path
    @doc = doc
    @relative_base_path = relative_to_base
  end
  
  def url( dest )
    "#{@relative_base_path}/guides/#{dest}/index.html"
  end
  
  def topic_links( topic_doc )
    if topic_doc.path == ""
      return "<a href='#{@relative_base_path}/guides/index.html'>guides</a>"
    end
    result = ""
    topic_path = topic_doc.path
    topic_path.split("/").each_with_index do |topic, index|
      result += "<a href='#{url( topic_path.split("/")[0..index].join("/") )}'>#{topic.split("_").last}</a>" + (topic_path.split("/").last == topic ? "" : ".")
    end
    result
  end
  
  def breadcrumbs
    if @doc.path == ""
      return "<li>Guides"
    end
    
    result = "<li><a class='is-perm' href='#{@relative_base_path}/guides/index.html'>Guides</a>"
    topic_path = @doc.path
    topic_path.split("/").each_with_index do |topic, index|
      if topic != topic_path.split("/").last
        result += "<li><a class='is-perm' href='#{url( topic_path.split("/")[0..index].join("/") )}'>#{topic.split("_").last}</a>"
      else
        result += "<li>#{topic.split("_").last}"
      end
    end
    result
  end
end