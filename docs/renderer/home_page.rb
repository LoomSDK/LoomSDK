require 'erb'
require File.expand_path('../page', __FILE__)

class HomePage < DocumentationPage
  include Module::Commentable

  def initialize(version_number, relative_path)
    @version_number = version_number
    @relative_base_path = relative_path
  end

end
