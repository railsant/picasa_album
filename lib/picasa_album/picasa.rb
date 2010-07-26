require 'httparty'
require 'hpricot'

module PicasaAlbum
  class Picasa
    class << self
      def create_album(title, summary, location, access)
        request_body = "<entry xmlns='http://www.w3.org/2005/Atom' xmlns:media='http://search.yahoo.com/mrss/' xmlns:gphoto='http://schemas.google.com/photos/2007'>
          <title type='text'>#{title}</title>
          <summary type='text'>#{summary}</summary>
          <gphoto:location>#{location}</gphoto:location>
          <gphoto:access>#{access}</gphoto:access>
          <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/photos/2007#album'></category>
        </entry>"
        response = HTTParty.post("http://picasaweb.google.com/data/feed/api/user/#@@username",
          :headers => {'Content-type' => 'application/atom+xml', 'Authorization' => "GoogleLogin auth=#@@auth"},
          :body => request_body
        )
        raise response.inspect
        raise PicasaAlbum::Picasa::ConnectionFailure unless response && (doc = Hpricot(response.body))
        
        album_url = doc.at('id').inner_html
        raise PicasaAlbum::Picasa::ConnectionFailure unless match_data = album_url.match(/.*\/albumid\/(.*)/)
        match_data[1]
      end
      
      def get_photos(album_id, options = {})
        query = options.inject([]) {|a, (k, v)| a << "#{k.to_s}=#{v}"}.join('&')
        query = "?#{query}" unless query.blank?
        photos = []
        if response = HTTParty.get("http://picasaweb.google.com/data/feed/api/user/#@@username/albumid/#{album_id}#{query}")
          doc = Hpricot(response.body)
          doc.search('entry').each do |entry|
            photo = Photo.new(entry.at('media:content').attributes.to_hash)
            thumbnails = []
            entry.search('media:thumbnail').each do |thumbnail|
              thumbnails << Thumbnail.new(thumbnail.attributes.to_hash)
            end
            photo.thumbnails = thumbnails
            photos << photo
          end
        end
        photos
      end
      
      def connect
        response = HTTParty.post('https://www.google.com/accounts/ClientLogin',
          :headers => {'Content-type' => 'application/x-www-form-urlencoded'},
          :body => {
            'accountType' => 'HOSTED_OR_GOOGLE',
            'Email' => @@username,
            'Passwd' => @@password,
            'service' => 'lh2',
            'source' => 'RailsPlugin-PicasaAlbum-1.0'
          }
        )
        raise PicasaAlbum::Picasa::ConnectionFailure unless response && response.message == 'OK' && (match_data = response.match(/SID=(.*?)\sLSID=(.*?)\sAuth=(.*?)\s/))
        @@sid, @@lsid, @@auth = match_data[1..3]
      end
      
      def config(options = {})
        @@username = options[:username]
        @@password = options[:password]
        connect
      end
      
      def username
        @@username
      end
      
      def password
        @@password
      end
      
      def auth
        @@auth
      end
    end
    
    class ConnectionFailure < Exception; end
  end
end