# frozen_string_literal: true

module JpAddress
  module CodeValidator
    CHECK_DIGITS_INDEX = 5
    CHECK_BASE = 11
    VALID_CODE_LENGTH = 6
    PREFECTURE_RANGE = (1..47)

    module_function

    def valid?(code)
      return false unless code.is_a?(String) && code.length == VALID_CODE_LENGTH

      prefecture_code = code[0..1].to_i
      return false unless PREFECTURE_RANGE.cover?(prefecture_code)

      sub_total = code.chars
                      .take(CHECK_DIGITS_INDEX)
                      .map.with_index { |digit, index| digit.to_i * (CHECK_DIGITS_INDEX - index + 1) }
                      .sum

      candidate = (CHECK_BASE - (sub_total % CHECK_BASE)) % 10
      check_digit = sub_total >= CHECK_BASE ? candidate : CHECK_BASE - sub_total
      code[CHECK_DIGITS_INDEX] == check_digit.to_s
    end
  end
end
