# frozen_string_literal: true

JpAddress::Engine.routes.draw do
  get "postal_codes/lookup", to: "postal_codes#lookup", as: :postal_code_lookup
  resources :prefectures, only: [:index], param: :code do
    get :cities, on: :member
  end
end
