# frozen_string_literal: true

module JpAddress
  # 自動入力・カスケードセレクト用のフォームヘルパー
  module FormHelper
    def jp_address_autofill_frame_tag
      content_tag("turbo-frame", nil, id: "jp-address-result",
                                      data: { "jp-address--auto-fill-target" => "frame" })
    end

    def jp_address_cascade_data
      prefectures_url = jp_address.prefectures_path
      cities_template = jp_address.cities_prefecture_path(":code")

      {
        controller: "jp-address--cascade-select",
        "jp-address--cascade-select-prefectures-url-value" => prefectures_url,
        "jp-address--cascade-select-cities-url-template-value" => cities_template
      }
    end
  end
end
