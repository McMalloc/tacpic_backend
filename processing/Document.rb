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

  def self.create_svg(variant_id, content, width, height)
    svg_file = SVG.new viewBox: "0 0 #{width}mm #{height}mm",
                       width: width.to_s + 'mm',
                       height: height.to_s + 'mm'
    svg_file << content
    svg_file.save "files/original-#{variant_id}.svg"
    
    self.create_thumbnails(variant_id,height.to_f/width)
  end

  def self.create_pdf(variant_id)
    path = Dir.pwd + '/files/'
    system "wkhtmltopdf --disable-smart-shrinking #{path}original-#{variant_id}.svg #{path}original-#{variant_id}.pdf"
  end

  def self.get_pdf(variant_id)
    File.open("files/original-#{variant_id}.pdf", 'r')
        .read
  end

  def self.create_brf(variant_id)
    latest_version = Version.where(variant_id: variant_id).order_by(:created_at).last
    content = JSON.parse(latest_version)
                  .select{|page|page["text"]}
                  .map{|page|page["braille"]}
                  .join(" ")

    layout_settings = JSON.parse(Variant[variant_id].values[:braille_layout])

    path = Dir.pwd + '/files/'
    File.open "#{path}#{variant_id}.brf", "w"do |f|
      f.write "\eDBT9,"
      f.write "TM#{layout_settings["marginTop"]},"
      f.write "BI#{layout_settings["marginLeft"]},"
      f.write "CH#{layout_settings["cellsPerRow"]},"
      f.write "LP#{layout_settings["rowsPerPage"]},"
      f.write "PN#{layout_settings["pageNumbers"]};"
      f.write "#{content}"
    end
  end

  def self.get_brf(variant_id)
    File.open("files/#{variant_id}.brf", 'r')
        .read
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