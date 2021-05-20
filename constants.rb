# frozen_string_literal: true

module CONSTANTS
  module ROLE
    ADMIN = 1
  end

  module HTTP
    OK = 200
    CREATED = 201
    ACCEPTED = 202
    NO_CONTENT = 204
    BAD_REQUEST = 400
    UNAUTHORIZED = 401
    FORBIDDEN = 403
    NOT_ACCEPTABLE = 406
    PROXY_AUTHENTICATE_REQUIRED = 407
    CONFLICT = 409
    INTERNAL = 500
  end

  # BESTELLSTATUSNUMMERN
  # ATTENTION_NEEDED: reserviert, falls wir eine gesonderte Problembehandlung implementieren
  # RECEIVED: Im System eingegangen, noch nciht an Produktionspartner rausgeschickt
  # TRANSFERED: An Produktionspartnerin samt Frankierung per Mail geschickt
  # PRODUCED: Produktionspartnerin hat die Produktion bestätigt und abgeschickt
  # COMPLETED: Mit der Bestellung verknüpfte Rechnung ist beglichen, und der Status war vorher PRODUCED, oder anders herum
  module ORDER_STATUS
    ATTENTION_NEEDED = 0
    RECEIVED = 1
    TRANSFERED = 2
    PRODUCED = 3
    COMPLETED = 4
  end
  module EWR_ISO
    GERMANY = 'DEU'
  end
end
