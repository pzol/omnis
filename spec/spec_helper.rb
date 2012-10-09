require 'bundler/setup'
Bundler.require :test

ENV['TZ'] = "CET" # make sure all tests are in the same timezone
$LOAD_PATH << File.expand_path('../../lib', __FILE__)
