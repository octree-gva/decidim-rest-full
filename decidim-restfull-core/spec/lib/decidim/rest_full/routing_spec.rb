# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Routing do
  describe ".read_resources" do
    it "declares resources with an absolute controller path" do
      router = double("router")
      allow(router).to receive(:resources)

      described_class.read_resources(router, :widgets, controller: "widgets/widgets", only: [:index, :show])

      expect(router).to have_received(:resources).with(
        :widgets,
        only: [:index, :show],
        controller: "/decidim/api/rest_full/widgets/widgets"
      )
    end
  end

  describe ".async_resources" do
    it "declares sync aliases for mutating actions" do
      router = double("router")
      allow(router).to receive(:resources).and_yield
      allow(router).to receive(:collection).and_yield
      allow(router).to receive(:member).and_yield
      allow(router).to receive(:post)
      allow(router).to receive(:put)
      allow(router).to receive(:delete)

      described_class.async_resources(
        router,
        :blogs,
        controller: "blogs/blogs",
        only: [:create, :update, :destroy]
      )

      expect(router).to have_received(:post).with("sync", action: :create_sync)
      expect(router).to have_received(:put).with("sync", action: :update_sync)
      expect(router).to have_received(:delete).with("sync", action: :destroy_sync)
    end

    it "declares optional member routes" do
      router = double("router")
      allow(router).to receive(:resources).and_yield
      allow(router).to receive(:collection)
      allow(router).to receive(:member).and_yield
      allow(router).to receive(:post)

      described_class.async_resources(
        router,
        :draft_proposals,
        controller: "draft_proposals/draft_proposals",
        only: [:create],
        member: { post: { publish: :publish, "publish/sync": :publish_sync } }
      )

      expect(router).to have_received(:post).with(:publish, action: :publish)
      expect(router).to have_received(:post).with(:"publish/sync", action: :publish_sync)
    end
  end
end
