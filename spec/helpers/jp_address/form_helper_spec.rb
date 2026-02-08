# frozen_string_literal: true

require "rails_helper"

RSpec.describe JpAddress::FormHelper, type: :helper do
  describe "#jp_address_autofill_frame_tag" do
    it "turbo-frameタグを生成する" do
      html = helper.jp_address_autofill_frame_tag

      expect(html).to include("turbo-frame")
      expect(html).to include('id="jp-address-result"')
      expect(html).to include('data-jp-address--auto-fill-target="frame"')
    end
  end

  describe "#jp_address_cascade_data" do
    it "Stimulusコントローラーのdata属性ハッシュを返す" do
      data = helper.jp_address_cascade_data

      expect(data[:controller]).to eq("jp-address--cascade-select")
      expect(data["jp-address--cascade-select-prefectures-url-value"]).to eq("/jp_address/prefectures")
      expect(data["jp-address--cascade-select-cities-url-template-value"]).to include("/jp_address/prefectures/")
      expect(data["jp-address--cascade-select-cities-url-template-value"]).to include(":code")
    end
  end
end
