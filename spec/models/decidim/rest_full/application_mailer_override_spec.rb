# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::ApplicationMailerOverride do
  class TestMailer < Decidim::ApplicationMailer
    def test_email(headers = {})
      mail(headers) do |format|
        format.text { "title" }
        format.html { "<h1>TITLE</h1>" }
      end
    end
  end

  let(:mailer) { TestMailer }

  describe "#mail" do
    context "when the recipient email does end with @example.org" do
      it "sends the email" do
        expect do
          mailer.test_email(
            to: "user@example.org",
            subject: "Test Subject"
          ).deliver_now
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end

      it "publishes an ActiveSupport notification" do
        expect(ActiveSupport::Notifications).to receive(:publish).with(
          "decidim.rest.test_mailer_performed",
          to: "user@example.org",
          subject: "Test Subject",
          body_text: "title"
        )
        mailer.test_email(to: "user@example.org", subject: "Test Subject").deliver_now
      end
    end

    context "when the recipient email does not end with @example.org" do
      it "sends the email" do
        expect do
          mailer.test_email(
            to: "user@realdomain.com",
            subject: "Test Subject"
          ).deliver_now
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "publishes an ActiveSupport notification" do
        expect(ActiveSupport::Notifications).to receive(:publish).with(
          "decidim.rest.test_mailer_performed",
          to: "user@realdomain.com",
          subject: "Test Subject",
          body_text: "title"
        )
        mailer.test_email(to: "user@realdomain.com", subject: "Test Subject").deliver_now
      end
    end
  end
end
