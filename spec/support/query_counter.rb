# frozen_string_literal: true

module QueryCounter
  def count_queries(&)
    count = 0
    counter = ->(*) { count += 1 }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end
end
