require 'erb'
require_relative '../../terminal_colors'
require "base64"

def determine_dimensions(format, is_landscape)
  if format == "a4"
    if is_landscape
      return [297, 210]
    else
      return [210, 297]
    end
  end
  if format == "a3"
    if is_landscape
      return [297, 420]
    else
      return [420, 297]
    end
  end
end

def determine_format(width, height)
  if width == 210 and height == 297
    return ["a4", false]
  end
  if width == 210 and height == 297
    return ["a4", true]
  end
  if width == 297 and height == 420
    return ["a3", false]
  end
  if width == 420 and height == 297
    return ["a3", true]
  end
end

# TODO Dateinamenschema templaten
class DocumentProcessor
  @@svg_renderer = ERB.new File.read("#{ENV['APPLICATION_BASE']}/tacpic_backend/services/processor/svg_template.svg.erb")
  @@brf_renderer = ERB.new File.read("#{ENV['APPLICATION_BASE']}/tacpic_backend/services/processor/brf_template.brf.erb")
  @@font_data = Base64.strict_encode64 File.read("#{ENV['APPLICATION_BASE']}/tacpic_backend/services/processor/tacpic_swellbraille_euro6.woff")
  @@root = "#{ENV['APPLICATION_BASE']}/tacpic_backend/files"

  def initialize(version)
    @version = version.values
    @variant = version.variant.values
    graphic = version.variant.graphic
    document = JSON.parse @version[:document]
    @pages = document['pages']

    @braille_layout = document['braillePages']
    @graphic_width, @graphic_height = determine_dimensions(@variant[:graphic_format], @variant[:graphic_landscape])
    @file_name = "v#{@version[:id]}-#{graphic.title.gsub(/[^0-9A-Za-z.\-]/, '_')}-#{@variant[:title].gsub(/[^0-9A-Za-z.\-]/, '_') or "basis"}"
  end

  def save_svg(index)
    File.open "#{@@root}/#{@file_name}-VECTOR-p#{index}.svg", 'w' do |f|
      binding = {
          content: @pages[index]['rendering'],
          font_data: @@font_data,
          width: @graphic_width,
          height: @graphic_height
      }
      f.write @@svg_renderer.result_with_hash(binding)
    end
  end

  def save_brf(index)
    # TODO Validierer, damit keine fehlerhaften BRFs ausgegeben werden, die die Produktion stören

    File.open "#{@@root}/#{@file_name}-BRAILLE.brf", 'w' do |f|
      content = @pages[index]['formatted']
      content.nil? && return
      page_index = 0
      binding = {
          cellsPerRow: @braille_layout['cellsPerRow'],
          height: @braille_layout['height'],
          marginLeft: @braille_layout['marginLeft'],
          marginTop: @braille_layout['marginTop'],
          pageNumbers: @braille_layout['pageNumbers'],
          rowsPerPage: @braille_layout['rowsPerPage'],
          width: @braille_layout['width'],
          braille_content: content.reduce("") { |memo, pagebreak|
            page_index += 1
            if page_index === content.count
              suffix = ""
            else
              suffix = "\x0c" # page feed
            end
            memo + pagebreak.reduce("") { |pagememo, line|
              pagememo + line + "\x0a"
            } + suffix
          },
      }
      f.write @@brf_renderer.result_with_hash(binding)
    end
  end

  def save_files
    ENV['RACK_ENV'] == 'test' and return @file_name
    @pages.nil? && return
    begin
      @pages.count.times do |index|
        if @pages[index]['text'] != true
          self.save_svg index
          self.save_pdf index
          self.save_thumbnails index
        else
          self.save_brf index
        end
      end
      # TODO wenn einer Variante Seiten entfernt werden, werden die Dateien trotzdem noch gemergt. => map
      merge_input = "#{@@root}/#{@file_name}-PRINT-p*.pdf"
      merge_output = "#{@@root}/#{@file_name}-PRINT-merged.pdf"
      print system "gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=#{merge_output} #{merge_input}"
    rescue StandardError => e
      puts e.message
      puts e.backtrace.inspect
      return nil
    end
    return @file_name
  end

  def save_thumbnails(index)
    source = "#{@@root}/#{@file_name}-RASTER-p#{index}.png"
    dest_prefix = "#{@@root}/../public/thumbnails/#{@file_name}"
    system "cat #{source} | pngtopnm | pnmscale 0.2 | pnmtopng > #{dest_prefix}-THUMBNAIL-sm-p#{index}.png"
    system "cat #{source} | pngtopnm | pnmscale 0.6 | pnmtopng > #{dest_prefix}-THUMBNAIL-xl-p#{index}.png"
  end

  def save_pdf(index)
    system "node #{ENV['APPLICATION_BASE']}/tacpic_backend/services/processor/convert_svg #{@file_name} #{@variant[:graphic_format]} #{@variant[:graphic_landscape]} #{index} #{@@root}"
  end
end