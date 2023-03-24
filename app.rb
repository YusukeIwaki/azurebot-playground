require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || :development).to_sym

require 'net/http'

use Rack::JSONBodyParser

get '/' do
  'It works!'
end

class BotConnectorClient
  def initialize(service_url:, conversation_id:, from_id:)
    @service_url = service_url
    @conversation_id = conversation_id
    @from_id = from_id
  end

  def fetch_access_token
    # https://learn.microsoft.com/ja-jp/azure/bot-service/rest-api/bot-framework-rest-connector-authentication?view=azure-bot-service-4.0&tabs=singletenant#bot-to-connector
    resp = Net::HTTP.post_form(
      URI("https://login.microsoftonline.com/#{ENV['TENANT_ID']}/oauth2/v2.0/token"),
      {
        'grant_type' => 'client_credentials',
        'client_id' => ENV['CLIENT_ID'],
        'client_secret' => ENV['CLIENT_SECRET'],
        'scope' => 'https://api.botframework.com/.default',
      }
    )
    JSON.parse(resp.body)['access_token']
  end

  private def net_http_request(uri, request)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  private def endpoint_url_for(activity_id)
    "#{@service_url}v3/conversations/#{@conversation_id}/activities/#{URI.encode_www_form_component(activity_id)}"
  end

  def create_message(activity_id:, text:)
    @token ||= fetch_access_token

    uri =URI(endpoint_url_for(nil))
    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@token}"
    request.body = {
      type: "message",
      from: { id: @from_id },
      text: text,
    }.to_json

    response = net_http_request(uri, request)
    body = JSON.parse(response.body)
    puts "response body: #{body}"

    body['id']
  end

  def update_message(activity_id:, text:)
    @token ||= fetch_access_token

    uri =URI(endpoint_url_for(activity_id))
    request = Net::HTTP::Put.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@token}"
    request.body = {
      type: "message",
      from: { id: @from_id },
      text: text,
    }.to_json

    response = net_http_request(uri, request)
    body = JSON.parse(response.body)
    puts "response body: #{body}"

    body['id']
  end
end

post '/webhook' do
  puts params
  if params['type'] == 'message'
    client = BotConnectorClient.new(
      service_url: params['serviceUrl'],
      conversation_id: params['conversation']['id'],
      from_id: params['recipient']['id'],
    )
    activity_id = params['id']
    text = params['text'].gsub(/<at>[a-zA-Z0-9]+<\/at>/, '').strip

    puts "text: #{text}"
    Thread.new do
      id = client.create_message(activity_id: activity_id, text: 'Processing...')
      sleep 1
      client.update_message(activity_id: id, text: 'Result is ...')
      sleep 1
      client.update_message(activity_id: id, text: 'Result is Something')
    end
  end

  'OK'
end
