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
      logs = $_db[:backend_errors]
      $_logger.error "[MODEL] #{e.class.name}: #{e.message}"

      # logs.insert(
      #   method: 'deflate document data',
      #   path: 'na',
      #   params: self.id,
      #   frontend_version: 'na',
      #   backend_version: $_version,
      #   type: e.class.name,
      #   backtrace: e.backtrace,
      #   message: e.message + ' (tried deflating non deflated document)',
      #   created_at: Time.now
      # )
    else
      self.document = encoded
    end

    # TODO: compress serialised document
  end

  def values
    vals = super
    vals[:document] = self.document
    vals
  end

  def document
    begin
      decoded = Zlib::Inflate.inflate Base64.decode64(self[:document])
    rescue Zlib::DataError => e
      logs = $_db[:backend_errors]
      $_logger.error "[MODEL] #{e.class.name}: #{e.message}"

      # logs.insert(
      #   method: 'inflate document data',
      #   path: 'na',
      #   params: self.id,
      #   frontend_version: 'na',
      #   backend_version: $_version,
      #   type: e.class.name,
      #   backtrace: e.backtrace,
      #   message: e.message + ' (tried inflating non inflated document)',
      #   created_at: Time.now
      # )
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
