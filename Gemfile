source 'http://rubygems.org'

gem 'rake'

base_path = Pathname.new(File.dirname(__FILE__))
relative_to_base = base_path.relative_path_from(Pathname.new(Dir.pwd))
eval File.read(File.join(relative_to_base, 'docs', 'Gemfile'))