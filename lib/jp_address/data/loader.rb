# frozen_string_literal: true

require "json"

module JpAddress
  module Data
    # 組み込みJSONデータの遅延読み込みとキャッシュ
    class Loader
      DATA_DIR = File.expand_path("../../../data", __dir__)

      class << self
        def prefectures
          @prefectures ||= load_json("prefectures.json")
        end

        def cities(prefecture_code)
          cities_cache[prefecture_code] ||= load_json("cities/#{format("%02d", prefecture_code)}.json")
        end

        def postal_codes(prefix)
          postal_cache[prefix] ||= load_json("postal_codes/#{prefix}.json")
        end

        def reset!
          instance_variables.each { |var| remove_instance_variable(var) }
        end

        private

        def cities_cache
          @cities_cache ||= {}
        end

        def postal_cache
          @postal_cache ||= {}
        end

        def load_json(relative_path)
          path = File.join(DATA_DIR, relative_path)
          return [] unless File.exist?(path)

          JSON.parse(File.read(path), symbolize_names: true)
        end
      end
    end
  end
end
