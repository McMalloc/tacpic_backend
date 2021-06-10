# thrown when requesting parameters compromise the sanity of the response
class DataError < StandardError
  attr_reader :parameter

  def initialize(msg = 'The request cannot reasonably be processed.', parameter)
    @parameter = parameter
    super
  end
end

# docs
class ServiceError < StandardError
  attr_reader :original_exception

  def initialize(service_exception)
    @original_exception = service_exception
    super
  end

  def message
    'An Error occured in a service'
  end
end

class EmptyOrderException < StandardError; end
class UnknownAddressError < StandardError; end

Tacpic.error do |e|
  logs = $_db[:backend_errors]
  request.body.rewind

  binding.pry
  logs.insert(
    method: request.request_method,
    path: request.path,
    params: request.request_method == 'GET' ? request.query_string : request.body.read,
    frontend_version: request.headers['TACPIC_VERSION'],
    backend_version: $_version,
    type: e.class.name,
    backtrace: e.backtrace.backtrace.select{|codepoint| codepoint.include?(ENV['APPLICATION_BASE'])}.first, # only select the upmost codepoint in the app code
    message: e.message,
    created_at: Time.now
  )

  response.status = 500
  {
    type: e.class.name,
    message: e.message,
    backtrace: e.backtrace
  }
end
