source 'https://rubygems.org'

# Specify your gem's dependencies in net-sftp.gemspec
gemspec

# TODO: add to gemspec
gem "rake", ">= 13.0"

gem 'byebug', group: %i[development test] if !Gem.win_platform? && RUBY_ENGINE == "ruby"

gem 'bundler-audit', require: false, group: :development

# rdoc is no longer a default gem as of Ruby 4.0; the Rakefile's doc tasks
# need it declared explicitly.
gem 'rdoc', require: false, group: :development

if ENV["CI"]
  gem 'simplecov', require: false, group: :test
end
