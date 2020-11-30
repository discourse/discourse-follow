# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  root "plugins/discourse-follow"
  track_files "plugins/discourse-follow/**/*.rb"
  add_filter { |src| src.filename =~ /(\/spec\/|\/db\/|plugin\.rb)/ }
end

require 'rails_helper'
