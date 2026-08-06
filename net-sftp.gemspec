# frozen_string_literal: true

require_relative 'lib/net/sftp/version'

Gem::Specification.new do |spec|
  spec.name          = "net-sftp"
  spec.version       = Net::SFTP::Version::STRING
  spec.authors       = ["Jamis Buck", "Delano Mandelbaum", "Mikl\u{f3}s Fazekas"]
  spec.email         = ["net-ssh@solutious.com"]

  if ENV['NET_SSH_BUILDGEM_SIGNED']
    spec.cert_chain = ["net-sftp-public_cert.pem"]
    spec.signing_key = "/mnt/gem/net-ssh-private_key.pem"
  end

  spec.summary       = %q{A pure Ruby implementation of the SFTP client protocol.}
  spec.description   = %q{A pure Ruby implementation of the SFTP client protocol}
  spec.homepage      = "https://github.com/net-ssh/net-sftp"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]

  # setup.rb is a 2004-era vendored installer that is no longer part of this
  # gem; reject it explicitly so a stale working copy cannot reintroduce it.
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/|^setup\.rb$}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency("net-ssh", ">= 5.0.0", "< 8.0.0")

  # Upper bounds so that a future major release of the test tooling cannot
  # silently break the suite; both currently resolve to their newest release.
  spec.add_development_dependency("minitest", ">= 5.0", "< 7.0")
  spec.add_development_dependency("mocha", "~> 2.0")
end
