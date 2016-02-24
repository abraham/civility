require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'thor'

class GMR < Thor
  VERSION = '1'
  SAVE_DIRECTORY = "/Documents/Aspyr/Sid\ Meier\'s\ Civilization\ 5/Saves/hotseat/"
  FILE_PREFIX = 'gmr'
  FILE_EXT = 'Civ5Save'
  API = 'http://multiplayerrobot.com/api/Diplomacy/'

  def initialize(*args)
    @config = load_config
    super(*args)
  end

  desc 'auth', 'Save auth key'
  def auth(key = nil)
    if key.nil?
      url = 'http://multiplayerrobot.com/download'
      puts "Grab your Authentication Key from #{url}"
      system('open', url)
    else
      @config[:version] = VERSION
      @config[:auth] = key
      @config[:user] = user
      self.config = @config
      puts "Hello, #{user['PersonaName']}, your auth is all configured!"
    end
  end

  desc "games", "List your current games"
  def games
    return missing_auth_error unless auth_key
    response = get('GetGamesAndPlayers', {authKey: auth_key, playerIDText: user_id})
    response = JSON.parse(response)
    output_games(response['Games'])
    self.config = @config.merge(games: response['Games'], updated_at: Time.now.to_i)
  end

  desc 'play', 'Download a game to play'
  def play(name)
    return missing_auth_error unless auth_key
    game = game_by_name(name)
    return missing_game_error unless game
    path = game_path(game)
    file('GetLatestSaveFileBytes', {authKey: auth_key, gameID: game['GameId']}, path)
    puts "Saved #{game['Name']} to #{path}"
  end

  desc 'complete', 'Upload a completed turn'
  def complete(name)
    return missing_auth_error unless auth_key
    game = game_by_name(name)
    return missing_game_error unless game
    path = game_path(game)
    response = upload_file('SubmitTurn', {authKey: auth_key, turnId: game['CurrentTurn']['TurnId']}, path)
    response = JSON.parse(response)
    case response['ResultType']
    when 0
      puts "UnexpectedError: #{response}"
    when 1
      puts "You earned #{response['PointsEarned']} points completing #{game['Name']} from #{path}"
    when 2
      puts "It's not your turn"
    when 3
      puts 'You already submitted your turn'
    else
      puts 'UnexpectedError'
    end
  end

  private

  def game_path(game)
    "#{Dir.home}#{SAVE_DIRECTORY}#{FILE_PREFIX}-#{normalize(game['Name'])}-#{game['GameId']}.#{FILE_EXT}"
  end

  def auth_key
    @config[:auth]
  end

  def user_id
    @config[:user]['SteamID']
  end

  def games_list
    @config[:games]
  end

  def output_games(games)
    for game in games
      turn = (user_id == game['CurrentTurn']['UserId'] ? " and it's your turn" : '')
      puts "#{game['Name']} with #{game['Players'].size} other players#{turn}"
    end
    puts "If your games are missing, try again" if games.size == 0
  end

  def game_by_name(name)
    name = normalize(name)
    games_list.find {|game| normalize(game['Name']) == name}
  end

  def user
    user_id = get('AuthenticateUser', {authKey: auth_key})
    response = get('GetGamesAndPlayers', {authKey: auth_key, playerIDText: user_id})
    players = JSON.parse(response)['Players']
    user_from_players(user_id, players)
  end

  def user_from_players(user_id, players)
    user_id = user_id.to_i
    players.find {|player| player['SteamID'] == user_id }
  end

  def normalize(name)
    name.downcase.strip.gsub(/[^\w]/, '')
  end

  def get(method, params)
    uri = URI.join(API, method)
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)
    fail error_message(response) unless response.code == '200'
    response.body
  end

  def file(method, params, path)
    uri = URI.parse("#{API}#{method}")
    uri.query = URI.encode_www_form(params)
    f = open(path, "wb")
    Net::HTTP.start(uri.host) do |http|
      http.request_get(uri.request_uri) do |response|
        fail error_message(response) unless response.code == '200'
        response.read_body do |segment|
          f.write(segment)
        end
      end
    end
  ensure
    f.close()
  end

  def upload_file(method, params, path)
    uri = URI.parse("#{API}#{method}")
    uri.query = URI.encode_www_form(params)
    data = File.read(path)
    http = Net::HTTP.new(uri.host)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = data
    response = http.request(request)
    fail error_message(response) unless response.code == '200'
    response.body
  end

  def load_config
    if config_file?
      @config = YAML::load_file config_path
    else
      self.config = {}
    end
  end

  def error_message(response)
    body = JSON.parse(response.body)
    "Code: #{response.code}\nBody: #{body}"
  rescue JSON::ParserError
    "Unable to parse response\nCode: #{response.code}\nBody: #{response.body}"
  end

  def missing_game_error
    puts 'Unable to find that game'
  end

  def missing_auth_error
    puts 'Please run `gmr auth` first'
  end

  def config=(settings)
    File.open(config_path, 'w') do |file|
      file.write settings.to_yaml
    end
  end

  def config_path
    "#{Dir.home}/.gmr.yml"
  end

  def config_file?
    File.exist?(config_path)
  end
end
