require "common"
require "net/sftp/protocol/01/attributes"
require "net/sftp/protocol/01/base"
require "net/sftp/protocol/04/attributes"
require "net/sftp/protocol/04/base"

# Several SFTP structures are a server-supplied 32-bit count followed by that
# many items. Net::SSH::Buffer clamps reads at end-of-buffer and returns nil
# rather than raising, so an unchecked count does not terminate the loop early
# on truncated input -- a four-byte field is enough to hang or OOM-kill the
# client. Each parser must reject a count the remaining bytes cannot satisfy.
class ParserLimitsTest < Net::SFTP::TestCase
  # Deliberately large enough that the unbounded implementations took visible
  # wall-clock time (~0.6s for the ACL case) and allocated 500k objects.
  ABSURD_COUNT = 500_000

  # Every parser must fail fast rather than grinding through the count. Well
  # under a second on any machine that can run the rest of this suite.
  TIME_LIMIT = 0.5

  def test_parse_acl_rejects_count_larger_than_remaining_bytes
    # An ACL string containing only a count, and no entries at all.
    acl_payload = [ABSURD_COUNT].pack("N")
    buffer = Net::SSH::Buffer.new([acl_payload.bytesize].pack("N") + acl_payload)

    error = assert_faster_than(TIME_LIMIT) do
      assert_raises(Net::SFTP::Exception) do
        Net::SFTP::Protocol::V04::Attributes.send(:parse_acl, buffer)
      end
    end

    assert_match(/ACL/, error.message)
  end

  def test_parse_extended_rejects_count_larger_than_remaining_bytes
    buffer = Net::SSH::Buffer.new([ABSURD_COUNT].pack("N"))

    error = assert_faster_than(TIME_LIMIT) do
      assert_raises(Net::SFTP::Exception) do
        Net::SFTP::Protocol::V01::Attributes.send(:parse_extended, buffer)
      end
    end

    assert_match(/extended attribute/, error.message)
  end

  def test_parse_name_packet_v1_rejects_count_larger_than_remaining_bytes
    driver = Net::SFTP::Protocol::V01::Base.new(stub(:logger => nil))
    packet = Net::SFTP::Packet.new([0, ABSURD_COUNT].pack("CN"))

    error = assert_faster_than(TIME_LIMIT) do
      assert_raises(Net::SFTP::Exception) { driver.parse_name_packet(packet) }
    end

    assert_match(/name/, error.message)
  end

  def test_parse_name_packet_v4_rejects_count_larger_than_remaining_bytes
    driver = Net::SFTP::Protocol::V04::Base.new(stub(:logger => nil))
    packet = Net::SFTP::Packet.new([0, ABSURD_COUNT].pack("CN"))

    error = assert_faster_than(TIME_LIMIT) do
      assert_raises(Net::SFTP::Exception) { driver.parse_name_packet(packet) }
    end

    assert_match(/name/, error.message)
  end

  def test_missing_count_is_reported_as_truncation
    error = assert_raises(Net::SFTP::Exception) do
      Net::SFTP::Protocol::V01::Attributes.send(:parse_extended, Net::SSH::Buffer.new(""))
    end

    assert_match(/truncated packet/, error.message)
  end

  # Counts that the buffer really can satisfy must still parse normally.
  def test_well_formed_extended_attributes_still_parse
    payload = Net::SSH::Buffer.from(:long, 2,
                                    :string, "a", :string, "1",
                                    :string, "b", :string, "2")

    extended = Net::SFTP::Protocol::V01::Attributes.send(:parse_extended, payload)
    assert_equal({ "a" => "1", "b" => "2" }, extended)
  end

  def test_well_formed_acl_still_parses
    entries = Net::SSH::Buffer.from(:long, 1, :long, 1, :long, 2, :long, 3, :string, "bob").to_s
    buffer  = Net::SSH::Buffer.from(:string, entries)

    acl = Net::SFTP::Protocol::V04::Attributes.send(:parse_acl, buffer)
    assert_equal 1, acl.length
    assert_equal [1, 2, 3, "bob"], acl.first.to_a
  end

  def test_session_rejects_oversized_packet_length
    oversized = Net::SFTP::Session::MAX_PACKET_LENGTH + 1

    expect_sftp_session :server_version => 3 do |channel|
      channel.gets_data([oversized].pack("N"))
    end

    Net::SSH::Test::Extensions::IO.with_test_extension do
      # The oversized header arrives with the version handshake, so this is
      # raised out of connect! rather than a later loop iteration.
      error = assert_raises(Net::SFTP::Exception) { sftp.connect! }
      assert_match(/oversized packet/, error.message)
    end
  end

  private

    def assert_faster_than(seconds)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result  = yield
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

      assert_operator elapsed, :<, seconds,
                      "parser took #{elapsed.round(3)}s; it should reject the count without iterating"
      result
    end
end
