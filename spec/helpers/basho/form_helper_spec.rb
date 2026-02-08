# frozen_string_literal: true

require "rails_helper"

RSpec.describe Basho::FormHelper, type: :helper do
  describe "#basho_autofill_frame_tag" do
    it "turbo-frameタグを生成する" do
      html = helper.basho_autofill_frame_tag

      expect(html).to include("turbo-frame")
      expect(html).to include('id="basho-result"')
      expect(html).to include('data-basho--auto-fill-target="frame"')
    end
  end

  describe "#basho_cascade_data" do
    it "Stimulusコントローラーのdata属性ハッシュを返す" do
      data = helper.basho_cascade_data

      expect(data[:controller]).to eq("basho--cascade-select")
      expect(data["basho--cascade-select-prefectures-url-value"]).to eq("/basho/prefectures")
      expect(data["basho--cascade-select-cities-url-template-value"]).to include("/basho/prefectures/")
      expect(data["basho--cascade-select-cities-url-template-value"]).to include(":code")
    end
  end
end
