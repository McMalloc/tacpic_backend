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

  def self.format_currency(value)
    #todo i18n
    main, decimals = (value/100.0).round(2).to_s.split('.')
    "#{main},#{decimals}#{decimals.length == 1 ? '0' : ''}€"
  end

  # https://stackoverflow.com/questions/49004335/ruby-find-date-with-your-day-except-weekend
  def self.add_working_days(date, num)
    mod_date = date.to_date
    num.times.inject(mod_date) do |mod_date|
      case mod_date.wday
      when 5 then mod_date += 3
      when 6 then mod_date += 2
      else mod_date += 1
      end
    end
  end

# TODO wohin damit?
  def self.determine_format(width, height)
    if width.to_i == 210 and height.to_i == 297
      return ["a4", false]
    end
    if width.to_i == 297 and height.to_i == 210
      return ["a4", true]
    end
    if width.to_i == 297 and height.to_i == 420
      return ["a3", false]
    end
    if width.to_i == 420 and height.to_i == 297
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
        return [420, 297]
      else
        return [297, 420]
      end
    end
  end
end