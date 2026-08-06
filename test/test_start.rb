require 'common'

class StartTest < Net::SFTP::TestCase
  def test_with_block
    ssh = mock('ssh')
    ssh.expects(:close)
    Net::SSH.expects(:start).with('host', 'user', {}).returns(ssh)

    sftp = mock('sftp')
    # TODO: figure out how to verify a block is passed, and call it later.
    # I suspect this is hard to do properly with mocha.
    Net::SFTP::Session.expects(:new).with(ssh, nil, min_version: nil).returns(sftp)
    sftp.expects(:connect!).returns(sftp)
    sftp.expects(:loop)
    
    Net::SFTP.start('host', 'user') do
      # NOTE: currently not called!
    end
  end
  
  def test_with_block_and_options
    ssh = mock('ssh')
    ssh.expects(:close)
    # Net::SFTP.start passes ssh_options positionally, so the expectation must
    # be a braced Hash rather than keywords (mocha strict keyword matching).
    Net::SSH.expects(:start).with('host', 'user', { auth_methods: ["password"] }).returns(ssh)

    sftp = mock('sftp')
    Net::SFTP::Session.expects(:new).with(ssh, 3, min_version: nil).returns(sftp)
    sftp.expects(:connect!).returns(sftp)
    sftp.expects(:loop)
    
    Net::SFTP.start('host', 'user', {auth_methods: ["password"]}, {version: 3}) do
      # NOTE: currently not called!
    end
  end
end
