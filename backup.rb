require 'net/sftp'

def backup
  Net::SFTP.start('ngcobalt327.manitu.net', 'ftp200008186', password: 'HPpHZ5vXh4xUC272fWJy', port: 23) do |sftp|
    Dir.mkdir 'backups' unless Dir.exist? 'backups'
    `pg_dump #{ENV['TACPIC_DATABASE_URL']} -f ./backups/#{ENV['RACK_ENV']}-dump.sql`

    sftp.dir.foreach('/') do |entry|
      puts entry.longname
    end

    sftp.upload!("./backups/#{ENV['RACK_ENV']}-dump.sql", "/#{ENV['RACK_ENV']}-dump.sql")
  end
end
