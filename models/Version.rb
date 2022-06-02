require 'digest'
require 'zlib'
require_relative '../services/processor/DocumentProcessor'

class Version < Sequel::Model
  many_to_one :user
  many_to_one :variant
  one_to_many :versions
  one_to_many :comments

  def before_save
    super
    begin
      encoded = Base64.encode64 Zlib::Deflate.deflate(document)
    rescue Zlib::DataError => e
      # logs = $_db[:backend_errors]
      $_logger.error "[MODEL] #{e.class.name}: #{e.message}"
    else
      self.document = encoded
    end

    # TODO: compress serialised document
  end

  def values
    vals = super
    vals[:document] = self.document.force_encoding("UTF-8") # TODO war das nur für den Test notwendig??
    vals
  end

  # Override to transparently get the dezipped document data since Versions save their documents encoded int he database
  def document
    begin # decode
      decoded = Zlib::Inflate.inflate Base64.decode64(self[:document])
    rescue Zlib::DataError => e # data already decoded, or at least no zip
      super
    else
      decoded
    end
  end

  def after_save
    super
    if file_name.nil?
      update(file_name: DocumentProcessor.new(self).save_files)
      variant.update(current_file_name: file_name)
    end
  end
end
