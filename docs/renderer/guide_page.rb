require 'erb'
require File.expand_path('../page', __FILE__)

class GuidePage < DocumentationPage
  include Module::Commentable
  
  def initialize(guide_path, doc, relative_path)
    @guide_path = guide_path
    @doc = doc
    @relative_base_path = relative_path
  end
  
  def url( dest )
    "#{@relative_base_path}/guides/#{@guide_path}/#{@doc.name}.html"
  end
  
  def replace_markdown
    markdown_text = ""
    if(File.exists? markdown_path)
      contents = File.open(markdown_path, 'r') { |f| f.read }
      contents = contents.sub(/(.*\n)*!------/, "")
      markdown_text = markdown(contents)
    end
    markdown_text
  end
  
  def markdown_path
    File.join("guides", @doc.path, "#{@doc.name}.md")
  end
  
  def breadcrumbs
    result = "<li><a class='is-perm' href='#{@relative_base_path}/guides/index.html'>Guides</a>"
    guide_path = @doc.path
    guide_path.split(".").each_with_index do |path, index|
      result += "<li><a class='is-perm' href='#{@relative_base_path}/guides/#{guide_path.split(".")[0..index].join("/")}/index.html'>#{path.split("_").last}</a>"
    end
    result += "<li>#{@doc.data[:title]}"
    result
  end
end