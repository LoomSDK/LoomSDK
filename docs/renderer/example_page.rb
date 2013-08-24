require 'erb'
require File.expand_path('../page', __FILE__)

class ExamplePage < DocumentationPage
  include Module::Commentable
  
  def initialize(example_path, doc, relative_path)
    @example_path = example_path
    @doc = doc
    @relative_base_path = relative_path
  end
  
  def url( dest )
    "#{@relative_base_path}/examples/#{@example_path}/index.html"
  end
  
  def replace_markdown
    markdown_text = ""
    if(File.exists? File.join(@example_path, "README.md"))
        contents = File.open(File.join(@example_path, "README.md"), 'r') { |f| f.read }
        contents = contents.sub(/(.*\n)*!------/, "")
        contents = insert_cli_example(contents)
        contents = insert_source(contents)
        markdown_text = markdown(contents)
    end
    markdown_text
  end

  def insert_source(contents)

    return contents unless (contents.include?("@insert_source") && !@doc.data[:source].nil?)

    source_file = File.join(@example_path, @doc.data[:source])

    if contents && File.exists?(source_file)
      contents.gsub!(/@insert_source/, "_#{@doc.data[:source]}_\n\n~~~as3\n#{File.open(source_file, 'r') { |f| f.read }}\n~~~\n")
    end

    contents
  end

  def insert_cli_example(contents)

    if contents
      try_it = "Use the following Loom CLI commands to run this example:\n\n~~~bash\nloom new My#{@doc.name} --example #{@doc.name}\ncd My#{@doc.name}\nloom run\n~~~\n"
      contents.gsub!(/@cli_usage/, try_it)
    end

    contents

  end
  
  def breadcrumbs
    result = "<li><a class='is-perm' href='#{@relative_base_path}/examples/index.html'>Examples</a>"
    result += "<li>#{@doc.data[:title]}"
  end
end