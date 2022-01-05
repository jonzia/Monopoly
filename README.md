# Monopoly

This Matlab package contains the necessary objects, functions, and scripts for training autonomous agents to play the board game Monopoly via reinforcement learning. This includes functionality for running Monte Carlo simulations of Monopoly games using either a random policy or an epsilon-greedy policy on a specified value function. The trained models may then be used with the provided `interface.mlx` script for implementation in player v. computer matches.

**Contents**
1. [Package Structure](#package-structure)
2. [Simplifying Assumptions](#simplifying-assumptions-in-simulation)
3. [Custom Reward Functions](#defining-custom-reward-functions)
4. [Training and Testing](#value-function-training-and-testing)
5. [Tutorial](#tutorial)
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

## Value Function Training and Testing

## Tutorial
### Tutorial Scripts
### Example Training and Testing Data
### Example Models

## Implementation in Real Games
