# frozen_string_literal: true

require 'net/sftp/errors'

module Net; module SFTP; module Protocol

  # Helpers for parsing server-supplied, length-prefixed sequences safely.
  #
  # Several SFTP structures are encoded as a 32-bit count followed by that many
  # items. The count is chosen entirely by the server and can be up to
  # 4,294,967,295. Net::SSH::Buffer clamps reads at end-of-buffer and returns
  # nil rather than raising, so a loop driven by an unchecked count does not
  # terminate early on truncated input -- it just spins, allocating, until the
  # client runs out of memory or patience. A four-byte field is therefore
  # enough for a hostile server to hang or OOM-kill a client.
  #
  # Every such count must be checked against the number of bytes actually
  # remaining in the buffer: a count larger than the buffer could possibly
  # hold cannot be legitimate.
  module BoundedRead
    # Reads a 32-bit item count and validates it against the bytes remaining in
    # +buffer+. +min_item_size+ is the smallest number of bytes a single item
    # can occupy on the wire.
    #
    # Raises Net::SFTP::Exception if the count is missing or could not possibly
    # be satisfied by the remaining data.
    def read_bounded_count!(buffer, min_item_size, what)
      count = buffer.read_long

      if count.nil?
        raise Net::SFTP::Exception, "truncated packet: missing #{what} count"
      end

      maximum = buffer.available / min_item_size
      if count > maximum
        raise Net::SFTP::Exception,
              "server reported #{count} #{what} entries but sent only #{buffer.available} bytes " \
              "(at most #{maximum} possible)"
      end

      count
    end
  end

end; end; end
