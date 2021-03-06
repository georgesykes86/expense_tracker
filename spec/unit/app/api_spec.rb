require_relative '../../../app/api'
require 'rack/test'

module ExpenseTracker
  RecordResult = Struct.new(:success?, :expense_id, :error_message)
  Record = Struct.new(:payee, :amount, :date)

  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    def parse_json(json)
      JSON.parse(json.body)
    end

    def parse_xml(xml)
      Ox.parse_obj(xml.body)
    end

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }

    describe 'POST /expenses' do
      context 'when the expense is successfully recorded' do
        let(:expense) { { 'some' => 'data' } }
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(true, 417, nil))
        end

        it 'returns the expense id' do
          post '/expenses', JSON.generate(expense)
          expect(parse_json(last_response)).to include('expense_id' => 417)
        end

        it 'responds with a 200 (ok)' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq(200)
        end


      end

      context 'when the expense fails validation' do
        let(:expense) { { 'some' => 'data' } }
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
        end

        it 'returns an error message' do
          post '/expenses', JSON.generate(expense)
          expect(parse_json(last_response)).to include('error' => 'Expense incomplete')
        end

        it 'responds with a 422 (Unprocessable entity)' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq(422)
        end
      end

      context 'when user submits a valid XML' do
        let(:expense) { { 'some' => 'data' } }
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(true,417,nil))
        end


        it 'responds with a 200 (ok)' do
          header 'Content-Type', 'text/xml'
          post '/expenses', Ox.dump(expense)
          expect(last_response.status).to eq(200)
        end

        it 'returns the expense id' do
          header 'Content-Type', 'text/xml'
          post '/expenses', Ox.dump(expense)
          expect(parse_xml(last_response)).to include('expense_id' => 417)
        end

      end

      context 'when a user submits an invalid XML' do
        let(:expense) { { 'some' => 'data' } }
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
        end

        it 'returns an error message' do
          header 'Content-Type', 'text/xml'
          post '/expenses', Ox.dump(expense)
          expect(parse_xml(last_response)).to include('error' => 'Expense incomplete')
        end

        it 'responds with a 422 (Unprocessable entity)' do
          header 'Content-Type', 'text/xml'
          post '/expenses', Ox.dump(expense)
          expect(last_response.status).to eq(422)
        end
      end

      context 'when a user submits an unrecognised data format' do
        let(:expense) { { 'some' => 'data' } }

        it 'returns an error message' do
          header 'Content-Type', 'text/plain'
          post '/expenses', expense.to_s
          expect(parse_json(last_response)).to include('error' => 'Unrecognised data format')
        end

        it 'responds with a 422 (Unrecognised format)' do
          header 'Content-Type', 'text/plain'
          post '/expenses', expense.to_s
          expect(last_response.status).to eq(422)
        end
      end

    end

    describe 'GET /expenses/:date' do
      context 'when expenses exist on the given date' do
        let(:date) {'2017-10-20'}
        before do
          allow(ledger).to receive(:expenses_on)
            .with(date)
            .and_return(Record.new("payee", 0.99, date))
        end

        it 'returns the expense record JSON' do
          get "/expenses/#{date}"
          expect(parse_json(last_response)).not_to be_empty
        end
        it 'responds with a 200 (OK)' do
          get "/expenses/#{date}"
          expect(last_response.status).to eq(200)
        end
      end

      context 'when there are no expenses on the given date' do
        let(:date) {'2017-10-21'}
        before do
          allow(ledger).to receive(:expenses_on)
            .with(date)
            .and_return(nil)
        end

        it 'returns an empty array as JSON' do
          get "/expenses/#{date}"
          expect(parse_json(last_response)).to be_empty
        end

        it 'responds with a 200 (OK)' do
          get "/expenses/#{date}"
          expect(last_response.status).to eq(200)
        end
      end

      context 'when the user request xml format back' do
        let(:date) {'2017-10-20'}
        before do
          allow(ledger).to receive(:expenses_on)
            .with(date)
            .and_return(Record.new("payee", 0.99, date))
        end

        it 'returns the expense record XML' do
          header 'Accept', 'text/xml'
          get "/expenses/#{date}"
          expect(parse_xml(last_response)).not_to be_empty
        end
        it 'responds with a 200 (OK)' do
          header 'Accept', 'text/xml'
          get "/expenses/#{date}"
          expect(last_response.status).to eq(200)
        end
      end

      context 'when the user request an unsupported format' do
        let(:date) {'2017-10-20'}
        before do
          allow(ledger).to receive(:expenses_on)
            .with(date)
            .and_return(Record.new("payee", 0.99, date))
        end

        it 'returns the expense record in JSON' do
          header 'Accept', 'text/plain'
          get "/expenses/#{date}"
          expect(parse_json(last_response)).to include('error' => 'Unrecognised data format')
        end
        it 'responds with a 200 (OK)' do
          header 'Accept', 'text/plain'
          get "/expenses/#{date}"
          expect(last_response.status).to eq(200)
        end
      end

    end
  end
end
