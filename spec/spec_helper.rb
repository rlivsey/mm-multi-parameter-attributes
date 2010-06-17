$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
gem 'rspec'

require 'mm-multi-parameter-attributes'
require 'spec'

MongoMapper.database = 'mm-multi-parameter-attributes-spec'

class Topic
  include MongoMapper::Document
  
  plugin MongoMapper::Plugins::MultiParameterAttributes
  
  key :title,       String
  key :last_read,   Date
  key :written_on,  Time
end

Spec::Runner.configure do |config|
end
