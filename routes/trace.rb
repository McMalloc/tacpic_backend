require 'uuid'
uuid_gen = UUID.new

Tacpic.hash_branch "trace" do |r|
  r.is do
    # POST /trace
    r.post do
      response['Content-Type'] = 'image/svg+xml'
      tempfile_input = "#{ENV['APPLICATION_BASE']}/files/temp/#{uuid_gen.generate}_#{request['image'][:filename]}"
      puts request['image'][:type]

      f = File.new(tempfile_input, "wb")
      f.write(request['image'][:tempfile].read)     #=> 10
      f.close

      system "cat #{tempfile_input} | pngtopnm | potrace --output #{tempfile_input}.svg --svg"
      File.read(tempfile_input + '.svg')
    end
  end
end

# TABLES
# de-ch-accents.cti
# de-chardefs6.cti
# de-chardefs8.cti
# de-chess.ctb
# de-ch-g0.utb
# de-ch-g1.ctb
# de-ch-g2.ctb
# de-de-accents.cti
# de-de-comp8.ctb
# de-de.dis
# de-de-g0.utb
# de-de-g1.ctb
# de-de-g2.ctb
# de-eurobrl6.dis
# de-eurobrl6u.dis
# de-g0-core.uti
# de-g1-core.cti
# de-g2-core.cti