# encoding: utf-8

require 'spec_helper'

describe Github::Client::Repos::Branches, '#get' do
  let(:user) { 'peter-murach' }
  let(:repo) { 'github' }
  let(:request_path) { "/repos/#{user}/#{repo}/branches/#{branch}" }
  let(:branch) { 'master' }

  after { reset_authentication_for subject }

  before {
    stub_get(request_path).to_return(:body => body, :status => status,
      :headers => {:content_type => "application/json; charset=utf-8"})
  }

  context "resource found" do
    let(:body)   { fixture('repos/branch.json') }
    let(:status) { 200 }

    it "should find resources" do
      subject.get user, repo, branch
      expect(a_get(request_path)).to have_been_made
    end

    it "should return repository mash" do
      repo_branch = subject.get user, repo, branch
      expect(repo_branch).to be_a Github::ResponseWrapper
    end

    it "should get repository branch information" do
      repo_branch = subject.get user, repo, branch
      expect(repo_branch.name).to eq 'master'
    end
  end

  it_should_behave_like 'request failure' do
    let(:requestable) { subject.get user, repo, branch }
  end
end # get
