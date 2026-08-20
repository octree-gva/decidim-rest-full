# frozen_string_literal: true

RSpec.shared_examples "a model with HasExtendedData" do
  it "includes HasExtendedData" do
    expect(subject.class.ancestors).to include(Decidim::RestFull::Core::HasExtendedData)
  end

  it "has_one extended_data association" do
    expect(subject).to respond_to(:extended_data)
    expect(subject.class.reflect_on_association(:extended_data).macro).to eq(:has_one)
  end

  it "exposes extended_data_hash" do
    expect(subject.extended_data_hash).to eq({})
  end

  it "ensures an extended_data row after create" do
    expect(subject.extended_data).to be_present
    expect(subject.extended_data.data).to eq({})
  end

  it "stores data on the polymorphic related row" do
    subject.extended_data.update!(data: { "foo" => "bar" })
    expect(subject.reload.extended_data_hash).to eq("foo" => "bar")
    expect(subject.extended_data.resource).to eq(subject)
  end

  it "touches the parent resource on extended_data update" do
    previous = subject.reload.updated_at
    travel 1.second do
      subject.extended_data.update!(data: { "touch" => "1" })
    end
    expect(subject.reload.updated_at).to be > previous
  end

  it "quotes resource_type in the extended_data ransacker SQL" do
    sql = subject.class.ransack(extended_data_cont: "probe").result.to_sql
    expect(sql).to include(ActiveRecord::Base.connection.quote(subject.class.name))
    expect(sql).to match(/data::text/i)
  end
end
