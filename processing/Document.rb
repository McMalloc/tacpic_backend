require 'victor'
include Victor
require 'erb'


# TODO mehrere Seiten?
module Document
  svg_template = File.read './processing/svg_template.svg.erb'
  @svg_renderer = ERB.new svg_template
  brf_template = File.read './processing/brf_template.brf.erb'
  @brf_renderer = ERB.new brf_template

  def self.save_svg(file_name, content, width, height)
    File.open "files/#{file_name}-VECTOR.svg", 'w' do |f|
      f.write @svg_renderer.result_with_hash({content: content, width: width, height: height})
    end
  end

  def self.save_brf(file_name, braille_content, braille_layout)
    # TODO Validierer, damit keine fehlerhaften BRFs ausgegeben werden, die die Produktion stören
    braille_content.nil? && return
    File.open "files/#{file_name}-BRAILLE.brf", 'w' do |f|
      index = 0
      f.write @brf_renderer.result_with_hash({
                                                 cellsPerRow: braille_layout['cellsPerRow'],
                                                 height: braille_layout['height'],
                                                 marginLeft: braille_layout['marginLeft'],
                                                 marginTop: braille_layout['marginTop'],
                                                 pageNumbers: braille_layout['pageNumbers'],
                                                 rowsPerPage: braille_layout['rowsPerPage'],
                                                 width: braille_layout['width'],
                                                 braille_content: braille_content.reduce("") { |memo, pagebreak|
                                                   index += 1
                                                   if index === braille_content.count
                                                     suffix = "" else suffix = "\x0c" end
                                                   memo + pagebreak.reduce("") { |pagememo, line|
                                                     pagememo + line + "\x0a"
                                                   } + suffix
                                                 },
                                             })
    end
  end

  def self.save_files(graphic_id, variant_id, pages, width, height, braille_layout)
    file_name = "#{graphic_id}-#{variant_id.to_s}-"
    pages.each_with_index do |page, index|
      if page['text'] != true
        indexed_filename = file_name + index.to_s
        self.save_svg(indexed_filename, page['rendering'], width, height)
        self.save_pdf(indexed_filename, width, height)
        self.save_thumbnails(indexed_filename)
      else
        self.save_brf(file_name + index.to_s, page['formatted'], braille_layout)
      end
    end
    # TODO wenn einer Variante Seiten entfernt werden, werden die Dateien trotzdem noch gemergt. => map
    print system "gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=#{ENV['APPLICATION_BASE']}/tacpic_backend/files/#{graphic_id}-#{variant_id}-merged-PRINT.pdf #{ENV['APPLICATION_BASE']}/tacpic_backend/files/#{graphic_id}-#{variant_id}-*-PRINT.pdf"
  end

  def self.save_thumbnails(file_name)
    source = "#{ENV['APPLICATION_BASE']}/tacpic_backend/files/#{file_name}-RASTER.png"
    dest_prefix = "#{ENV['APPLICATION_BASE']}/tacpic_backend/public/thumbnails/#{file_name}"
    system "cat #{source} | pngtopnm | pnmscale 0.2 | pnmtopng > #{dest_prefix}-sm.png"
    system "cat #{source} | pngtopnm | pnmscale 0.6 | pnmtopng > #{dest_prefix}-xl.png"
  end

  def self.save_pdf(title, width, height)
    system "node processing/convert_svg #{title} #{width} #{height} #{ENV['APPLICATION_BASE']}/tacpic_backend"
  end

  def self.get_pdf(graphic_id, variant_id)
    File.open("#{ENV['APPLICATION_BASE']}/tacpic_backend/files/#{graphic_id}-#{variant_id}-merged-PRINT.pdf", 'r').read
  end
end