# frozen_string_literal: true

Rails.application.routes.draw do
  mount Basho::Engine, at: "/basho"
end
