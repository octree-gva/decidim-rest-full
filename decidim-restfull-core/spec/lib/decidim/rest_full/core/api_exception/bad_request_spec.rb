# frozen_string_literal: true

require "spec_helper"

module Decidim
  module RestFull
    module Core
      module ApiExceptionBadRequestSpec
        class SampleForm
          include ActiveModel::Model

          attr_accessor :title, :body

          validates :title, :body, presence: true
          validates :title, length: { minimum: 15 }, allow_blank: true
        end
      end
    end
  end
end

RSpec.describe Decidim::RestFull::Core::ApiException::BadRequest do
  let(:form_class) { Decidim::RestFull::Core::ApiExceptionBadRequestSpec::SampleForm }

  describe ".from_errors" do
    it "maps ActiveModel errors to error_details and joins descriptions" do
      record = form_class.new(title: "Hi", body: "")
      expect(record).not_to be_valid

      exception = described_class.from_errors(record.errors)

      expect(exception.message).to eq(record.errors.map(&:full_message).join(". "))
      expect(exception.error_details).to all(include(:code, :field, :description))
      expect(exception.error_details.map { |d| d[:field] }).to include("title", "body")
      expect(exception.error_details.map { |d| d[:code] }).to include("blank", "too_short")
    end

    it "infers too_much_caps when type is a translated string (DecidimAwesome)" do
      record = form_class.new(title: "ok", body: "ok")
      record.valid?
      record.errors.add(:title, "Is using too many capital letters (over 25% of the text)")

      exception = described_class.from_errors(record.errors)

      expect(exception.error_details).to include(
        a_hash_including(code: "too_much_caps", field: "title")
      )
    end
  end

  describe ".from_form" do
    it "limits details to selected attributes" do
      record = form_class.new(title: "", body: "")
      expect(record).not_to be_valid

      exception = described_class.from_form(record, only: [:title])

      expect(exception.error_details.map { |d| d[:field] }).to all(eq("title"))
      expect(exception.error_details).to include(a_hash_including(code: "blank", field: "title"))
    end
  end
end
