# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Basho::PostalCodes", type: :request do
  describe "GET /basho/postal_codes/lookup" do
    context "有効な郵便番号の場合" do
      it "data属性付きのturbo-frameを返す" do
        get "/basho/postal_codes/lookup", params: { code: "1540011" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('turbo-frame id="basho-result"')
        expect(response.body).to include("data-address")
        expect(response.body).to include('data-prefecture="東京都"')
        expect(response.body).to include('data-city="世田谷区"')
        expect(response.body).to include('data-town="上馬"')
      end

      it "ハイフン付き郵便番号でも動作する" do
        get "/basho/postal_codes/lookup", params: { code: "154-0011" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("data-address")
        expect(response.body).to include('data-prefecture="東京都"')
      end
    end

    context "無効な郵便番号の場合" do
      it "空のturbo-frameを返す" do
        get "/basho/postal_codes/lookup", params: { code: "invalid" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('turbo-frame id="basho-result"')
        expect(response.body).not_to include("data-address")
      end
    end

    context "存在しない郵便番号の場合" do
      it "空のturbo-frameを返す" do
        get "/basho/postal_codes/lookup", params: { code: "0000000" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('turbo-frame id="basho-result"')
        expect(response.body).not_to include("data-address")
      end
    end

    context "桁数が足りない場合" do
      it "空のturbo-frameを返す" do
        get "/basho/postal_codes/lookup", params: { code: "154" }

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("data-address")
      end
    end

    context "codeパラメータがない場合" do
      it "空のturbo-frameを返す" do
        get "/basho/postal_codes/lookup"

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("data-address")
      end
    end
  end
end
