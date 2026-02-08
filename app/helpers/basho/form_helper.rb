# frozen_string_literal: true

module Basho
  # 自動入力・カスケードセレクト用のフォームヘルパー
  module FormHelper
    def basho_autofill_frame_tag
      content_tag("turbo-frame", nil, id: "basho-result",
                                      data: { "basho--auto-fill-target" => "frame" })
    end

    def basho_cascade_data
      prefectures_url = basho.prefectures_path
      cities_template = basho.cities_prefecture_path(":code")

      {
        controller: "basho--cascade-select",
        "basho--cascade-select-prefectures-url-value" => prefectures_url,
        "basho--cascade-select-cities-url-template-value" => cities_template
      }
    end
  end
end
