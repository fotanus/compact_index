require 'tempfile'
require 'spec_helper'
require 'compact_index/versions_file'
require 'support/versions_file'

describe CompactIndex::VersionsFile do
  before :all do
    @file_contents = "gem1 1.1,1.2\ngem2 2.1,2.1-jruby\n"
    @file = Tempfile.new('versions.list')
    @file.write @file_contents
    @file.rewind
  end

  after :all do
    @file.unlink
  end

  let(:versions_file) do
    CompactIndex::VersionsFile.new(@file.path)
  end

  context "using the file" do
    let(:file) { Tempfile.new("create_versions.list") }
    let(:gems) do
      [
        {name: "gem5", versions: %W(1.0.1) },
        {name: "gem2", versions: %W(1.0.1 1.0.2-arch)},
      ]
    end
    let(:versions_file) { versions_file = CompactIndex::VersionsFile.new(file.path) }

    before(:each) do
      versions_file.create(gems)
    end

    describe "#create"  do
      it "write the gems" do
        expected_file_output = /created_at: .*?\n---\ngem5 1.0.1\ngem2 1.0.1,1.0.2-arch\n/
        expect(file.open.read).to match(expected_file_output)
      end

      it "add the date on top" do
        date_regexp = /^created_at: (.*?)\n/
        expect(
          file.open.read.match(date_regexp)[0]
        ).to match (
          /(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})\:(\d{2})[+-](\d{2})\:(\d{2})/
        )
      end
      pending "order by creation time"
      pending "order version numbers"
    end

    describe "#update" do
      it "add a gem" do
        gems = [{name: 'new-gem', versions: %w(1.0)}]
        expected_output = "---\ngem5 1.0.1\ngem2 1.0.1,1.0.2-arch\nnew-gem 1.0\n"
        versions_file.update(gems)
        expect(file.open.read).to match(expected_output)
      end

      it "add again even if already listed" do
        gems = [{name: 'gem5', versions: %w(3.0)}]
        expected_output = "---\ngem5 1.0.1\ngem2 1.0.1,1.0.2-arch\ngem5 3.0\n"
        versions_file.update(gems)
        expect(file.open.read).to match(expected_output)
      end
      pending "order by creation time"
      pending "order version numbers"
    end
  end

  describe "#updated_at" do
    it "is a date time" do
      expect(versions_file.updated_at).to be_kind_of(DateTime)
    end
    it "uses File#mtime" do
      expect(File).to receive('mtime') { DateTime.now }
      versions_file.updated_at
    end
  end

  describe "#contents" do
    it "return the file" do
      expect(versions_file.contents).to eq(@file_contents)
    end

    it "receive extra gems" do
      extra_gems = [{name: "gem3", versions: %W(1.0.1 1.0.2-arch)}]
      expect(
        versions_file.contents(extra_gems)
      ).to eq(
        @file_contents + "gem3 1.0.1,1.0.2-arch\n"
      )
    end

    pending "order by creation time"
    pending "order version numbers"
  end
end
