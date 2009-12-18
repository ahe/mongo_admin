begin
  require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
rescue LoadError
  puts "You need to install rspec in your base app"
  exit
end

plugin_spec_dir = File.dirname(__FILE__)

class Announce
  include MongoMapper::Document
  key :title, String
  key :price, Float
  key :year, Integer
  key :published, Boolean
  key :created_at, Time
  
  many :offers
  many :pictures
end

class Offer
  include MongoMapper::Document  
  belongs_to :announce
  
  key :announce_id, ObjectId
  key :price, Float
end

class Picture
  include MongoMapper::EmbeddedDocument
  key :name, String
end