# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Basho::Prefectures", type: :request do
  describe "GET /basho/prefectures" do
    it "47都道府県のJSONを返す" do
      get "/basho/prefectures"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.size).to eq(47)
      expect(json.first).to eq("code" => 1, "name" => "北海道")
      expect(json.last).to eq("code" => 47, "name" => "沖縄県")
    end

    it "Cache-Controlヘッダーを返す" do
      get "/basho/prefectures"

      expect(response.headers["Cache-Control"]).to include("max-age=86400")
      expect(response.headers["Cache-Control"]).to include("public")
    end

    it "code, nameのみ含む" do
      get "/basho/prefectures"

      json = JSON.parse(response.body)
      expect(json.first.keys).to contain_exactly("code", "name")
    end
  end

  describe "GET /basho/prefectures/:code/cities" do
    context "有効な都道府県コードの場合" do
      it "市区町村一覧のJSONを返す" do
        get "/basho/prefectures/13/cities"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
        expect(json.size).to be > 0

        first_city = json.first
        expect(first_city.keys).to contain_exactly("code", "name")
        expect(first_city["code"]).to start_with("13")
      end

      it "Cache-Controlヘッダーを返す" do
        get "/basho/prefectures/13/cities"

        expect(response.headers["Cache-Control"]).to include("max-age=86400")
        expect(response.headers["Cache-Control"]).to include("public")
      end

      it "北海道の市区町村を返す" do
        get "/basho/prefectures/1/cities"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json.size).to be > 0
        names = json.map { |c| c["name"] }
        expect(names).to include("札幌市")
      end
    end

    context "無効な都道府県コードの場合" do
      it "404と空配列を返す" do
        get "/basho/prefectures/99/cities"

        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end

    context "都道府県コードが0の場合" do
      it "404と空配列を返す" do
        get "/basho/prefectures/0/cities"

        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end

    context "数値以外のコードの場合" do
      it "404と空配列を返す" do
        get "/basho/prefectures/abc/cities"

        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end
  end
end
