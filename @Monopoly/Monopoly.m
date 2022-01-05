classdef Monopoly
    
    % Instantiates game board

    properties (SetAccess = public, GetAccess = public)
        numPlayers  double      % Number of players
        board       table       % Board state
        turn        double      % Turn number
        assets      table       % Table of assets per player
        current     double      % Current player
        doubleCounter   double  % Counter for number of doubles
        isJailed                % Is each player jailed?
        isBankrupt              % Is each player bankrupt?
        jailCounter     double  % Counter for each jailed player
        stateLength             % Length of state vector
    end

    methods
        
        % Class constructor
        function obj = Monopoly(numPlayers)

            % Assign variables
            obj.numPlayers = numPlayers; obj.turn = 1; obj.current = 1;
            obj.doubleCounter = 0; obj.isJailed = false(1, numPlayers);
            obj.jailCounter = zeros(numPlayers, 1); obj.isBankrupt = false(1, numPlayers);
            obj.stateLength = 57 + 4*obj.numPlayers;

            % Create board table
            index = 1:40; index = index'; isOwned = false(40, 1); owner = zeros(40, 1);
            isMortgaged = false(40, 1); numHouses = zeros(40 ,1);
            players = zeros(40, numPlayers); players(1, :) = ones(1, numPlayers);
            property = [Properties.null; Properties.Mediterranean; Properties.null; ...
                Properties.Baltic; Properties.null; Properties.ReadingRR; ...
                Properties.Oriental; Properties.null; Properties.Vermont; ...
                Properties.Connecticut; Properties.null; Properties.StCharles; ...
                Properties.Electric; Properties.States; Properties.Virginia; ...
                Properties.PennsylvaniaRR; Properties.StJames; Properties.null; ...
                Properties.Tennessee; Properties.NewYork; Properties.null; ...
                Properties.Kentucky; Properties.null; Properties.Indiana; ...
                Properties.Illinois; Properties.BandORR; Properties.Atlantic; ...
                Properties.Ventnor; Properties.Water; Properties.MarvinGardens; ...
                Properties.null; Properties.Pacific; Properties.NorthCarolina; ...
                Properties.null; Properties.Pennsylvania; Properties.ShortLineRR; ...
                Properties.null; Properties.ParkPlace; Properties.null; Properties.Boardwalk];
            tile = [Tiles.go;
                Tiles.null; Tiles.communityChest; Tiles.null; ...
                Tiles.incomeTax; Tiles.null; Tiles.null; Tiles.chance; ...
                Tiles.null; Tiles.null; Tiles.jail; Tiles.null; Tiles.null; ...
                Tiles.null; Tiles.null; Tiles.null; Tiles.null; Tiles.communityChest; ...
                Tiles.null; Tiles.null; Tiles.parking; Tiles.null; Tiles.chance; ...
                Tiles.null; Tiles.null; Tiles.null; Tiles.null; Tiles.null; ...
                Tiles.null; Tiles.null; Tiles.goToJail; Tiles.null; Tiles.null; ...
                Tiles.communityChest; Tiles.null; Tiles.null; Tiles.chance; ...
                Tiles.null; Tiles.luxuryTax; Tiles.null];
            set = [0, 1, 0, 1, 0, 0, 2, 0, 2, 2, ...
                0, 3, 0, 3, 3, 0, 4, 0, 4, 4, ...
                0, 5, 0, 5, 5, 0, 6, 6, 0, 6, ...
                0, 7, 7, 0, 7, 0, 0, 8, 0, 8]';
            obj.board = table(index, property, tile, set, isOwned, owner, ...
                isMortgaged, numHouses, players);

            % Compute bank's net worth
            totalCash = 15140; netWorth = totalCash; m = enumeration('Properties');
            for i = 1:length(m); netWorth = netWorth + m(i).mortgageValue; end

            % Create asset table
            asset = [Resource.netWorth; Resource.cash; Resource.getOutOfJail];
            bank = [netWorth; totalCash; 2];
            assets = table(asset, bank);
            for i = 1:obj.numPlayers
                assets.("P" + string(i)) = [1500; 1500; 0];
                assets.bank(1) = assets.bank(1) - 1500;
                assets.bank(2) = assets.bank(2) - 1500;
            end; obj.assets = assets;

        end

        % Move token
        function [obj, result] = moveToken(obj, roll, isRoll, collect)

            % Note: if ~isRoll, it is assumed tile number is specified
            if ~isRoll
                result = roll; temp = zeros(40, 1); temp(roll) = 1;
                obj.board.players(:, obj.current) = temp; return
            end

            % Else, get tile of current player
            tile = obj.board.index(obj.board.players(:, obj.current) == 1);

            % Get new tile
            newTile = mod(tile + roll, 40); 
            if newTile == 0; newTile = 40; end; result = newTile;
            temp = zeros(40, 1); temp(newTile) = 1;
            obj.board.players(:, obj.current) = temp;

            % Pass go?
            if newTile < tile; passGo = true; else; passGo = false; end

            % Collect 200 if pass go (if indicated)
            if collect && passGo
                [obj, ~] = obj.payCash(200, obj.current, Transaction.cashBankToPlayer);
            end

        end

        % Change player's net worth (or cash and net worth) by specified amount
        function [obj, isError] = changeNetWorth(obj, player, amount, resource)

            % Note: If resource = Resource.netWorth     Only net worth
            %       If resource = Resource.cash         Cash and net worth
            % Note: Player = 0 indicates bank

            if player == 0
                playerName = "bank";
            else
                playerName = "P" + string(player);
            end

            % Calculate new net worth
            newNetWorth = obj.assets.(playerName)(obj.assets.asset == ...
                Resource.netWorth) + amount;

            % Calculate new cash
            if resource == Resource.cash
                newCash = obj.assets.(playerName)(obj.assets.asset == ...
                    Resource.cash) + amount;
            end

            % If cash or net worth is negative, return an error
            if newNetWorth < 0 || (resource == Resource.cash && newCash < 0)
                isError = true; return
            end; isError = false;

            % Update net worth (+/- cash)
            obj.assets.(playerName)(obj.assets.asset == Resource.netWorth) = newNetWorth;
            if resource == Resource.cash
                obj.assets.(playerName)(obj.assets.asset == Resource.cash) = newCash;
            end

        end

        % Pay from bank to player or vice-versa; and from player to player
        function [obj, isError] = payCash(obj, amount, player, transaction, varargin)
            otherPlayer = player; if ~isempty(varargin); otherPlayer = varargin{1}; end
            % Note, if the bank does not have the cash, distribute maximum
            % amount possible.
            % cashBankToPlayer -> transfer from bank to player
            % cashPlayerToBank -> transfer from player to bank
            % cashPlayerToPlayer -> transfer from player to player

            % Extract data
            bankCash = obj.assets.bank(obj.assets.asset == Resource.cash);
            playerCash = obj.assets.("P" + string(player))(obj.assets.asset == Resource.cash);
            isError = false;

            switch transaction
                case Transaction.cashBankToPlayer

                    % If the bank does not have the cash, return an error
                    % and pay the maximum possible amount
                    if bankCash < amount; isError = true; end
                    [obj, ~] = obj.changeNetWorth(player, min(bankCash, amount), Resource.cash);
                    [obj, ~] = obj.changeNetWorth(0, -min(bankCash, amount), Resource.cash);

                case Transaction.cashPlayerToBank

                    % If the player does not have the cash, return an error
                    % and do not make a transaction
                    if playerCash < amount; isError = true; return; end

                    % Else, make the transaction
                    [obj, ~] = obj.changeNetWorth(player, -amount, Resource.cash);
                    [obj, ~] = obj.changeNetWorth(0, amount, Resource.cash);

                case Transaction.cashPlayerToPlayer

                    % If the player does not have the cash, return an error
                    % and do not make a transaction
                    if playerCash < amount; isError = true; return; end

                    % Else, make the transaction
                    [obj, ~] = obj.changeNetWorth(player, -amount, Resource.cash);
                    [obj, ~] = obj.changeNetWorth(otherPlayer, amount, Resource.cash);

            end

        end

        % Send a player to jail
        function [obj, newTile] = toJail(obj, player)
            [obj, newTile] = obj.moveToken(Tiles.jail.index, false, false);
            obj.isJailed(player) = true; obj.doubleCounter = 0;
        end

        % Buy a property
        function [obj, isError] = buyProperty(obj, property, player, varargin)

            % May enter custom price in case of auction
            if ~isempty(varargin)
                price = varargin{1};
            else
                price = property.purchasePrice;
            end

            % If the property is owned, return an error
            if obj.board.isOwned(obj.board.property == property)
                isError = true; return
            end
            % If the player has the cash, buy the property; else, return an
            % error
            [obj, isError] = obj.payCash(price, player, Transaction.cashPlayerToBank);
            if isError; return; end
            obj.board.isOwned(obj.board.property == property) = true;
            obj.board.owner(obj.board.property == property) = player;
            % Increment net worth by the mortgage value
            [obj, ~] = obj.changeNetWorth(player, property.mortgageValue, Resource.netWorth);
            [obj, ~] = obj.changeNetWorth(0, -property.mortgageValue, Resource.netWorth);
        end

        % Buy a house/hotel
        function [obj, isError] = buyHouse(obj, property)
            % If the current player does not have all three properties in
            % the set, return an error
            temp = obj.board.owner(obj.board.set == obj.board.set(property.index));
            if ~all(temp == obj.current); isError = true; return; end
            % If the property's buildings are maxed out, return an error
            if obj.board.numHouses(obj.board.property == property) > 5
                isError = true; return
            end
            % Buy the house; if player doesn't have cash, return an error
            % and don't complete the transaction
            price = property.housePrice;
            [obj, isError] = obj.payCash(price, obj.current, Transaction.cashPlayerToBank);
            if isError; return; end
            obj.board.numHouses(obj.board.property == property) = ...
                obj.board.numHouses(obj.board.property == property) + 1;
            % Add half the house value to net worth
            [obj, ~] = obj.changeNetWorth(obj.current, price/2, Resource.netWorth);
        end

        % Swap properties between players
        function [obj, isError] = swapProperties(obj, fromPlayer, toPlayer, property1, property2)
            % If player 1/2 does not have the property to trade (without
            % houses, unmortgaged), return an error
            isError = false;
            if obj.board.owner(obj.board.property == property1) ~= fromPlayer || ...
                    obj.board.owner(obj.board.property == property2) ~= toPlayer || ...
                    obj.board.numHouses(obj.board.property == property1) ~= 0 || ...
                    obj.board.numHouses(obj.board.property == property2) ~= 0 || ...
                    obj.board.isMortgaged(obj.board.property == property1) || ...
                    obj.board.isMortgaged(obj.board.property == property2)
                isError = true; return
            end
            % Swap the properties and adjust net worth accordingly
            obj.board.owner(obj.board.property == property1) = toPlayer;
            obj.board.owner(obj.board.property == property2) = fromPlayer;
            propertyValue1 = property1.mortgageValue;
            propertyValue2 = property2.mortgageValue;
            [obj, ~] = obj.changeNetWorth(toPlayer, propertyValue1 - propertyValue2, Resource.netWorth);
            [obj, ~] = obj.changeNetWorth(fromPlayer, propertyValue2 - propertyValue1, Resource.netWorth);
        end

        % Mortgage a property
        function [obj, isError] = mortgage(obj, property)
            % If the property is mortgaged or has houses, return an error
            isError = false;
            if obj.board.isMortgaged(obj.board.property == property) || ...
                    obj.board.numHouses(obj.board.property == property) > 0
                isError = true; return
            end
            % Mortgage the property and decrement net worth
            obj.board.isMortgaged(obj.board.property == property) = true;
            price = property.mortgageValue;
            [obj, ~] = obj.payCash(price, obj.current, Transaction.cashBankToPlayer);
            [obj, ~] = obj.changeNetWorth(obj.current, -price, Resource.netWorth);
        end

        % Unmortgage a property
        function [obj, isError] = unmortgage(obj, property)
            % If the property is not mortgaged, return an error
            if ~obj.board.isMortgaged(obj.board.property == property)
                isError = true; return
            end
            % Unmortgage the property if possible; else, return an error
            price = property.mortgageValue*1.1;
            [obj, isError] = obj.payCash(price, obj.current, Transaction.cashPlayerToBank);
            if isError; return; end
            obj.board.isMortgaged(obj.board.property == property) = false;
            % Increment net worth by mortgage price
            [obj, ~] = obj.changeNetWorth(obj.current, property.mortgageValue, Resource.netWorth);
        end

        % Sell house back to bank
        function [obj, isError] = sellHouse(obj, property)
            % Return an error if there are no houses to return
            isError = false;
            if obj.board.numHouses(obj.board.property == property) == 0
                isError = true; return
            end
            % Obtain house price
            price = property.housePrice/2;
            % Collect price from bank and decrement net worth
            [obj, ~] = obj.payCash(price, obj.current, Transaction.cashBankToPlayer);
            [obj, ~] = obj.changeNetWorth(obj.current, -price, Resource.netWorth);
            % Return house to bank
            obj.board.numHouses(obj.board.property == property) = ...
                obj.board.numHouses(obj.board.property == property) - 1;
        end

        % Calculate player debt
        function [debt, isBankrupt] = calculateDebt(obj, player, amount)
            debt = min(0, obj.assets.("P" + string(player))(obj.assets.asset == Resource.cash) - amount);
            debt = debt*-1;
            if amount > obj.assets.("P" + string(player))(obj.assets.asset == Resource.netWorth)
                isBankrupt = true;
            else
                isBankrupt = false;
            end
        end

        % Compute target values based on board state, for given player
        function result = target(obj, player)

            % Target computed as player's net worth - average net worth
            netWorth = zeros(obj.numPlayers, 1);
            for i = 1:obj.numPlayers
                if obj.isBankrupt(i)
                    netWorth(i) = 0;
                else
                    netWorth(i) = obj.assets.("P" + string(i))(obj.assets.asset == Resource.netWorth);
                end
            end
            
            result = obj.assets.("P" + string(player))(obj.assets.asset == ...
                Resource.netWorth) - mean(netWorth);

        end

        % Compress board into state vector
        state = getState(obj, varargin)

    end

    % Static methods
    methods (Static)

        % Roll dice
        function [result, isDouble] = roll()
            A = randi([1,6]); B = randi([1,6]); result = A + B;
            if A == B; isDouble = true; else; isDouble = false; end
        end

        % Find nearest tile among a set of options
        function nearest = nearest(fromTile, toTile)
            distance = zeros(length(toTile), 1);
            for i = 1:length(toTile)
                if toTile(i) > fromTile
                    distance(i) = toTile(i) - fromTile;
                else
                    distance(i) = (40 - fromTile) + toTile(i);
                end
            end; [~, nearest] = min(distance);
        end

    end

end