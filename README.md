# BOT-OPOLY (MONOPOLY)

This Matlab package contains the necessary objects, functions, and scripts for training autonomous agents to play the board game Monopoly via reinforcement learning. This includes functionality for running Monte Carlo simulations of Monopoly games using either a random policy or an epsilon-greedy policy on a specified value function. The trained models may then be used with the provided `interface.mlx` script for implementation in player v. computer matches.

**Contents**
1. [Package Structure](#package-structure)
2. [Simplifying Assumptions](#simplifying-assumptions-in-simulation)
3. [Custom Reward Functions](#defining-custom-reward-functions)
5. [Training and Testing](#value-function-training-and-testing)
6. [Implementation in Real Games](#implementation-in-real-games)

## Package Structure

The package centers on the `Monopoly` class, which when instantiated initializes the board and tracks all gameplay parameters. The object contains two important tables: `Monopoly.assets`, which tracks the assets for each player, and `Monopoly.board`, which tracks all other physical attributes of the board state. The class also contains member functions for performing player- and bank-side transactions, such as moving tokens, trading assets, and developing or mortgaging properties. Using member functions to perform tasks ensures that data are appropriately updated in the corresponding tables; for instance, using a member function to trade assets automatically updates both the `board` table with the physical assets and `assets` table with new cash and net worth balances.

This package is arranged in a hierarchical format: users need not interact directly with the Monopoly class for the purpose of training autonomous agents. Individual turns in a Monte Carlo simulation of the game are run by the function `game.turnManager()`, which evolves the board state based on either random selection among available actions, or based on an epsilon-greedy policy on a specified value function. Further up the hierarchy is the function `game.gameManager()`, which runs a full game composed of individual turns until either the maximum turns are performed or all but one players are bankrupt. The data outputted by the game manager are the board state and calculated return at each step, along with the resulting `Monopoly` object on the last turn of the simulation (for debugging). This data may then be used to train quality functions or analyze their performance.

This package makes frequent use of enumerations, which are contained in the `Classes` folder. A description of each enumeration may be found in the file header. These enumerations contain static information related to the Classic version of Monopoly, including the different Chance and Community Chest cards, as well as property values and rent tables. Thus, adapting this package to all but the Classic version of Monopoly may require updating these enumerations accordingly.

## Simplifying Assumptions in Simulation

There are several simplifying assumptions made by `game.turnManager()` which are intended to make Monte Carlo simulation more practical. These should be noted insofar as they may affect resulting value functions:

| Category | Assumption |
| ----------- | ----------- |
| Auctions | Auctions start by the auctioning player bidding either the mortgage value of the property or their remaining cash, whichever is lower. A player may only buy a property with cash on hand, and may not buy a property by selling or mortgaging assets. The auction then proceeds in player-order, with each player able to either raise the bid by $10 or withdraw from bidding. The bidding stops when one player remains. |
| Bankruptcy | In traditional Monopoly, if a player is bankrupted by the bank, the bank collects the player's assets and auctions them off. In this implementation, to incentivize optimization of net worth, all assets are forefeited to the player with the highest net worth. |
| Building Houses | The constraint that houses must be built evenly across properties has not been implemented in the current version. Houses may only be built on the player's turn. |
| Jail | Get out of jail free cards (GOJFC) may not be traded. Furthermore, a player may not pay $50 to be released from jail if they have a GOJFC; rather, they must use the card if they have it and three turns have passed without a double. |
| Raising Cash | When a player runs out of cash but has the net worth to pay a debt, they may mortgage properties or sell houses back to the bank. They may not trade with another player to raise capital to avoid mortgaging or selling assets. Additionally, they may not raise capital via mortgaging properties or selling assets unless there is a debt to be collected which can not be paid in cash. |
| Trading | Each player may propose only one trade per turn. Subject to the approval of the opposing player, trades may only consist of a 1-for-1 property swap, as permissible (i.e. properties undeveloped, not mortgaged, etc.). |

## Defining Custom Reward Functions

The user may wish to implement a different measure of reward with which to train the value function. Reward at each step is calculated using the member function `Monopoly.target()`. The game manager calculates the expected reward at each step by summing the reward over a specified number of steps (input `lambda`). Presently, if n<sub>i</sub> is the net worth for player i on the present turn, the reward is calculated as R(i) = n<sub>i</sub> - mean(n<sub>not i</sub>). This is meant to incentivize a player to make decisions which not only increase their net worth, but decrease the net worth of their opponents. Users may modify this reward function by re-writing the `Monopoly.target()` member function in `@Monopoly/Monopoly.m` accordingly.

## Value Function Training and Testing

### Tutorial Scripts
The file `Resources/tutorial.mlx` contains tutorials for generating gameplay data, training models to estimate the value function, and testing model performance. The tutorials use ensembled regression trees to model the value function, as decision-making in Monopoly is conducive to a decision tree format. This decision is otherwise arbitrary, however, and may be substituted for another model. The scripts included in this file are intended to provide the code fragments necessary to build full reinforcement learning paradigms.

### Example Training and Testing Data
Gameplay data generated using the corresponding modules in `tutorial.mlx` are available in the `Resources/Simulations/` folder. File names correspond to those shown in the relevant `tutorial.mlx` module. Please note that this package is actively being updated, and provided simulation data and models may contain errors present in prior versions of the package; these are intended for example and should not be considered deployment-ready training data or models.

### Example Models
Ensemble regression tree models generated using the corresponding gameplay data are available in the `Resources/Models/` folder. File names correspond to those shown in the relevant `tutorial.mlx` module.

## Implementation in Real Games
The file `Resources/interface.mlx` is intended to bride the gap between learned value functions and actual human v. computer live-action gameplay. The script enables the players to update the board state during a live-action multiplayer game such that the program may use the learned value function to make decisions. It has been written in an attempt to minimize time spent entering data and enable real-time gameplay. This includes replacing text-based entry with graphical interfaces wherever possible.

The live script generally has two sections. The first section is intended to update the board state when a human player makes one of a variety of actions; the second section is an analogue of the turn manager used during training, which manages the bot's turn. The former contains modules which may be run in any sequence as the human player takes actions, with hyperlinks present after each section to quickly return to the table of contents and select the next action. The latter is designed (but not required) to be run in sequence, with hyperlinks present after each section, quickly guiding the user to the next relevant section.

To use this script, ensure that the desired `model.mat` file is loaded into the workspace. The model may then be initialized with the desired parameters by running the `Initialize Model` section. _(Of note, one or more players may be a bot -- as in, their moves are completely determined by the trained models -- and any human player may take actions based on the trained models as well; simply running the corresponnding "A.I." section rather than "Human Player" section for the current player allows the bot to automate an action.)_ After each turn is completed, running the `Housekeeping` module handles tasks such as updating the current player based on the dice roll, allowing the user to skip back to the top of the script by pressing the hyperlink and beginning the next turn. A final note on this script concerns trading. Note that while the bot may only propose 1-for-1 property trades, it can analyze more complex trades offered by human players. Complex trades may be entered in the `Assess Offered Trade` section.
