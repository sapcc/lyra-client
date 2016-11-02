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
          self.headers = {'test'  => 'test'}
        end

        it "should build the collection path with prefix" do
          LyraClientTestClass.site = "https://lyra-app.com/api/v1"
          expect(LyraClientTestClass.collection_path).to be == "/api/v1/automations"
          expect(LyraClientTestClass.collection_path({limit: 100, page: 1, test: 'test'})).to be == "/api/v1/automations?limit=100&page=1&test=test"
        end

        it "should build the collection path without prefix" do
          LyraClientTestClass.site = "https://lyra-app.com"
          expect(LyraClientTestClass.collection_path).to be == "/automations"
          expect(LyraClientTestClass.collection_path({limit: 100, page: 1, test: 'test'})).to be == "/automations?limit=100&page=1&test=test"
        end

        describe "mergin headers" do

          it "should merge class headers with the request headers" do
            headers = LyraClientTestClass.collect_headers({"X-Auth-Token" => 'this_is_a_token'})
            expect(headers).to eql({"Content-Type"=>"application/json", "test"=>"test", "X-Auth-Token"=>"this_is_a_token"})
          end

        end

      end

      describe "find" do

        class LyraClientTestFindClass < LyraClient::Base
          self.site = "https://lyra-app.com/api/v1"
          self.collection_name = 'automations'
        end

        describe "all" do

          it "should get all" do
            elements = [FakeFactory.automation('id' => 1)]
            Excon.stub({path: "/api/v1/automations", method: 'get'}, {:body => elements.to_json, :status => 200})

            all = LyraClientTestFindClass.all({"X-Auth-Token" => 'this_is_a_token'})
            all.each_with_index do |element, index|
              expect(element.attributes).to be == elements[index]
            end
          end

        end

        describe "by id (single)" do

          it "should find one" do
            element = FakeFactory.automation('id' => 3)
            Excon.stub({path: "/api/v1/automations/3", method: 'get'}, {:body => element.to_json, :status => 200})

            one = LyraClientTestFindClass.find("3", {"X-Auth-Token" => 'this_is_a_token'})
            expect(one.attributes).to be == element
          end

        end

      end

    end

    describe "object methods" do

      class LyraClientTestObjMethodsClass < LyraClient::Base
        self.site = "http://localhost:3001/api/v1"
        self.collection_name = 'automations'
      end

      it "should save" do
        # save
        element = FakeFactory.automation('id' => 1)
        Excon.stub({path: "/api/v1/automations", method: 'post'}, {:body => element.to_json, :status => 200})

        # create
        automation = LyraClientTestObjMethodsClass.new(nil, FakeFactory.automation(name: 'kaaa'))
        automation.save()
        expect(automation.attributes['id']).to be == 1
      end

      it "should update" do
        # get existing automation
        element = FakeFactory.automation('id' => 1)
        Excon.stub({}, {:body => element.to_json, :status => 200})
        automation = LyraClientTestFindClass.find("1")

        # save changes
        Excon.stubs.clear
        element = FakeFactory.automation('id' => 1, 'timeout' => 666)
        # we actually test that a rest api call is being fired with the right parameters
        Excon.stub({path: "/api/v1/automations/1", method: 'put'}, {:body => element.to_json, :status => 200})
        automation.attributes['timeout'] = 666
        automation.save
      end

      it "should destroy" do
        # get existing automation
        Excon.stub({}, {:body => FakeFactory.automation('id' => 1).to_json, :status => 200})
        automation = LyraClientTestFindClass.find("1")

        # destroy
        Excon.stubs.clear
        # we actually test that a rest api call is being fired with the right parameters
        Excon.stub({path: "/api/v1/automations/1", method: 'delete'}, {:body => "", :status => 200})
        automation.destroy
      end

    end

  end

  describe "collection" do

    describe "Access to response headers" do

      class LyraClientTestCollectionClass < LyraClient::Base
        self.site = "https://lyra-app.com/api/v1"
        self.collection_name = 'automations'
        self.headers = {"X-Auth-Token" => 'this_is_a_token'}
      end

      before(:each) do
        @elements = [FakeFactory.automation('id' => 1), FakeFactory.automation('id' => 2)]
        Excon.stub({}, {:body => @elements.to_json, :status => 200})
      end

      it "should return a collection class" do
        all = LyraClientTestCollectionClass.all()
        expect(all).to be_instance_of(LyraClient::Collection)
      end

      it "should have access to the the response" do
        all = LyraClientTestCollectionClass.all()
        expect(all.response).to be_truthy
      end

      it "should iterate" do
        all = LyraClientTestCollectionClass.all({"X-Auth-Token" => 'override_this_is_a_token'})
        expect(all.count).to be == 2
        iterator = 0
        all.each do |item|
          iterator += 1
          expect(item).to be_truthy
        end
        expect(iterator).to be == 2
      end

      context 'Pagination' do

        it "should be kaminari compatible" do
          # reset the stubs
          Excon.stubs.clear
          Excon.stub({}, {:body => @elements.to_json, :status => 200, :headers => {}})
          # test kaminari methods
          all = LyraClientTestCollectionClass.all({"X-Auth-Token" => 'this_is_a_token'})
          expect(all.total_pages).to be == 0
          expect(all.current_page).to be  == 0
          expect(all.limit_value).to be == 0

          # reset the stubs
          Excon.stubs.clear
          Excon.stub({}, {:body => @elements.to_json, :status => 200, :headers => {'Pagination-Elements' => '20', 'Pagination-Page' => '1', 'Pagination-Per-Page' => '10' }})
          # test kaminari methods
          all = LyraClientTestCollectionClass.all({"X-Auth-Token" => 'this_is_a_token'})
          expect(all.total_pages).to be == 2
          expect(all.current_page).to be  == 1
          expect(all.limit_value).to be == 10

          # reset the stubs
          Excon.stubs.clear
          Excon.stub({}, {:body => @elements.to_json, :status => 200, :headers => {'Pagination-Elements' => '22', 'Pagination-Page' => '2', 'Pagination-Per-Page' => '5' }})
          # test kaminari methods
          all = LyraClientTestCollectionClass.all({"X-Auth-Token" => 'this_is_a_token'})
          expect(all.total_pages).to be == 5
          expect(all.current_page).to be  == 2
          expect(all.limit_value).to be == 5

          # reset the stubs
          Excon.stubs.clear
          Excon.stub({}, {:body => @elements.to_json, :status => 200, :headers => {'Pagination-Elements' => '5', 'Pagination-Page' => '1', 'Pagination-Per-Page' => '6' }})
          # test kaminari methods
          all = LyraClientTestCollectionClass.all({"X-Auth-Token" => 'this_is_a_token'})
          expect(all.total_pages).to be == 1
          expect(all.current_page).to be  == 1
          expect(all.limit_value).to be == 6
        end

      end

    end

  end

  describe "Exceptions" do

    it "should raise an exception when no 200 or 201" do
      Excon.stub({}, {:body => "Not found", :status => 404})
      expect { LyraClientTestFindClass.find("1") }.to raise_error
    end

  end

end
