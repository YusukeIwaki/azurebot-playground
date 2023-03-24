### DEMO

```ruby
post '/webhook' do
  # Handle a new message...
  if params['type'] == 'message'
    client = BotConnectorClient.new(
      service_url: params['serviceUrl'],
      conversation_id: params['conversation']['id'],
      from_id: params['recipient']['id'],
    )
    activity_id = params['id']

    Thread.new do
      # Reply immediately
      id = client.create_message(activity_id: activity_id, text: 'Processing...')

      # Do something...
      sleep 1

      # update the reply
      client.update_message(activity_id: id, text: 'Result is ...')

      # And do something...
      sleep 1

      # update the reply
      client.update_message(activity_id: id, text: 'Result is Something')
    end
  end

  'OK'
end
```

![image](image.gif)

### Development

Prepare Azure bot, and set the enviroment variables as below.

```
export TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export CLIENT_SECRET=x.XXX-xXXXxxXXXXXXXxxxxXX-XXxxxXXXXXXX
```
