require 'net/sftp'
require 'zip'
require 'date'

def backup
  timestamp = DateTime.now.strftime('%Y-%m-%d_%H-%M-%S')
  Dir.mkdir 'backups' unless Dir.exist? 'backups'
  `pg_dump #{ENV['TACPIC_DATABASE_URL']} -f ./backups/#{timestamp}__#{ENV['RACK_ENV']}-dump.sql`

  Zip::File.open("./backups/#{timestamp}__files.zip", Zip::File::CREATE) do |zipfile|
    Dir['./files/*'].each do |file|
      unless File.directory? file
        zipfile.add "#{File.basename(file)}.#{File.extname(file)}", file
      end
    end
  end

  Zip::File.open("./backups/#{timestamp}__thumbnails.zip", Zip::File::CREATE) do |zipfile|
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
  end
end
