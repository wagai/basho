# frozen_string_literal: true

module JpAddress
  module CodeValidator
    CHECK_DIGITS_INDEX = 5
    CHECK_BASE = 11
    PREFECTURE_RANGE = (1..47)

    module_function

    def valid?(code)
      return false unless code.is_a?(String) && code.match?(/\A\d{6}\z/)
      return false unless PREFECTURE_RANGE.cover?(code[0..1].to_i)

      code[CHECK_DIGITS_INDEX].to_i == compute_check_digit(code)
    end

    def compute_check_digit(code)
      sub_total = code.chars
                      .take(CHECK_DIGITS_INDEX)
                      .map.with_index { |digit, i| digit.to_i * (CHECK_DIGITS_INDEX - i + 1) }
                      .sum

      candidate = (CHECK_BASE - (sub_total % CHECK_BASE)) % 10
      sub_total >= CHECK_BASE ? candidate : CHECK_BASE - sub_total
    end
  end
end
