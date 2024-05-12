# Made for the redstone chain composability hackathon

For AW '24 we made an interop tug of war game that could only be played if you
held a Downstream Zone Token. This is the [presentation](https://www.youtube.com/watch?v=kKmpWvOuL8g)

For this hack we want to improve on its limitations:

* Only one tug of war could happen at a time
* It only worked if you minted a zone
* Nobody could tell if you one or how convincingly you won
* To hand the rope to another person, you had to give them your zone token
* You had to run scripts at the command line to play

For this hack we want to show better cross game interop:

* Start a game using any downstream item token (ERC 1155)
* Make pulling the rope require getting and collecting items in a downstream
  zone.
* Allow any number of tug 'o wars to happen at the same time
* Have a leader board based on how many blocks it takes to pull the rope
  accross the line
* Show that the puller of the rope changes if you transfer your downstream item
  to someone else (another player or any other wallet)

Before the hack we:

* Set up a basic web ui with wallet support
* Pipe cleaned deployment to redstone with our original contracts
* Prepared our basic bill board plugin and tested it locally
* Tried to get AA infra going and it didn't work out in time.
* This commit was our starting point: 877c96f6b82ba6f34d26387d5e244ff2d04e3ef5
