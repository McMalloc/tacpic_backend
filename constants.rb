# frozen_string_literal: true

module CONSTANTS
  module ROLE
    STANDARD = 0
    ADMIN = 1
    EXTERNAL = 2
  end

  module HTTP
    OK = 200
    CREATED = 201
    ACCEPTED = 202
    NO_CONTENT = 204
    BAD_REQUEST = 400
    UNAUTHORIZED = 401
    FORBIDDEN = 403
    NOT_FOUND = 404
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
  # CANCELED: Storniert
  module ORDER_STATUS
    ATTENTION_NEEDED = 0
    RECEIVED = 1
    TRANSFERED = 2
    PRODUCED = 3
    COMPLETED = 4
    CANCELED = 5
  end
  module INVOICE_STATUS
    RESERVED = 0
    UNPAID = 1
    PAID = 2
    PARTIALLY = 3
    REPLACED = 4 # Stornorechnung ausgestellt
    CANCELLED = 5 # storniert
    CREDIT_NOTE = 6 # Gutschrift / Stornorechnung
  end
  module EWR_ISO
    GERMANY = 'DEU'
  end

  ISO_DATETIME = '%Y-%m-%dT%H:%M:%S%z'.freeze
end
