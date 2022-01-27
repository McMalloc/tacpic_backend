class MultiIO
  def initialize(file_path)
    @file_path = file_path
  end

  def write(*args)
    STDOUT.write(*args)
    File.write(@file_path, *args, mode: 'a')
  end

  def close; end
end

def init_logging
  log_file_path = "logs/log_#{Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')}.log"
  $_logger = Logger.new MultiIO.new log_file_path

  #   $_logger = Logger.new "logs/log_#{Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')}.log"
  plugin :common_logger, $_logger
end
