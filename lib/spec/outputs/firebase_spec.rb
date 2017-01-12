# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/firebase"

describe LogStash::Outputs::Firebase do

  it_behaves_like "an interruptible output plugin" do
    let(:config) { { "interval" => 100 } }
  end

end
