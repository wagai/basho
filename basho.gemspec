# frozen_string_literal: true

require_relative "lib/basho/version"

Gem::Specification.new do |spec|
  spec.name = "basho"
  spec.version = Basho::VERSION
  spec.authors = ["Hirotaka Wagai"]
  spec.email = ["hirotaka.wagai@gmail.com"]

  spec.summary = "日本の住所データ（都道府県・市区町村・郵便番号・地方区分）を統一的に扱うgem"
  spec.description = "都道府県・市区町村・郵便番号・地方区分をJSON同梱で提供。ActiveRecord統合あり。"
  spec.homepage = "https://github.com/wagai/basho"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/wagai/basho"
  spec.metadata["changelog_uri"] = "https://github.com/wagai/basho/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml tasks/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
