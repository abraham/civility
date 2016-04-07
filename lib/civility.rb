require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'thor'

class Civility < Thor
  VERSION = '4'
  SAVE_DIRECTORY = "/Documents/Aspyr/Sid\ Meier\'s\ Civilization\ 5/Saves/hotseat/"
  FILE_PREFIX = 'civility'
  FILE_EXT = 'Civ5Save'
  CONFIG_FILE = '.civility.yml'

  def initialize(*args)
    @config = load_config
    @gmr = Civility::GMR.new(auth_key, user_id) if auth_key
    super(*args)
  end

  desc 'auth', 'Save auth key'
  option aliases: :a
  def auth(auth_key = nil)
    if auth_key.nil?
      auth_url = Civility::GMR.auth_url
      puts "Grab your Authentication Key from #{auth_url}"
      system('open', auth_url)
    else
      @gmr = Civility::GMR.new(auth_key)
      @config[:version] = VERSION
      @config[:auth] = auth_key
      @config[:user] = user
      self.config = @config
      puts "Hello, #{user['PersonaName']}, your auth is all configured!"
    end
  end

  desc 'games', 'List your current games'
  option aliases: :g
  def games
    return missing_auth_error unless auth_key
    output_games sync_games
  end

  desc 'play', 'Download a game to play'
  option aliases: :p
  def play(*name)
    name = name.join(' ')
    return missing_auth_error unless auth_key
    game = game_by_name(name)
    return missing_game_error(name) unless game
    path = save_path(game)
    data = @gmr.download(game['GameId'])
    save_file(path, data)
    puts "Saved #{game['Name']} to #{path}"
    sync_games
  end

  desc 'complete', 'Upload a completed turn'
  option aliases: :c
  def complete(*name)
    name = name.join(' ')
    return missing_auth_error unless auth_key
    game = game_by_name(name)
    return missing_game_error(name) unless game
    path = save_path(game)
    response = @gmr.upload(game['CurrentTurn']['TurnId'], File.read(path))
    case response['ResultType']
    when 0
      puts "UnexpectedError: #{response}"
    when 1
      puts "You earned #{response['PointsEarned']} points completing #{game['Name']} from #{path}"
      notify_slack(game) if @config[:slack]
    when 2
      puts "It's not your turn"
    when 3
      puts 'You already submitted your turn'
    else
      puts 'UnexpectedError'
    end
  end

  desc 'slack', 'Enable slack integration'
  def slack(status, bot_token = nil, channel_name = nil, next_player_name = nil, game_name = nil)
    if status == 'on'
      if [bot_token, channel_name, next_player_name, game_name].any?(&:nil?)
        puts 'Bot token, channel name, next player name, and game name are required'
        puts '$ civility slack on xoxb-123xyz awecome_channel sam awesome civ 5 game'
      else
        game = game_by_name(game_name)
        return missing_game_error(name) unless game
        @config[:slack].merge!(
          game['GameId'] => {
            channel_name: channel_name,
            bot_token: bot_token,
            next_player_name: next_player_name
          }
        )
        puts "Slack integration enabled for #{game_name}"
      end
    else
      @config.delete(:slack)
      puts 'Slack integration disabled'
    end
    self.config = @config
  end

  private

  def notify_slack(game)
    slack_config = @config[:slack][game['GameId']]
    return puts 'Slack not configured for game' unless slack_config
    slack = Civility::Ext::Slack.new(slack_config[:bot_token])
    message = "@#{slack_config[:next_player_name]}'s turn!"
    code, body = slack.post_message(slack_config[:channel_name], message, 'Shelly')
    puts "Error updating Slack: #{body}" unless code == 200
  end

  def sync_games
    games = @gmr.games
    self.config = @config.merge(games: games, updated_at: Time.now.to_i)
    games
  end

  def save_path(game)
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
    games.each do |game|
      turn = (user_id == game['CurrentTurn']['UserId'] ? " and it's your turn" : '')
      puts "#{game['Name']} with #{game['Players'].size} other players#{turn}"
    end
    puts "\nIf your games are missing, try again"
  end

  def game_by_name(name)
    name = normalize(name)
    games_list.find { |game| normalize(game['Name']) == name }
  end

  def user
    @gmr.user
  end

  def normalize(name)
    name.downcase.strip.gsub(/[^\w]/, '')
  end

  def save_file(path, data)
    file = open(path, 'wb')
    file.write(data)
    file.close
  end

  def load_config
    if config_file?
      @config = YAML.load_file config_path
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

  def missing_game_error(name)
    puts "Unable to find the game #{name}"
  end

  def missing_auth_error
    puts 'Please run `civility auth` first'
  end

  def config=(settings)
    File.open(config_path, 'w') do |file|
      file.write settings.to_yaml
    end
  end

  def config_path
    "#{Dir.home}/#{CONFIG_FILE}"
  end

  def config_file?
    File.exist?(config_path)
  end
end

require 'civility/gmr'
require 'civility/ext'
