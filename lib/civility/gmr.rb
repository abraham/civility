require 'net/http'
require 'uri'
require 'json'

class Civility
  class GMR
    API_BASE = 'http://multiplayerrobot.com/api/Diplomacy'

    def initialize(auth_key, user_id = nil)
      @auth_key = auth_key
      @user_id = user_id
    end

    def self.auth_url
      'http://multiplayerrobot.com/download'
    end

    def user(user_id = nil)
      user_id = current_user_id if user_id.nil?
      code, response = get('GetGamesAndPlayers', playerIDText: user_id)
      fail "Unable to get user #{response}" if code != 200
      data = JSON.parse(response)
      data['Players'].find { |player| player['SteamID'].to_i == user_id.to_i }
    end

    def games
      code, response = get('GetGamesAndPlayers', playerIDText: current_user_id)
      fail "Unable to get games #{response}" if code != 200
      data = JSON.parse(response)
      data['Games']
    end

    def download(game_id)
      code, response = get('GetLatestSaveFileBytes', gameId: game_id)
      fail "Unable to download file #{response}" if code != 200
      response
    end

    def upload(turn_id, save_file)
      code, response = post('SubmitTurn', save_file, turnId: turn_id)
      fail "Unable to upload file #{response}" if code != 200
      JSON.parse(response)
    end

    # TODO: Implement a method shortcut method to get a game turn_id
    # def turn_id(game_id)
    # end

    private

    attr_reader :auth_key

    def api_url(path)
      URI.parse([API_BASE, path].join('/'))
    end

    def current_user_id
      return @user_id if @user_id

      code, response = get('AuthenticateUser')
      fail 'Unable to get current_user_id' if code != 200
      @user_id = response.to_i
    end

    def get(path, params = {})
      uri = api_url path
      uri.query = encode_params_with_auth(params)
      response = Net::HTTP.get_response(uri)
      [response.code.to_i, response.body]
    end

    def post(path, body, params = {})
      uri = api_url path
      uri.query = encode_params_with_auth(params)
      http = Net::HTTP.new(uri.host)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = body
      response = http.request(request)
      [response.code.to_i, response.body]
    end

    def encode_params_with_auth(params)
      URI.encode_www_form(params.merge(authKey: auth_key))
    end
  end
end
