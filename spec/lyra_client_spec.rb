require "spec_helper"

describe LyraClient do

  before(:all) do
    Excon.defaults[:mock] = true
  end

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
          # self.site = "https://lyra-app/api/v1"
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

          before(:all) do
            @elements = [{test: 'test'}]
            Excon.stub({}, {:body => @elements.to_json, :status => 200})
          end

          after(:all) do
            Excon.stubs.clear
          end

          it "should get all" do
            all = LyraClientTestFindClass.all({"X-Auth-Token" => 'd4e2f9461ef14137b055d1668758c9ca'})
            all.each_with_index do |element, index|
              expect(element.attributes.to_json).to be == @elements[index].to_json
            end
          end

        end

        describe "single" do

          before(:all) do
            @element = {test: 'test'}
            Excon.stub({}, {:body => @element.to_json, :status => 200})
          end

          after(:all) do
            Excon.stubs.clear
          end

          it "should find one" do
            one = LyraClientTestFindClass.find("3", {"X-Auth-Token" => 'd4e2f9461ef14137b055d1668758c9ca'})
            expect(one.attributes).to be == @element.to_json
          end

        end

      end

    end

    describe "object methods" do

    end

  end

end
