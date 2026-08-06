# frozen_string_literal: true

require 'net/ssh'
require 'net/sftp/session'

module Net

  # Net::SFTP is a pure-Ruby module for programmatically interacting with a
  # remote host via the SFTP protocol (that's SFTP as in "Secure File Transfer
  # Protocol" produced by the Secure Shell Working Group, not "Secure FTP"
  # and certainly not "Simple FTP").
  #
  # See Net::SFTP#start for an introduction to the library. Also, see
  # Net::SFTP::Session for further documentation.
  module SFTP
    # A convenience method for starting a standalone SFTP session. It will
    # start up an SSH session using the given arguments (see the documentation
    # for Net::SSH::Session for details), and will then start a new SFTP session
    # with the SSH session. This will block until the new SFTP is fully open
    # and initialized before returning it.
    #
    #   sftp = Net::SFTP.start("localhost", "user")
    #   sftp.upload! "/local/file.tgz", "/remote/file.tgz"
    #
    # If a block is given, it will be passed to the SFTP session and will be
    # called once the SFTP session is fully open and initialized. When the
    # block terminates, the new SSH session will automatically be closed.
    #
    #   Net::SFTP.start("localhost", "user") do |sftp|
    #     sftp.upload! "/local/file.tgz", "/remote/file.tgz"
    #   end
    #
    # Extra parameters can be passed:
    # - The Net::SSH connection options (see Net::SSH for more information)
    # - The Net::SFTP connection options:
    #   - :version     - the SFTP protocol version to offer to the server
    #   - :min_version - refuse the session if the server negotiates a
    #     protocol version below this. The server alone chooses the negotiated
    #     version, so without this it can silently downgrade the client to
    #     protocol 1.
    def self.start(host, user, ssh_options={}, sftp_options={}, &block)
      session = Net::SSH.start(host, user, ssh_options)
      version = sftp_options.fetch(:version, nil)
      min_version = sftp_options.fetch(:min_version, nil)
      sftp = Net::SFTP::Session.new(session, version, min_version: min_version, &block).connect!

      if block_given?
        sftp.loop
        session.close
        return nil
      end

      sftp
    rescue ::Exception => anything
      # Deliberately broad: an Interrupt or a Timeout::Error part-way through
      # setup must still tear down the SSH session before propagating. Nothing
      # is swallowed -- the original exception is always re-raised.
      #
      # session is nil if Net::SSH.start itself raised, in which case there is
      # nothing to shut down.
      if session
        begin
          session.shutdown!
        rescue ::StandardError => shutdown_error
          # A failure to shut down must not mask the exception that got us
          # here, but it should not vanish silently either.
          warn "net-sftp: error while shutting down session after #{anything.class}: #{shutdown_error.message}"
        end
      end

      raise anything
    end
  end

end

class Net::SSH::Connection::Session
  # A convenience method for starting up a new SFTP connection on the current
  # SSH session. Blocks until the SFTP session is fully open, and then
  # returns the SFTP session.
  #
  #   Net::SSH.start("localhost", "user", :password => "password") do |ssh|
  #     ssh.sftp.upload!("/local/file.tgz", "/remote/file.tgz")
  #     ssh.exec! "cd /some/path && tar xf /remote/file.tgz && rm /remote/file.tgz"
  #   end
  def sftp(wait=true)
    @sftp ||= begin
      sftp = Net::SFTP::Session.new(self)
      sftp.connect! if wait
      sftp
    end
  end
end
