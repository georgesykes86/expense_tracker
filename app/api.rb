require 'sinatra/base'
require 'json'
require_relative 'ledger'
require 'ox'

module ExpenseTracker
  class API < Sinatra::Base
    def initialize(ledger: Ledger.new)
      @ledger = ledger
      super()
    end

    post '/expenses' do
      if ['application/json', 'application/x-www-form-urlencoded'].include? request.media_type
        expense = JSON.parse(request.body.read)
        result = @ledger.record(expense)

        if result.success?
          JSON.generate('expense_id' => result.expense_id)
        else
          status 422
          JSON.generate('error' => result.error_message)
        end
      elsif request.media_type == 'text/xml'
        expense = Ox.parse_obj(request.body.read)
        result = @ledger.record(expense)

        if result.success?
          Ox.dump('expense_id' => result.expense_id)
        else
          status 422
          Ox.dump('error' => result.error_message)
        end
      else
        status 422
        return JSON.generate('error' => 'Unrecognised data format')
      end
    end

    get '/expenses/:date' do
      if request.accept? 'application/json'
        result = @ledger.expenses_on(params['date']) || []
        JSON.generate(result)
      elsif request.accept? 'text/xml'
        result = @ledger.expenses_on(params['date']) || []
        result_json = JSON.generate(result)
        Ox.dump(result_json)
      else
        JSON.generate('error' => 'Unrecognised data format')
      end
    end
  end
end
