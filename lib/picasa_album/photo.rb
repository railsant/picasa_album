require 'ostruct'

module PicasaAlbum
  class Photo < OpenStruct
    attr_accessor :thumbnails
  end
end