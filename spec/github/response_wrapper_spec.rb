# encoding: utf-8

require 'spec_helper'

describe Github::ResponseWrapper do
  let(:github) { Github.new }
  let(:user)   { 'wycats' }
  let(:res)    { github.activity.events.public({ 'per_page' => 20 }) }
  let(:pages)  { ['1', '5', '6'] }
  let(:link) {
    "<https://api.github.com/users/wycats/repos?page=6&per_page=20>; rel=\"last\", <https://api.github.com/users/wycats/repos?page=1&per_page=20>; rel=\"first\""
  }

  before do
    stub_get("/events").
      with(:query => { 'per_page' => '20' }).
      to_return(:body => fixture('events/events.json'),
        :status => 200,
        :headers => {
          :content_type => "application/json; charset=utf-8",
          'X-RateLimit-Remaining' => '4999',
          'X-RateLimit-Limit' => '5000',
          'content-length' => '344',
          'etag' => "\"d9a88f20567726e29d35c6fae87cef2f\"",
          'server' => "nginx/1.0.4",
          'Date' => "Sun, 05 Feb 2012 15:02:34 GMT",
          'Link' => link
        })

    ['', '1', '5', '6'].each do |page|
    params = page.empty? ? {'per_page'=>'20'} : {'per_page'=>'20', 'page'=>page}
    stub_get("/users/#{user}/repos").
      with(:query => params).
      to_return(:body => fixture('events/events.json'),
        :status => 200,
        :headers => {
          :content_type => "application/json; charset=utf-8",
          'X-RateLimit-Remaining' => '4999',
          'X-RateLimit-Limit' => '5000',
          'content-length' => '344',
          'Date' => "Sun, 05 Feb 2012 15:02:34 GMT",
          'Link' => link
        })
    end
  end

  it "should assess successful" do
    expect(res.success?).to be true
  end

  it "should read response body" do
    expect(res.body).to_not be_empty
  end

  context "pagination methods" do
    let(:links)       { Github::PageLinks.new({}) }
    let(:current_api) { double(:api).as_null_object }
    let(:iterator)    { Github::PageIterator.new(links, current_api) }

    before do
      allow(described_class).to receive(:page_iterator).and_return iterator
    end

    it "should respond to links" do
      expect(res.links).to be_a Github::PageLinks
    end

    %w[ next prev ].each do |link|
      context "#{link}_page" do
        it "responds to #{link}_page request" do
          expect(res.send(:"#{link}_page")).to be_nil
        end

        it 'should have no link information' do
          expect(res.links.send(:"#{link}")).to be_nil
        end
      end
    end

    %w[ first last].each do |link|
      context "#{link}_page" do
        it "should return resource if exists" do
          expect(res.send(:"#{link}_page")).to_not be_empty
        end

        it "should have link information" do
          expect(res.send(:"#{link}_page")).to_not be_nil
        end
      end
    end

    it 'finds single page successfully' do
      allow(iterator).to receive(:get_page).and_return res
      expect(res.page(5)).to eq res
    end

    it 'checks if there are more pages' do
      expect(res).to receive(:has_next_page?).and_return true
      expect(res.has_next_page?).to be true
    end

  end # pagination

end # Github::ResponseWrapper
