Tacpic.hash_branch "braille" do |r|
  r.is do
    # POST /braille
    r.post do
      # DON'T USE IN FUTURE. could be used for cli injection attacks
      if r.params['bulk'].nil?
        `printf '#{request['label']}' | lou_translate --forward #{request['system'].shellescape}`
      else
        response_body = {
            labels: []
        }
        request['labels'].each do |label|
          response_body[:labels].push({
                                           braille: `printf '#{label['text']}' | lou_translate --forward #{request['system'].shellescape}`,
                                           uuid: label['uuid']
                                       })
        end

        response_body
      end
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