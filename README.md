Civility
========

Civility is the easiest way to manage your Civ5 hotseat games hosted by [http://multiplayerrobot.com/](http://multiplayerrobot.com/).

Install
-------

    $ gem install civility


Usage
-----

Authenticate yourself:

    $ civility auth token

_Run `civility auth` if you don't know where to get your GMR token._

Get a list of your games:

    $ civility games


Download a save file to play:

    $ civility play game name

Open Civ5, play your hotseat turn, and save to the same file.

Upload you completed turn:

    $ civility complete game name

OS Support
----------

civility has only been minimally tested on OS X and Windows.

Security
--------

civility is cryptographically signed. To be sure the gem you install hasn’t been tampered with:

Add my public key (if you haven’t already) as a trusted certificate

    $ gem cert --add <(curl -Ls https://raw.githubusercontent.com/abraham/civility/master/certs/abraham.pem)
    $ gem install civility -P MediumSecurity

The MediumSecurity trust profile will verify signed gems, but allow the installation of unsigned dependencies.

This is necessary because not all of civility’s dependencies are signed, so we cannot use HighSecurity.

Troubleshooting
---------------

- If you get `UnexpectedError: {"ResultType"=>0, "PointsEarned"=>0}` when running `civility complete game name`, try `civility games` every five minutes until the games list shows it being your turn and then try `complete` again. The GMR API is frequently stale and returning the old `turn_id`.

- If your game isn't showing when you run `civility games` try running the command again. Frequently games are missing for from the GMR API response.
