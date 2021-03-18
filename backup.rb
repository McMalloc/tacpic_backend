require 'net/sftp'
require 'zip'
require 'date'
require 'logger'
require 'digest'
require_relative 'services/mail/mail'

def getSizeinKB(path)
  (File.size(path) / 1000).to_i.to_s + 'KB'
end

def backup
  timestamp = DateTime.now.strftime '%Y-%m-%d_%H-%M-%S'
  log_file = File.join ENV['APPLICATION_BASE'], "backups/#{timestamp}_backup.log"
  logger = Logger.new log_file
  logger.info "Starting backup at #{timestamp} in #{ENV['RACK_ENV']}"
  Dir.mkdir 'backups' unless Dir.exist? 'backups'

  dump_file = File.join ENV['APPLICATION_BASE'], "/backups/#{timestamp}__#{ENV['RACK_ENV']}-dump.sql"
  system "pg_dump #{ENV['TACPIC_DATABASE_URL']} -f #{dump_file}",
         exception: true
  logger.info "[psql] #{`psql #{ENV['TACPIC_DATABASE_URL']} -c '\\c'`}"
  logger.info "Created database dump #{dump_file}"
  logger.info "  file size: #{getSizeinKB dump_file}"
  logger.info "  file hash: #{Digest::MD5.hexdigest File.open(dump_file).read}"

  files_name = File.join ENV['APPLICATION_BASE'], "./backups/#{timestamp}__files.zip"
  logger.info "Creating archive #{files_name} ..."
  before_files_zip = Time.now
  Zip::File.open(files_name, Zip::File::CREATE) do |zipfile|
    counter = 1
    Dir['./files/*'].each do |file|
      zipfile.add "#{File.basename(file)}.#{File.extname(file)}", file unless File.directory? file
      counter += 1
    end
    logger.info "  Done! Added #{counter} file/s to the archive"
  end
  logger.info "  size: #{getSizeinKB files_name}"
  logger.info "  time: #{Time.now - before_files_zip}s"

  thumbnails_name = File.join ENV['APPLICATION_BASE'], "./backups/#{timestamp}__thumbnails.zip"
  logger.info "Creating archive #{thumbnails_name} ..."
  before_thumbnails_zip = Time.now
  Zip::File.open(thumbnails_name, Zip::File::CREATE) do |zipfile|
    counter = 1
    Dir['./public/thumbnails/*'].each do |file|
      zipfile.add "#{File.basename(file)}.#{File.extname(file)}", file unless File.directory? file
      counter += 1
    end
    logger.info "  Done! Added #{counter} file/s to the archive"
  end
  logger.info "  size: #{getSizeinKB thumbnails_name}"
  logger.info "  time: #{Time.now - before_thumbnails_zip}s"

  logger.info "Attempting SFTP connection to #{ENV['BACKUP_HOST']}:#{ENV['BACKUP_PORT']}"

  Net::SFTP.start(ENV['BACKUP_HOST'], ENV['BACKUP_USER'], password: ENV['BACKUP_PWD'],
                                                          port: ENV['BACKUP_PORT']) do |sftp|
    logger.info 'Connection established. Uploading files ...'
    before_upload = Time.now
    sftp.upload!(dump_file, "/#{timestamp}__#{ENV['RACK_ENV']}-dump.sql")
    sftp.upload!(files_name, "/#{timestamp}__files.zip")
    sftp.upload!(thumbnails_name, "/#{timestamp}__thumbnails.zip")
    sftp.upload!(log_file, "/#{timestamp}.log")
    logger.info '  Done!'
    logger.info "  time: #{Time.now - before_upload}s"
  end
rescue StandardError
  logger.error $!

  SMTP.init
  Mail.deliver do
    from     'system@tacpic.de'
    to       'robert@tacpic.de'
    subject  'Error during backup'
    body     ''
    add_file log_file
  end
end
