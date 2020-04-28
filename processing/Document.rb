require 'victor'
# require 'uuid'
include Victor

# uuid = UUID.new

# TODO mehrere Seiten?
module Document
  def self.open_svg(variant_id)
    File.open "files/original-#{variant_id}.svg", 'w'
        .read
  end

  def self.save_svg(variant_id, content, width, height)
    svg_file = SVG.new viewBox: "0 0 #{width}mm #{height}mm",
                       width: width.to_s + 'mm',
                       height: height.to_s + 'mm'
    svg_file << content
    svg_file.save "files/original-#{variant_id}.svg"
    
    self.create_thumbnails(variant_id,height.to_f/width)
  end

  # def self.convert_pdf(variant_id)
  #   path = Dir.pwd + '/files/'
  #   system "wkhtmltopdf --disable-smart-shrinking #{path}test.svg #{path}test.pdf"
  # end

  def self.get_pdf(variant_id)
    system "wkhtmltopdf --disable-smart-shrinking files/original-#{variant_id}.svg files/original-#{variant_id}.pdf"
    # system "rsvg-convert -f pdf -o files/original-#{variant_id}.pdf files/original-#{variant_id}.svg"

    File.open("files/original-#{variant_id}.pdf", 'r').read
  end

  def self.create_thumbnails(variant_id, ratio)
    # TODO ratio nicht mehr nötig?
    if ratio > 1
      width_sm = 200
      height_sm = (width_sm*ratio).to_i
      width_xl = 400
      height_xl = (width_xl*ratio).to_i
    else
      height_sm = 200
      width_sm = (height_sm*ratio).to_i
      height_xl = 400
      width_xl = (height_xl*ratio).to_i
    end

    path = Dir.pwd + '/public/thumbnails/'

    `node ./node_modules/svgexport/bin/index.js files/original-#{variant_id}.svg #{path}thumbnail-#{variant_id}-sm.png pad #{width_sm}#{height_sm}`
    `node ./node_modules/svgexport/bin/index.js files/original-#{variant_id}.svg #{path}thumbnail-#{variant_id}-xl.png pad #{width_xl}#{height_xl}`

    # system "inkscape -z -e #{path}thumbnail-#{variant_id}-sm.png -w #{width_sm} -h #{height_sm} ./files/original-#{variant_id}.svg"
    # system "inkscape -z -e #{path}thumbnail-#{variant_id}-xl.png -w #{width_xl} -h #{height_xl} ./files/original-#{variant_id}.svg"
  end
end