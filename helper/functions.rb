module Helper
  def self.table_print(rows)
    rows.first.keys.each { |key| print trunc(key.to_s, 8) + "\t" }
    print "\n"
    rows.each do |row|
      row.each { |v| print trunc(v[1].to_s, 8) + "\t" }
      print "\n"
    end
    rows.first.keys.each { |key| print trunc(key.to_s, 8) + "\t" }
  end

  def self.trunc(string, length)
    if string.length <= length
      return string
    end
    string.to_s[0..length-3] + "…"
  end

  def self.pack_json(request, fields)
    stripped_request = {}
    fields.each do |field|
      stripped_request[field] = request[field]
    end
    return stripped_request.to_json
  end

# TODO wohin damit?
  def self.determine_format(width, height)
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

  def self.determine_dimensions(format, is_landscape)
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
end