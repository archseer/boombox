require 'bundler/setup'
Bundler.require
require 'active_support/core_ext'
require 'fileutils'

require_relative 'web_interface'

MongoMapper.database = "boombox"

EM.run do
  WebInterface.run! :port => 8080
end