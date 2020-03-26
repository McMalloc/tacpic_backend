base = "/home/robert/Desktop/git-test"

class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end

  def bg_black;       "\e[40m#{self}\e[0m" end
  def bg_red;         "\e[41m#{self}\e[0m" end
  def bg_green;       "\e[42m#{self}\e[0m" end
  def bg_brown;       "\e[43m#{self}\e[0m" end
  def bg_blue;        "\e[44m#{self}\e[0m" end
  def bg_magenta;     "\e[45m#{self}\e[0m" end
  def bg_cyan;        "\e[46m#{self}\e[0m" end
  def bg_gray;        "\e[47m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
  def blink;          "\e[5m#{self}\e[25m" end
  def reverse_color;  "\e[7m#{self}\e[27m" end
end

pp ENV

puts "Staging backend:".black.bg_cyan
Dir.chdir("#{base}/tacpic") do
  system "git pull"
  system "npm install" # if package.json was modified
  system "npm run build"
end

puts "Staging frontend:".black.bg_cyan
Dir.chdir("#{base}/tacpic_backend") do
  system "git pull"
  system "bundle install" # if Gemfile was specified
  system "npm install" # if Gemfile was specified
  # change rvm version if something? specifies it
end

unless Dir.exists?("#{base}/tacpic_backend/public")
  system "mkdir #{base}/tacpic_backend/public"
end

puts "Copying #{base}/tacpic/build/* to #{base}/tacpic_backend/public ... "
if system "cp -r #{base}/tacpic/build/* #{base}/tacpic_backend/public"
  print "Success!".black.green_bg
end

puts "Starting application server".black.green_bg
Dir.chdir("#{base}/tacpic_backend") do
  system "rake run:main RACK_ENV=production"
end