require 'net/http'
require 'uri'
require 'json'

class Civility
  class Ext
    class Slack
      def initialize(token)
        @token = token
      end

      def post_message(channel_name, text, username)
        params = {
          token: @token,
          channel: channel_name,
          link_names: 1,
          username: username,
          icon_emoji: ':robot_face:',
          text: text
        }
        post('https://slack.com/api/chat.postMessage', params)
      end

      private

      def post(url, params = {})
        uri = URI.parse(url)
        uri.query = URI.encode_www_form(params)
        http = Net::HTTP.new(uri.host, 443)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.request_uri)
        response = http.request(request)
        [response.code.to_i, JSON.parse(response.body)]
      end
    end
  end
end
