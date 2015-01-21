require 'erb'
require File.expand_path('../page', __FILE__)

class ExampleIndex < DocumentationPage
  include Module::Commentable

  def initialize(examples, version_number, relative_path)
    @examples = examples
    @version_number = version_number
    @relative_base_path = relative_path
  end

end
