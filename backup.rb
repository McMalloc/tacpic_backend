require 'net/sftp'
require 'zip'
require 'date'

def backup
  timestamp = DateTime.now.strftime('%Y-%m-%d_%H-%M-%S')
  Dir.mkdir 'backups' unless Dir.exist? 'backups'
  `pg_dump #{ENV['TACPIC_DATABASE_URL']} -f ./backups/#{timestamp}__#{ENV['RACK_ENV']}-dump.sql`

  files_name = "./backups/#{timestamp}__files.zip"
  Zip::File.open(files_name, Zip::File::CREATE) do |zipfile|
    Dir['./files/*'].each do |file|
      unless File.directory? file
        zipfile.add "#{File.basename(file)}.#{File.extname(file)}", file
      end
    end
  end

  thumbnails_name = "./backups/#{timestamp}__thumbnails.zip"
  Zip::File.open(thumbnails_name, Zip::File::CREATE) do |zipfile|
    Dir['./files/thumbnails/*'].each do |file|
      unless File.directory? file
        zipfile.add "#{File.basename(file)}.#{File.extname(file)}", file
      end
    end
  end

  Net::SFTP.start(ENV['BACKUP_HOST'], ENV['BACKUP_USER'], password: ENV['BACKUP_PWD'], port: ENV['BACKUP_PORT']) do |sftp|
    sftp.dir.foreach('/') do |entry|
      puts entry.longname
    end

    sftp.upload!("./backups/#{timestamp}__#{ENV['RACK_ENV']}-dump.sql", "/#{timestamp}__#{ENV['RACK_ENV']}-dump.sql")
    sftp.upload!("./backups/#{files_name}", "/#{files_name}")
    sftp.upload!("./backups/#{thumbnails_name}", "/#{thumbnails_name}")
  end
end
