require "spec_helper"
require 'fakefactory'

describe LyraClient do

  it "has a version number" do
    expect(LyraClient::VERSION).not_to be nil
  end

  describe "Base" do

    describe "class methods" do

      class LyraClientTestAttributesClass < LyraClient::Base
        self.site = "http://test.com"
        self.headers = {test: 'test'}
        self.collection_name = 'automations'
      end

      it "should exist thread safe attributes" do
        expect(LyraClientTestAttributesClass.site).to be == "http://test.com"
        expect(LyraClientTestAttributesClass.headers).to be == {test: 'test'}
      end

      describe "collection path with prefix" do

        class LyraClientTestClass < LyraClient::Base
          self.collection_name = 'automations'
        end

        it "should build the collection path with prefix" do
          LyraClientTestClass.site = "https://lyra-app/api/v1"
          expect(LyraClientTestClass.collection_path).to be == "/api/v1/automations"
          expect(LyraClientTestClass.collection_path({limit: 100, page: 1, test: 'test'})).to be == "/api/v1/automations?limit=100&page=1&test=test"
        end

        it "should build the collection path without prefix" do
          LyraClientTestClass.site = "https://lyra-app"
          expect(LyraClientTestClass.collection_path).to be == "/automations"
          expect(LyraClientTestClass.collection_path({limit: 100, page: 1, test: 'test'})).to be == "/automations?limit=100&page=1&test=test"
        end

      end

      describe "find" do

        class LyraClientTestFindClass < LyraClient::Base
          self.site = "https://lyra-app/api/v1"
          self.collection_name = 'automations'
        end

        describe "all" do

          before(:each) do
            @elements = [FakeFactory.automation('id' => 1)]
            Excon.stub({}, {:body => @elements.to_json, :status => 200})
          end

          it "should get all" do
            all = LyraClientTestFindClass.all({"X-Auth-Token" => 'this_is_a_token'})
            all.each_with_index do |element, index|
              expect(element.attributes.to_json).to be == @elements[index].to_json
            end
          end

        end

        describe "single" do

          before(:each) do
            @element = FakeFactory.automation('id' => 1)
            Excon.stub({}, {:body => @element.to_json, :status => 200})
          end

          it "should find one" do
            one = LyraClientTestFindClass.find("3", {"X-Auth-Token" => '3eb2d7b9d99f41a388cd3eab7c070011'})
            expect(one.attributes).to be == @element.to_json
          end

        end

      end

    end

    describe "object methods" do

    end

  end

  describe "collection" do

    describe "Access to response headers" do

      class LyraClientTestCollectionClass < LyraClient::Base
        self.site = "https://lyra-app/api/v1"
        self.collection_name = 'automations'
      end

      before(:each) do
        @elements = [FakeFactory.automation('id' => 1), FakeFactory.automation('id' => 2)]
        Excon.stub({}, {:body => @elements.to_json, :status => 200})
      end

      it "should return a collection class" do
        all = LyraClientTestCollectionClass.all({"X-Auth-Token" => 'aa5c1921d9cc4afd90a2892f2e90017f'})
        expect(all).to be_instance_of(LyraClient::Collection)
      end

      it "should have access to the the response" do
        all = LyraClientTestCollectionClass.all({"X-Auth-Token" => 'aa5c1921d9cc4afd90a2892f2e90017f'})
        expect(all.response).to be_truthy
      end

      it "should iterate" do
        all = LyraClientTestCollectionClass.all({"X-Auth-Token" => 'aa5c1921d9cc4afd90a2892f2e90017f'})
        expect(all.count).to be == 2
        iterator = 0
        all.each do |item|
          iterator += 1
          expect(item).to be_truthy
        end
        expect(iterator).to be == 2
      end

    end

  end

end
