require 'simplecov'

SimpleCov.configure do
  add_filter do |src|
    src.filename !~ /discourse-follow/ ||
    src.filename =~ /spec/
  end
end
