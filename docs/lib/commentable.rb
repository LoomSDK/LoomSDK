module Module::Commentable
  require 'redcarpet'
  require 'nokogiri'
  require 'pygments.rb'

  def comment(data, relative_base_path)
    @relative_base_path = relative_base_path
    docString = data.is_a?(String) ? data : data[:docString]
    docString = inherit_doc_from_class(self, data[:name]) if docString.include? "@inheritDoc"
    docString = replace_copy docString
    docString = replace_see docString
    docString = remove_flags docString
    markdown(docString)
  end

  # remove flags
  def remove_flags(docString)
    docString = remove_param_flags docString
    docString = remove_throws_flags docString
    docString = remove_return_flags docString
    docString = remove_deprecated_flags docString
    docString = remove_noinherit_flags docString
    remove_default_flags docString
  end

  def remove_default_flags(str)
    str.gsub(/@default\s*(.*)/, "")
  end

  def remove_param_flags(str)
    str.gsub(/@param\s*(\S*)\s(.*)/, "")
  end

  def remove_throws_flags(str)
    str.gsub(/@throws\s*(\S*)\s*(.*)/, "")
  end

  def remove_return_flags(str)
    str.gsub(/@return\s*(.*)/, "")
  end

  def remove_deprecated_flags(str)
    str.gsub(/@deprecated\s*(.*)/, "")
  end

  def remove_noinherit_flags(str)
    str.gsub(/@hide-from-inherited/, "")
  end

  # @inheritDoc
  def inherit_doc_from_class(class_doc, name)

    new_docString = ""

    #check interfaces
    class_doc.data[:interfaces].each do |interface|
      interface_doc = $classes_by_package_path[interface]
      new_docString = find_docString_in_interface(interface_doc, name)
      break unless new_docString.empty?
    end

    #check this class unless its the base class
    if new_docString.empty? && class_doc != self
      new_docString = docString_from_class(class_doc, name)
    end

    #check superclass
    if new_docString.empty? && !class_doc.superclass.nil?
      new_docString = inherit_doc_from_class(class_doc.superclass, name)
    end

    new_docString
  end

  def docString_from_class(doc, name)
    if doc.method_hash[name]
      return doc.method_hash[name][:docString] unless doc.method_hash[name][:docString].include? "@inheritDoc"
    end
    if doc.field_hash[name]
      return doc.field_hash[name][:docString] unless doc.field_hash[name][:docString].include? "@inheritDoc"
    end
    ""
  end

  def find_docString_in_interface(interface_doc, name)
    new_docString = docString_from_class(interface_doc, name)

    #check interface superclasses
    if new_docString.empty?
      interface_doc.superclasses.each do |superclass_doc|
        new_docString = docString_from_class(superclass_doc, name)
      end
    end

    new_docString
  end


  # @copy
  def replace_copy(str)
    str.match(/@copy \S*/).to_a.each do |match|
      class_doc = $classes_by_package_path[match.sub("@copy ", "").split("#").first]
      attribute = match.sub("@copy ", "").split("#").last.sub("()", "")
      copied_data = ""
      if match.include? "()"
        copied_data = class_doc.get_methods(nil)[attribute][:docString] unless class_doc.get_methods(nil)[attribute].nil?
      else
        copied_data = class_doc.get_fields(nil)[attribute][:docString] unless class_doc.get_fields(nil)[attribute].nil?
      end
      str = str.sub(match, copied_data)
    end
    str
  end

  # @see
  def replace_see(str)
    match_data = str.scan(/@see ((".*")|\S*(\s\[.*\])?)/)
    unless match_data.nil?
      match_data.each_with_index do |match, index|
        replacement_text = ""
        replacement_text += "See also:  \n" if index == 0
        if match[0].include? "http://"
          replacement_text += "[#{match[0]}](#{match[0]})  "
        elsif match[0][0] == "#" # method or property on class
          replacement_text += link_text(match[0])
        elsif !$classes_by_package_path[self.data[:package] + ".#{match[0].split("#").first}"].nil? # in the same package
          replacement_text += link_text(self.data[:package] + ".#{match[0]}")
        elsif !$classes_by_package_path["system.#{match[0].split("#").first}"].nil? # in top level class
          replacement_text += link_text("system.#{match[0]}")
        elsif !$examples[match[0]].nil?
          replacement_text += "[#{match[0]}](#{File.join(@relative_base_path, "examples", match[0], "index.html")})  "
        else # in a different package
          replacement_text += link_text(match[0])
        end
        str = str.sub(/@see ((".*")|\S*(\s\[.*\])?)/.match(str)[0], replacement_text);
      end
    end
    str
  end

  def link_text(matching_str)
    class_path, attribute = matching_str.split("#")
    unless attribute.nil?
      if attribute.include? "()"
        attribute = "#function-#{attribute}".sub!("()", "")
      else
        attribute = "#attribute-#{attribute}"
      end
    end
    class_path = self.package_path if class_path.empty?
    "[#{matching_str}](#{Module::ClassDoc.full_classpath_to_url class_path, @relative_base_path}#{attribute})  "
  end

  # @default
  def default_for_property(property)
    match_data = /@default\s*(.*)/.match property[:docString]
    match_data.nil? ? "" : match_data[1]
  end

  # @params
  def comment_for_param(param_name, docString)
    match_data = /@param\s*(#{param_name})\s(.*)/.match docString
    match_data.nil? ? "" : match_data[2]
  end

  # @return
  def comment_for_return(return_description)
    match_data = /@return\s*(.*)/.match return_description
    match_data.nil? ? "" : match_data[1]
  end

  # @throws
  def comment_for_throws(str)
    match_data = /@throws\s*(\S*)\s*(.*)/.match str
    match_data.nil? ? "" : "#{match_data[1]} #{match_data[2]}"
  end

  # @deprecated
  def deprecated(str)
    match_data = /@deprecated\s*(.*)/.match str
    match_data.nil? ? "" : "<span class='deprecated-property' title='#{match_data[1]}'>deprecated </span>"
  end

  def markdown(text, allow_html=false)
    renderer_options = {
      :hard_wrap => false,
      :with_toc_data => true,
      :filter_html => true
    }

    renderer = HTMLwithPygments.new(renderer_options)

    options = {
      :autolink => true,
      :no_intra_emphasis => true,
      :fenced_code_blocks => true,
      :lax_html_blocks => true,
      :strikethrough => true,
      :superscript => true,
      :tables => true
    }

    Redcarpet::Markdown.new(renderer, options).render(text)
  end
end

#markdown
class HTMLwithPygments < Redcarpet::Render::HTML
  require 'digest/sha1'

  def block_code(code, language)
    if language && Pygments::Lexer.find(language.downcase)
      lexer = language.downcase
    else
      puts "Pygments :: Unknown lexer #{language}, setting to text"
      lexer = "text"
    end
    Pygments.highlight(code, :lexer => lexer)
  end
end
