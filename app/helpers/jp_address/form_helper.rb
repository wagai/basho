# frozen_string_literal: true

module JpAddress
  module FormHelper
    def jp_address_autofill_frame_tag
      content_tag("turbo-frame", nil, id: "jp-address-result",
                                      data: { "jp-address--auto-fill-target" => "frame" })
    end
  end
end
