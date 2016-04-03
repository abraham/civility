describe Civility::GMR do
  let(:user_id) { '12345' }
  let(:user_id2) { '67890' }
  let(:auth_key) { 'secret' }
  let(:invalid_api_key) { 'invalid' }
  let(:gmr) { Civility::GMR.new(auth_key) }
  let(:file) { 'file contents' }
  let(:games_and_players_url) { "http://multiplayerrobot.com/api/Diplomacy/GetGamesAndPlayers?authKey=#{auth_key}&playerIDText=#{user_id}" }
  let(:auth_url) { "http://multiplayerrobot.com/api/Diplomacy/AuthenticateUser?authKey=#{auth_key}" }
  let(:user) do
    {
      'SteamID' => user_id,
      'PersonaName' => 'Cool player',
      'AvatarUrl' => "https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/fe/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb.jpg",
      'PersonaState' => 4,
      'GameID' => 0
    }
  end
  let(:user2) do
    {
      'SteamID' => user_id2,
      'PersonaName' => 'Awesome player',
      'AvatarUrl' => "https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/fe/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb.jpg",
      'PersonaState' => 4,
      'GameID' => 0
    }
  end
  let(:game) do
    {
      'Name' => 'Super Awesome Civ 5 Game',
      'GameId' => 1,
      'Players' => [{
        'UserId' => 76561197967777429,
        'TurnOrder' => 1
      }, {
        'UserId' => 76561197980213624,
        'TurnOrder' => 0
      }],
      'CurrentTurn' => {
        'TurnId' => 334,
        'Number' => 39,
        'UserId' => 76561197967777429,
        'Started' => '2016-02-26T16:53:50.723',
        'Expires' => '2016-02-28T16:53:50.723',
        'Skipped' => false,
        'PlayerNumber' => 3,
        'IsFirstTurn' => false
      },
      'Type' => 0
    }
  end
  let(:games_and_players_response) do
    {
      Games: [game],
      Players: [user, user2],
      CurrentTotalPoints: 39
    }
  end
  let(:games_and_players_response_json) { JSON.dump(games_and_players_response) }
  let(:upload_response) { { 'ResultType' => 1, 'PointsEarned' => 2 } }

  describe '#auth_key' do
    it 'returns the auth_key set on initialize' do
      expect(gmr.send(:auth_key)).to eq(auth_key)
    end
  end

  describe '#auth_url' do
    it 'returns the auth URL' do
      expect(Civility::GMR.auth_url).to eq('http://multiplayerrobot.com/download')
    end
  end

  describe '#api_url' do
    it 'builds the full API URL' do
      expect(gmr.send(:api_url, 'AuthenticateUser').to_s).to eq('http://multiplayerrobot.com/api/Diplomacy/AuthenticateUser')
    end
  end

  describe '#current_user_id' do
    it 'returns the id' do
      stub_request(:get, auth_url).to_return(status: 200, body: user_id)

      expect(gmr.send(:current_user_id)).to eq(user_id.to_i)
    end

    it 'caches the id' do
      stub = stub_request(:get, auth_url).to_return(status: 200, body: user_id)

      gmr.send :current_user_id
      gmr.send :current_user_id

      expect(stub).to have_been_requested.once
    end
  end

  describe '#user' do
    before(:each) do
      stub_request(:get, auth_url)
        .to_return(status: 200, body: user_id)
    end

    it 'returns a the current user' do
      stub_request(:get, games_and_players_url).to_return(status: 200, body: games_and_players_response_json)

      expect(gmr.user).to eq(user)
    end

    context 'with user_id' do
      it 'returns the user with that ID' do
        stub_request(:get, "http://multiplayerrobot.com/api/Diplomacy/GetGamesAndPlayers?authKey=#{auth_key}&playerIDText=#{user_id2}")
          .to_return(status: 200, body: JSON.dump(games_and_players_response))

        expect(gmr.user(user_id2)).to eq(user2)
      end
    end

    context 'error response' do
      it 'throws an error' do
        stub_request(:get, games_and_players_url)
          .to_return(status: 500, body: nil)

        expect { gmr.user }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#games' do
    let(:gmr) { Civility::GMR.new(auth_key, user_id) }

    it 'returns games' do
      stub = stub_request(:get, games_and_players_url).to_return(status: 200, body: games_and_players_response_json)

      expect(gmr.games).to eq([game])
      expect(stub).to have_been_requested.once
    end

    context 'error response' do
      it 'throws an exception' do
        stub_request(:get, games_and_players_url).to_return(status: 500, body: nil)

        expect { gmr.games }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#download' do
    let(:gmr) { Civility::GMR.new(auth_key, user_id) }
    let(:download_url) { "http://multiplayerrobot.com/api/Diplomacy/GetLatestSaveFileBytes?authKey=#{auth_key}&gameId=#{game_id}" }
    let(:game_id) { 54321 }

    it 'includes file in post' do
      stub = stub_request(:get, download_url).to_return(status: 200, body: file)

      expect(gmr.download(game_id)).to eq(file)
      expect(stub).to have_been_requested.once
    end

    context 'error response' do
      it 'throws an exception' do
        stub_request(:get, download_url).to_return(status: 500, body: nil)

        expect { gmr.download(game_id) }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#upload' do
    let(:gmr) { Civility::GMR.new(auth_key, user_id) }
    let(:upload_url) { "http://multiplayerrobot.com/api/Diplomacy/SubmitTurn?authKey=#{auth_key}&turnId=#{turn_id}" }
    let(:turn_id) { 5 }

    it 'includes file in post' do
      stub = stub_request(:post, upload_url).with(body: file).to_return(status: 200, body: JSON.dump(upload_response))

      expect(gmr.upload(turn_id, file)).to eq(upload_response)
      expect(stub).to have_been_requested.once
    end

    context 'error response' do
      it 'throws an exception' do
        stub_request(:post, upload_url).to_return(status: 500, body: nil)

        expect { gmr.upload(turn_id, file) }.to raise_error(RuntimeError)
      end
    end
  end
end
