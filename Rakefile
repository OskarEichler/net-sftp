# frozen_string_literal: true

require "rake"
require "rake/clean"
require "bundler/gem_tasks"

desc "When releasing make sure NET_SSH_BUILDGEM_SIGNED is set"
task :check_NET_SSH_BUILDGEM_SIGNED do
  raise "NET_SSH_BUILDGEM_SIGNED should be set to release" unless ENV['NET_SSH_BUILDGEM_SIGNED']
end

Rake::Task[:release].enhance [:check_NET_SSH_BUILDGEM_SIGNED]

task :default => ["build"]
CLEAN.include [ 'pkg', 'rdoc' ]
name = "net-sftp"

require_relative "lib/net/sftp/version"
version = Net::SFTP::Version::CURRENT

namespace :cert do
  desc "Update public cert from private - only run if public is expired"
  task :update_public_when_expired do
    require 'openssl'
    require 'time'
    raw = File.read "net-sftp-public_cert.pem"
    certificate = OpenSSL::X509::Certificate.new raw
    raise "Not yet expired: #{certificate.not_after}" unless certificate.not_after < Time.now
    # `gem cert` coerces --days with to_i, so an expression like "365*5" would
    # silently become 365. Pass the literal day count.
    sh "gem cert --build netssh@solutious.com --days 1825 --private-key /mnt/gem/net-ssh-private_key.pem"
    sh "mv gem-public_cert.pem net-sftp-public_cert.pem"
    sh "gem cert --add net-sftp-public_cert.pem"
  end
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs = ["lib", "test"]
end

# rdoc stopped being a default gem in Ruby 4.0, so it may legitimately be
# absent. Only define the documentation tasks when it can be loaded, rather
# than letting a missing gem break `rake test`.
begin
  require "rdoc/task"
rescue LoadError
  desc "Build documentation (unavailable: the rdoc gem is not installed)"
  task :rdoc do
    abort "The rdoc gem is not installed. Run `gem install rdoc` or add it to your Gemfile."
  end
else
  extra_files = %w[LICENSE.txt THANKS.txt CHANGES.txt ]
  RDoc::Task.new do |rdoc|
    rdoc.rdoc_dir = "rdoc"
    rdoc.title = "#{name} #{version}"
    rdoc.main = 'README.rdoc'
    rdoc.rdoc_files.include("README*")
    rdoc.rdoc_files.include("bin/*.rb")
    rdoc.rdoc_files.include("lib/**/*.rb")
    extra_files.each { |file|
      rdoc.rdoc_files.include(file) if File.exist?(file)
    }
  end
end
