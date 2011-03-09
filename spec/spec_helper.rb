$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'rspec'

require 'mm-multi-parameter-attributes'

MongoMapper.database = 'mm-multi-parameter-attributes-spec'

class Topic
  include MongoMapper::Document
  
  plugin MongoMapper::Plugins::MultiParameterAttributes
  
  key :title,       String
  key :last_read,   Date
  key :written_on,  Time
end

RSpec.configure do |config|
end
