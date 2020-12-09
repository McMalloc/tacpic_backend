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
  @@svg_renderer = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/processor/svg_template.svg.erb")
  @@brf_renderer = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/processor/brf_template.brf.erb")
  @@font_data = Base64.strict_encode64 File.read("#{ENV['APPLICATION_BASE']}/services/processor/tacpic_swellbraille_euro6.woff")
  @@root = "#{ENV['APPLICATION_BASE']}/files"

  def initialize(version)
    @version = version.values
    @variant = version.variant.values
    @contributors = version.variant.contributors
    @graphic = version.variant.graphic
    document = JSON.parse @version[:document]
    @pages = document['pages']

    @braille_pages = document['braillePages']
    @graphic_width, @graphic_height = determine_dimensions(@variant[:graphic_format], @variant[:graphic_landscape])
    @file_name = "v#{@version[:id]}-#{@graphic.title.gsub(/[^0-9A-Za-z.\-]/, '_')}-#{@variant[:title].gsub(/[^0-9A-Za-z.\-]/, '_') or "basis"}"
  end

  def save_svg(index)
    File.open "#{@@root}/#{@file_name}-VECTOR-p#{index}.svg", 'w' do |f|
      binding = {
          content: @pages[index]['rendering'],
          font_data: @@font_data,
          version_id: @version[:id],
          width: @graphic_width,
          height: @graphic_height,
          title: @variant[:title] + ": " + @graphic[:title],
          contributors: @contributors.map{|c| c[:display_name]}.join(", "),
          description: @variant[:description],
          date: @version[:created_at]
      }
      f.write @@svg_renderer.result_with_hash(binding)
    end
  end

  def save_brf(formattedContent)
    # TODO Validierer, damit keine fehlerhaften BRFs ausgegeben werden, die die Produktion stören

    File.open "#{@@root}/#{@file_name}-BRAILLE.brf", 'w' do |f|
      page_index = 0
      binding = {
          cellsPerRow: @braille_pages['cellsPerRow'],
          height: @braille_pages['height'],
          marginLeft: @braille_pages['marginLeft'],
          marginTop: @braille_pages['marginTop'],
          pageNumbers: @braille_pages['pageNumbers'],
          rowsPerPage: @braille_pages['rowsPerPage'],
          width: @braille_pages['width'],
          braille_content: formattedContent.reduce("") { |memo, pagebreak|
            page_index += 1
            if page_index === formattedContent.count
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
    begin
      self.save_brf @braille_pages['formatted']
      @pages.nil? && return
      @pages.count.times do |index|
        self.save_svg index
        self.save_pdf index
        self.save_thumbnails index
      end
      # TODO wenn einer Variante Seiten entfernt werden, werden die Dateien trotzdem noch gemergt. => map
      merge_input = "#{@@root}/#{@file_name}-PRINT-p*.pdf"
      merge_output = "#{@@root}/#{@file_name}-PRINT-merged.pdf"
      # print system "gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=#{merge_output} #{merge_input}"
      print system "gs -sProcessColorModel=DeviceCMYK -sColorConversionStrategy=CMYK -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=#{merge_output} #{merge_input}"
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
    system "node #{ENV['APPLICATION_BASE']}/services/processor/convert_svg #{@file_name} #{@variant[:graphic_format]} #{@variant[:graphic_landscape]} #{index} #{@@root}"
  end
end