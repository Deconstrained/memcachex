# https://code.google.com/p/memcached/wiki/MemcacheBinaryProtocol

defmodule Memcache.Protocol do
  import Memcache.BinaryUtils

  def to_binary(:QUIT) do
    bcat([<< 0x80 >>, opb(:QUIT), << 0x00 :: size(16) >>,
          << 0x00 >>, << 0x00 >>, << 0x0000 :: size(16) >>,
          << 0x00 :: size(32) >>, << 0x00 :: size(32) >>,
          << 0x00 :: size(64) >> ])
  end

  def to_binary(command) do
    to_binary(command, 0)
  end

  def to_binary(:GET, key) do
    bcat([<< 0x80 >>, opb(:GET)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) :: size(32) >> <>
    bcat([<< 0x00 :: size(32) >>, << 0x00 :: size(64) >>]) <>
    key
  end

  def to_binary(:DELETE, key) do
    bcat([<< 0x80 >>, opb(:DELETE)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) :: size(32) >> <>
    bcat([<< 0x00 :: size(32) >>, << 0x00 :: size(64) >>]) <>
    key
  end

  def to_binary(:FLUSH, 0) do
    bcat([<< 0x80 >>, opb(:FLUSH), << 0x00 :: size(16) >>,
          << 0x00 >>, << 0x00 >>, << 0x0000 :: size(16) >>,
          << 0x00 :: size(32) >>, << 0x00 :: size(32) >>,
          << 0x00 :: size(64) >>])
  end

  def to_binary(:FLUSH, expiry) do
    bcat([<< 0x80 >>, opb(:FLUSH), << 0x00 :: size(16) >>,
          << 0x04 >>, << 0x00 >>, << 0x0000 :: size(16) >>,
          << 0x04 :: size(32) >>, << 0x00 :: size(32) >>,
          << 0x00 :: size(64) >> ]) <>
    << expiry :: size(32) >>
  end

  def to_binary(command, key) do
    to_binary(command, key, 0)
  end

  def to_binary(command, key, value) do
    to_binary(command, key, value, 0, 0, 0)
  end

  def to_binary(command, key, value, cas) do
    to_binary(command, key, value, cas, 0, 0)
  end

  def to_binary(command, key, value, cas, flag) do
    to_binary(command, key, value, cas, flag, 0)
  end

  def to_binary(:INCREMENT, key, delta, initial, cas, expiry) do
    bcat([<< 0x80 >>, opb(:INCREMENT)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x14 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 20 :: size(32) >> <>
    << 0x00 :: size(32) >> <>
    << cas :: size(64) >> <>
    << delta :: size(64) >> <>
    << initial :: size(64) >> <>
    << expiry :: size(32) >> <>
    key
  end

  def to_binary(:DECREMENT, key, delta, initial, cas, expiry) do
    bcat([<< 0x80 >>, opb(:DECREMENT)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x14 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 20 :: size(32) >> <>
    << 0x00 :: size(32) >> <>
    << cas :: size(64) >> <>
    << delta :: size(64) >> <>
    << initial :: size(64) >> <>
    << expiry :: size(32) >> <>
    key
  end

  def to_binary(:SET, key, value, cas, flag, expiry) do
    bcat([<< 0x80 >>, opb(:SET)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x08 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 8 + byte_size(value) :: size(32) >> <>
    << 0x00 :: size(32) >> <>
    << cas :: size(64) >> <>
    << flag :: size(32) >> <>
    << expiry :: size(32) >> <>
    key <>
    value
  end

  def to_binary(:ADD, key, value, cas, flag, expiry) do
    bcat([<< 0x80 >>, opb(:ADD)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x08 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 8 + byte_size(value) :: size(32) >> <>
    << 0x00 :: size(32) >> <>
    << cas :: size(64) >> <>
    << flag :: size(32) >> <>
    << expiry :: size(32) >> <>
    key <>
    value
  end

  def to_binary(:REPLACE, key, value, cas, flag, expiry) do
    bcat([<< 0x80 >>, opb(:REPLACE)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x08 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 8 + byte_size(value) :: size(32) >> <>
    << 0x00 :: size(32) >> <>
    << cas :: size(64) >> <>
    << flag :: size(32) >> <>
    << expiry :: size(32) >> <>
    key <>
    value
  end

  defrecordp :header, [ :opcode, :key_length, :extra_length, :data_type, :status, :total_body_length, :opaque, :cas ]

  def parse_header(<<
                   0x81 :: size(8),
                   opcode :: size(8),
                   key_length :: size(16),
                   extra_length :: size(8),
                   data_type :: size(8),
                   status :: size(16),
                   total_body_length :: size(32),
                   opaque :: size(32),
                   cas :: size(64)
                   >>) do
    header(opcode: opcode, key_length: key_length, extra_length: extra_length, data_type: data_type, status: status, total_body_length: total_body_length, opaque: opaque, cas: cas)
  end

  def total_body_size(header(total_body_length: size)) do
    size
  end

  def parse_body(header(status: 0x0000, opcode: op(:GET), extra_length: extra_length, total_body_length: total_body_length), rest) do
    value_size = (total_body_length - extra_length)
    << _extra :: bsize(extra_length),  value :: bsize(value_size) >> = rest
    { :ok, value }
  end

  def parse_body(header(status: 0x0000, opcode: op(:INCREMENT)), rest) do
    << value :: size(64) >> = rest
    { :ok, value }
  end

  def parse_body(header(status: 0x0000, opcode: op(:DECREMENT)), rest) do
    << value :: size(64) >> = rest
    { :ok, value }
  end

  defparse_empty(:SET)
  defparse_empty(:ADD)
  defparse_empty(:REPLACE)
  defparse_empty(:DELETE)
  defparse_empty(:QUIT)
  defparse_empty(:FLUSH)

  defparse_error(0x0001, "Key not found")
  defparse_error(0x0002, "Key exists")
  defparse_error(0x0003, "Value too large")
  defparse_error(0x0004, "Invalid arguments")
  defparse_error(0x0005, "Item not stored")
  defparse_error(0x0006, "Incr/Decr on non-numeric value")
  defparse_error(0x0081, "Unknown command")
  defparse_error(0x0082, "Out of memory")
end
