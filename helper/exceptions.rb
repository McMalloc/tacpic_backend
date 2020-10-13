class AccountError < StandardError
  attr_reader :message
  attr_reader :status

  def initialize(message = "Nicht authorisiert", status = 403)
    @message = message
    @status = status
  end
end