# PicasaAlbum
module PicasaAlbum
  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
    base.send :initialize_picasa_setting
  end

  module ClassMethods
    def picasa_album_config
      @@picasa_album_config
    end

    def set_picasa_album_id(method = :picasa_album_id)
      @@picasa_album_config[:id] = method
    end

    def set_picasa_album_title(method = :picasa_album_title)
      @@picasa_album_config[:title] = method
    end

    def set_picasa_album_summary(method = :picasa_album_summary)
      @@picasa_album_config[:summary] = method
    end

    def set_picasa_album_location(method = :picasa_album_location)
      @@picasa_album_config[:location] = method
    end

    def initialize_picasa_setting
      @@picasa_album_config = {}
      set_picasa_album_id
      set_picasa_album_title
      set_picasa_album_summary
      set_picasa_album_location
    end
  end

  module InstanceMethods
    def photos(options = {})
      album_id = self.send(self.class.picasa_album_config[:id])
      PicasaAlbum::Picasa.get_photos(album_id, options)
    end

    def create_album
      title = self.send(self.class.picasa_album_config[:title])
      summary = self.send(self.class.picasa_album_config[:summary])
      location = self.send(self.class.picasa_album_config[:location])
      self.send("#{self.class.picasa_album_config[:id].to_s}=", PicasaAlbum::Picasa.create_album(title, summary, location, 'public'))
      self.save
      self.send(self.class.picasa_album_config[:id])
    end

    def upload_photo(image_file)
      raise PicasaAlbum::Picasa::NoAlbumError unless self.album_id
      PicasaAlbum::Picasa.upload_photo(self.album_id, image_file)
    end
  end
end

