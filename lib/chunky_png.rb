require 'set'
require 'zlib'

require 'chunky_png/datastream'
require 'chunky_png/chunk'
require 'chunky_png/palette'
require 'chunky_png/pixel'
require 'chunky_png/pixel_matrix/encoding'
require 'chunky_png/pixel_matrix/decoding'
require 'chunky_png/pixel_matrix'
require 'chunky_png/image'

module ChunkyPNG
  extend self

  def load_from_io(io)
    ChunkyPNG::Datastream.read(io)
  end

  def load_from_file(file)
    File.open(file, 'r') { |f| load_from_io(f) }
  end

  def load_from_memory(string)
    load_from_io(StringIO.new(string))
  end

  def load(arg)
    if arg.respond_to?(:read)
      load_from_io(arg)
    elsif File.exists?(arg)
      load_from_file(arg)
    else
      load_from_memory(arg)
    end
  end
end
