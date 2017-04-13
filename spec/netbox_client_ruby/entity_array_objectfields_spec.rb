require 'spec_helper'

describe NetboxClientRuby::Entity do
  class TestSubPoro
    attr_accessor :name

    def initialize(data)
      @name = data['name']
    end
  end
  class TestEntity5
    include NetboxClientRuby::Entity

    attr_accessor :test_id
    path 'tests/:test_id'
    array_object_fields an_object_array: TestSubPoro

    def initialize
      @test_id = 42
    end
  end
  class TestSubEntity
    include NetboxClientRuby::Entity

    attr_accessor :my_id
    path 'tests/:my_id/sub'

    def initialize(my_id, data = nil)
      @my_id = my_id
      self.data = data
    end
  end
  class TestEntity6
    include NetboxClientRuby::Entity

    attr_accessor :test_id
    path 'tests/:test_id'
    array_object_fields an_object_array: proc { |data| TestSubEntity.new(@test_id, data) }

    def initialize
      @test_id = 42
    end
  end

  let(:faraday_stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday) do
    Faraday.new(url: 'https://netbox.test/api/', headers: NetboxClientRuby::Connection.headers) do |faraday|
      faraday.adapter :test, faraday_stubs
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/
    end
  end
  let(:response_json) do
    <<-json
      {
        "name": "Beat",
        "boolean": true,
        "number": 1,
        "float_number": 1.2,
        "date": "2014-05-28T18:46:18.764425Z",
        "an_object": {
          "key": "value",
          "second": 2
        },
        "an_array": [],
        "an_object_array": [
          {
            "name": "obj1"
          }, {
            "name": "obj2"
          }, {
            "name": "obj3"
          }
        ],
        "counter": 1
      }
    json
  end
  let(:url) { '/api/tests/42' }
  let(:subject) { TestEntity.new }

  before do
    faraday_stubs.get(url) do |_env|
      [200, { content_type: 'application/json' }, response_json]
    end
    allow(Faraday).to receive(:new).and_return faraday
  end

  describe 'objectification of the content of array fields' do
    context 'anonymous classes' do
      it 'does not return `an_object_array` as Hashes' do
        expect(subject.an_object_array).to be_a Array
        subject.an_object_array.each do |obj|
          expect(obj).to_not be_a Hash
        end
      end

      it 'returns the correct values' do
        arr = subject.an_object_array

        expect(arr[0].name).to eq 'obj1'
        expect(arr[1].name).to eq 'obj2'
        expect(arr[2].name).to eq 'obj3'
      end

      it 'does not call the server for the sub-object' do
        expect(faraday).to receive(:get).once.and_call_original

        expect(subject._name).to eq 'Beat'
        expect(subject.an_object_array).to_not be_a Hash
      end

      it 'is a new object everytime' do
        a = subject.an_object_array
        b = subject.an_object_array

        expect(a).to_not be b
        expect(b).to_not be a
      end
    end

    context 'poro classes' do
      let(:subject) { TestEntity5.new }

      it 'does not return `an_object_array` as Hashes' do
        expect(subject.an_object_array).to be_a Array
        subject.an_object_array.each do |obj|
          expect(obj).to be_a TestSubPoro
        end
      end

      it 'returns the correct values' do
        arr = subject.an_object_array

        expect(arr[0].name).to eq 'obj1'
        expect(arr[1].name).to eq 'obj2'
        expect(arr[2].name).to eq 'obj3'
      end

      it 'does not call the server for the sub-object' do
        expect(faraday).to receive(:get).once.and_call_original

        expect(subject._name).to eq 'Beat'
        expect(subject.an_object_array).to_not be_a Hash
      end

      it 'is a new object everytime' do
        a = subject.an_object_array
        b = subject.an_object_array

        expect(a).to_not be b
        expect(b).to_not be a
      end
    end

    context 'entity classes' do
      let(:subject) { TestEntity6.new }

      it 'does not return `an_object_array` as Hashes' do
        expect(subject.an_object_array).to be_a Array
        subject.an_object_array.each do |obj|
          expect(obj).to be_a TestSubEntity
        end
      end

      it 'returns the correct values' do
        arr = subject.an_object_array

        expect(arr[0].name).to eq 'obj1'
        expect(arr[1].name).to eq 'obj2'
        expect(arr[2].name).to eq 'obj3'
      end

      it 'does not call the server for the sub-object' do
        expect(faraday).to receive(:get).once.and_call_original

        expect(subject._name).to eq 'Beat'
        expect(subject.an_object_array).to_not be_a Hash
      end

      it 'is a new object everytime' do
        a = subject.an_object_array
        b = subject.an_object_array

        expect(a).to_not be b
        expect(b).to_not be a
      end
    end
  end
end