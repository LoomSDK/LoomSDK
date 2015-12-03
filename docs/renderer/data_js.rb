class DataJs
  def render(path)
    template_src = File.read(path)
    template = ERB.new(template_src)
    result = template.result(binding)
  end

  def first_sentence( str )
    result = str.split(/\.(\s+|<\/p>)/).first
    result.nil? ? '' : result.strip
  end

  def abbr_path( str )
    str.split( '.' ).last
  end

  def is_static( str )
    str.include? 'static'
  end

  def is_native( str )
    str.include? 'native'
  end

  def is_getter ( hash )
    hash.has_key? :getter
  end

  def is_setter ( hash )
    hash.has_key? :setter
  end

  def search_object_string
    $search_json
  end

  def breadcrumbs
    ''
  end
end
