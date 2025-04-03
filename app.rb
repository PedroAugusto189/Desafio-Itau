require 'sinatra'
require 'sinatra/json'
require 'time'

class TransactionAPI < Sinatra::Base
  configure do
    set :transactions, []
    set :port, 3000
  end

  helpers do
    def valid_transaction?(transaction)
      transaction.key?('amount') && transaction.key?('timestamp') &&
        transaction['amount'].is_a?(Numeric) &&
        !transaction['timestamp'].empty?
    end
  end

  # Rota para adicionar transação
  post '/transactions' do
    transaction = JSON.parse(request.body.read)

    if !valid_transaction?(transaction)
      status 422
      return json(error: 'Transação inválida')
    end

    settings.transactions << transaction
    status 201
    json(message: 'Transação adicionada')
  end

  # Rota para estatísticas
  get '/statistics' do
    now = Time.now
    one_minute_ago = now - 60

    recent_transactions = settings.transactions.select do |t|
      Time.parse(t['timestamp']) >= one_minute_ago rescue false
    end

    amounts = recent_transactions.map { |t| t['amount'].to_f }

    stats = {
      sum: amounts.sum.round(2),
      avg: amounts.empty? ? 0 : (amounts.sum / amounts.size).round(2),
      max: amounts.empty? ? 0 : amounts.max.round(2),
      min: amounts.empty? ? 0 : amounts.min.round(2),
      count: amounts.size
    }

    json(stats)
  end

  # Rota para limpar transações (útil para testes)
  delete '/transactions' do
    settings.transactions.clear
    json(message: 'Todas as transações foram removidas')
  end
end