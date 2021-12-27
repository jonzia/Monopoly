function obj = turnManager(obj, model, epsilon)

    % ---------------------------------------------------------------------
    % This function runs one turn of the game given a value function and
    % specified policy.
    % ---------------------------------------------------------------------

    % If the player is bankrupt, increment the turn counter and return
    if obj.isBankrupt(obj.current)
        obj.current = mod(obj.current+1, obj.numPlayers);
        if obj.current == 0; obj.current = obj.numPlayers; end
        return
    end

    % Get current player
    current = "P" + string(obj.current);

    % Set debt handling flag (true = requires debt handling)
    debtHandling = false; isBankrupt = false;

    % ---------------------------------------------------------------------
    % JAIL MANAGEMENT
    % ---------------------------------------------------------------------
    
    % If the player is jailed, decide whether to pay 50/GOJFC now or roll
    % If player pays 50/GOJFC, release from jail and proceed
    if obj.isJailed(obj.current)
        % GOJFC
        usedGOJFC = false;
        if obj.assets.(current)(obj.assets.asset == Resource.getOutOfJail) > 0
            newObj = obj;
            newObj.assets.(current)(obj.assets.asset == Resource.getOutOfJail) = ...
                newObj.assets.(current)(obj.assets.asset == Resource.getOutOfJail) - 1;
            newObj.assets.bank(obj.assets.asset == Resource.getOutOfJail) = ...
                newObj.assets.bank(obj.assets.asset == Resource.getOutOfJail) + 1;
            newObj.isJailed(obj.current) = false; newObj.jailCounter(obj.current) = 0;
            selection = game.policy(newObj.getState(), model, 'epsilon', epsilon, 'baseline', obj.getState());
            if selection == 1; usedGOJFC = true; obj = newObj; end
            % Pay 50
        end
        if obj.assets.(current)(obj.assets.asset == Resource.cash) >= 50 && ...
                ~usedGOJFC
            newObj = obj;
            [newObj, ~] = newObj.payCash(50, obj.current, Transaction.cashPlayerToBank);
            newObj.isJailed(obj.current) = false; newObj.jailCounter(obj.current) = 0;
            selection = game.policy(newObj.getState(), 'epsilon', epsilon, 'baseline', model, obj.getState());
            if selection == 1; obj = newObj; end
        end
    end

    % ---------------------------------------------------------------------
    % REGULAR TURN; ROLL DICE AND MOVE
    % ---------------------------------------------------------------------

    % Get 'old tile' of current player
    oldTile = obj.board.index(obj.board.players(:, obj.current) == 1);

    % Roll the dice
    [roll, isDouble] = obj.roll();
    
    % If a double was rolled, increment the counter; else, clear.
    if isDouble; obj.doubleCounter = obj.doubleCounter + 1; ...
    else; obj.doubleCounter = 0; end
    % If this is the third double in a row, the player goes to jail and the
    % double counter is reset
    if obj.doubleCounter == 3; [obj, newTile] = obj.toJail(obj.current); end

    % If the player has not rolled three doubles and is not jailed, move 
    % the token and collect 200 if passed Go
    if obj.doubleCounter < 3 && ~obj.isJailed(obj.current); ...
        [obj, newTile] = obj.moveToken(roll, true, true); end

    % If the player is jailed and did not roll a double, increment the jail
    % counter. If they have rolled three times, pay 50 or play GOJFC and
    % release from jail but stay in just visiting. Note that if they have
    % debt, pay all available cash to bank and reconcile debt in debt
    % handling.
    % First, if the player was jailed but rolled a double, release and move
    % tile without paying.
    if obj.isJailed(obj.current) && isDouble
        obj.isJailed(obj.current) = false; obj.jailCounter(obj.current) = 0;
        [obj, newTile] = obj.moveToken(roll, true, true);
        % Otherwise, if they're jailed and did not roll a double,
        % increment the jail counter
    elseif obj.isJailed(obj.current) && ~isDouble
        obj.jailCounter(obj.current) = obj.jailCounter(obj.current) + 1;
    end
    % If they have had three rolls in jail without a double, they have to
    % pay 50 or present a card.
    if obj.isJailed(obj.current) && obj.jailCounter(obj.current) == 3
        % First, if they have a card, use it and release them without
        % moving.
        if obj.assets.(current)(obj.assets.asset == Resource.getOutOfJail) > 0
            obj.assets.(current)(obj.assets.asset == Resource.getOutOfJail) = ...
                obj.assets.(current)(obj.assets.asset == Resource.getOutOfJail) - 1;
            obj.assets.bank(obj.assets.asset == Resource.getOutOfJail) = ...
                obj.assets.bank(obj.assets.asset == Resource.getOutOfJail) + 1;
            obj.isJailed(obj.current) = false; obj.jailCounter(obj.current) = 0;
            % Else, if they have 50, pay it and release them without moving
        elseif obj.assets.(current)(obj.assets.asset == Resource.cash) >= 50
            [obj, ~] = obj.payCash(50, obj.current, Transaction.cashPlayerToBank);
            obj.isJailed(obj.current) = false; obj.jailCounter(obj.current) = 0;
        else
            % Player does not have resources to get out of jail; if they do
            % not have a net worth of 50, go bankrupt. Else, release from
            % jail and proceed to debt collection.
            debtHandling = true; oweTo = 0;
            [debt, isBankrupt] = obj.calculateDebt(obj.current, 50);
            if ~isBankrupt; obj.isJailed(obj.current) = false; ...
                    obj.jailCounter(obj.current) = 0; end
        end
    end

    % ---------------------------------------------------------------------
    % IF THE PLAYER LANDS ON A NON-PROPERTY TILE
    % ---------------------------------------------------------------------

    if obj.board.tile(newTile) ~= Tiles.null

        % Note: Chance precedes switch statement because player can move
        % from chance to CC or luxury tax. The non-property tiles precede
        % property tiles because player can move from CC/Chance to property
        % tile.
        if obj.board.tile(newTile) == Tiles.chance

            % Draw a chance card
            loop = true;
            while loop
                c = enumeration('Chance'); len = length(c);
                idx = randi([1, len]); card = c(idx);
                % Can't issue GOJFC if there are none left
                loop = false;
                if card == Chance.getOutOfJailFree && ...
                        obj.assets.bank(obj.assets.asset == Resource.getOutOfJail) == 0
                    loop = true;
                end
            end

            switch card

                case Chance.advanceToBoardwalk

                    % Advance to Boardwalk
                    [obj, newTile] = obj.moveToken(Chance.advanceToBoardwalk.idx, false, true);

                case Chance.advanceToGo

                    % Advance to Go and collect 200
                    [obj, newTile] = obj.moveToken(Chance.advanceToGo.idx, false, true);

                case Chance.advanceToIllinois

                    % Advance to Illinois and collect 200 if pass Go
                    [obj, newTile] = obj.moveToken(Chance.advanceToIllinois.idx, false, true);

                case Chance.advanceToRailroad

                    % Find nearest railroad
                    newTile = obj.nearest(oldTile, Chance.advanceToRailroad.idx);

                    % Advance to railroad and collect 200 if pass Go
                    [obj, newTile] = obj.moveToken(newTile, false, true);

                case Chance.advanceToReading

                    % Advance to Reading RR and collect 200 if pass Go
                    [obj, newTile] = obj.moveToken(Chance.advanceToReading.idx, false, true);

                case Chance.advanceToStCharles

                    % Advance to St. Charles and collect 200 if pass Go
                    [obj, newTile] = obj.moveToken(Chance.advanceToStCharles.idx, false, true);

                case Chance.advanceToUtility

                    % Find nearest utility
                    nearest = obj.nearest(oldTile, Chance.advanceToUtility.idx);

                    % Advannce to nearest utility and collect 200 if
                    % pass Go
                    [obj, newTile] = obj.moveToken(nearest, false, true);

                case Chance.bankPays50

                    % Collect 50 from bank
                    [obj, ~] = obj.payCash(Chance.bankPays50.idx, ...
                        obj.current, Transaction.cashBankToPlayer);

                case Chance.electedChairman

                    % Pay each player 50, if able
                    isError = false; counter = 1;
                    while ~isError && counter <= obj.numPlayers
                        if counter ~= obj.current && ~obj.isBankrupt(counter)
                            [obj, isError] = obj.payCash(Chance.electedChairman.idx, ...
                                obj.current, Transaction.cashPlayerToPlayer, counter);
                            if ~isError; counter = counter + 1; end
                        else; counter = counter + 1;
                        end
                    end

                    % Proceed to debt handling if necessary
%                     if isError; debtHandling = true; [debt, isBankrupt] = ...
%                             obj.calculateDebt(obj.current, Chance.electedChairman.idx); end

                case Chance.generalRepairs

                    % Get number of houses and hotels
                    houses = obj.board.numHouses(obj.board.owner == obj.current);
                    numHouses = 0; numHotels = 0;
                    for i = 1:length(houses)
                        if houses(i) < 5
                            numHouses = numHouses + houses(i);
                        elseif houses(i) == 5
                            numHotels = numHotels + 1;
                        end
                    end

                    % Calculate amount owed and pay bank
                    owed = numHouses*Chance.generalRepairs.idx(1) + ...
                        numHotels*Chance.generalRepairs.idx(2);
                    [obj, isError] = obj.payCash(owed, obj.current, ...
                        Transaction.cashPlayerToBank);

                    % Proceed to debt handling if necessary
                    if isError; debtHandling = true; oweTo = 0; [debt, isBankrupt] = ...
                            obj.calculateDebt(obj.current, owed); end

                case Chance.getOutOfJailFree

                    % Obtain GOJFC (already verified availability)
                    obj.assets.bank(obj.assets.asset == Resource.getOutOfJail) = ...
                        obj.assets.bank(obj.assets.asset == Resource.getOutOfJail) - 1;
                    obj.assets.(current)(obj.assets.asset == Resource.getOutOfJail) = ...
                        obj.assets.(current)(obj.assets.asset == Resource.getOutOfJail) + 1;

                case Chance.goBack3

                    % Go back three spaces
                    newTile = oldTile + Chance.goBack3.idx;
                    if newTile < 0; newTile = newTile + 40; end
                    [obj, newTile] = obj.moveToken(newTile, false, false);

                    % NOTE: COULD LAND ON CC OR LUXURY TAX

                case Chance.goToJail

                    % Move to jail, otherwise turn is over besides trading
                    % and modifying assets
                    [obj, newTile] = obj.toJail(obj.current);

                case Chance.loanMatures

                    % Collect 150 from bank
                    [obj, ~] = obj.payCash(Chance.loanMatures.idx, obj.current, ...
                        Transaction.cashBankToPlayer);

                case Chance.poorTax

                    % Pay poor tax of 15
                    [obj, isError] = obj.payCash(Chance.poorTax.idx, obj.current, ...
                        Transaction.cashPlayerToBank);
                    % Proceed to debt handling if necessary
                    if isError; debtHandling = true; oweTo = 0; [debt, isBankrupt] = ...
                            obj.calculateDebt(obj.current, Chance.poorTax.idx); end

            end

        end

        % Now, see if the player was either on another tile, or moved from
        % Chance to CC.
        switch obj.board.tile(newTile)

            case Tiles.communityChest

                % Draw a CC card
                loop = true;
                while loop
                    c = enumeration('CommunityChest'); len = length(c);
                    idx = randi([1, len]); card = c(idx);
                    % Can't issue GOJFC if there are none left
                    loop = false;
                    if card == CommunityChest.getOutOfJailFree && ...
                            obj.assets.bank(obj.assets.asset == Resource.getOutOfJail) == 0
                        loop = true;
                    end
                end

                switch card

                    case CommunityChest.advanceToGo

                        % Advance to Go and collect 200
                        [obj, newTile] = obj.moveToken(Tiles.go.index, false, true);

                    case CommunityChest.bankError

                        % Collect 200 from bank
                        [obj, ~] = obj.payCash(CommunityChest.bankError.idx, ...
                            obj.current, Transaction.cashBankToPlayer);

                    case CommunityChest.beautyContest

                        % Collect 10 from bank
                        [obj, ~] = obj.payCash(CommunityChest.beautyContest.idx, ...
                            obj.current, Transaction.cashBankToPlayer);

                    case CommunityChest.birthday

                        % Collect 10 from each player
                        for i = 1:obj.numPlayers
                            if i ~= obj.current && ~obj.isBankrupt(i)
                                [obj, ~] = obj.payCash(CommunityChest.birthday.idx, ...
                                    i, Transaction.cashPlayerToPlayer, obj.current);
                            end
                        end

                    case CommunityChest.christmasFund

                        % Collect 100 from bank
                        [obj, ~] = obj.payCash(CommunityChest.christmasFund.idx, ...
                            obj.current, Transaction.cashBankToPlayer);

                    case CommunityChest.doctorsFees

                        % Pay bank 50
                        [obj, isError] = obj.payCash(CommunityChest.doctorsFees.idx, ...
                            obj.current, Transaction.cashPlayerToBank);
                        % Proceed to debt handling if necessary
                        if isError; debtHandling = true; oweTo = 0; [debt, isBankrupt] = ...
                            obj.calculateDebt(obj.current, CommunityChest.doctorsFees.idx); end

                    case CommunityChest.feeForServices

                        % Collect 25 from bank
                        [obj, ~] = obj.payCash(CommunityChest.feeForServices.idx, ...
                            obj.current, Transaction.cashBankToPlayer);

                    case CommunityChest.getOutOfJailFree

                        % Obtain GOJFC (already verified availability)
                        obj.assets.bank(obj.assets.asset == Resource.getOutOfJail) = ...
                            obj.assets.bank(obj.assets.asset == Resource.getOutOfJail) - 1;
                        obj.assets.(current)(obj.assets.asset == Resource.getOutOfJail) = ...
                            obj.assets.(current)(obj.assets.asset == Resource.getOutOfJail) + 1;

                    case CommunityChest.goToJail

                        % Go to jail
                        [obj, newTile] = obj.toJail(obj.current);

                    case CommunityChest.hospitalFees

                        % Pay bank 100
                        [obj, isError] = obj.payCash(CommunityChest.feeForServices.idx, ...
                            obj.current, Transaction.cashPlayerToBank);
                        % Proceed to debt handling if necessary
                        if isError; debtHandling = true; oweTo = 0; [debt, isBankrupt] = ...
                            obj.calculateDebt(obj.current, CommunityChest.feeForServices.idx); end

                    case CommunityChest.incomeTaxRefund

                        % Collect 20 from bank
                        [obj, ~] = obj.payCash(CommunityChest.incomeTaxRefund.idx, ...
                            obj.current, Transaction.cashBankToPlayer);

                    case CommunityChest.inherit

                        % Collect 100 from bank
                        [obj, ~] = obj.payCash(CommunityChest.inherit.idx, ...
                            obj.current, Transaction.cashBankToPlayer);

                    case CommunityChest.lifeInsurance

                        % Collect 100 from bank
                        [obj, ~] = obj.payCash(CommunityChest.lifeInsurance.idx, ...
                            obj.current, Transaction.cashBankToPlayer);

                    case CommunityChest.operaNight

                        % Collect 50 from each player
                        for i = 1:obj.numPlayers
                            if i ~= obj.current && ~obj.isBankrupt(i)
                                [obj, ~] = obj.payCash(CommunityChest.operaNight.idx, ...
                                    i, Transaction.cashPlayerToPlayer, obj.current);
                            end
                        end

                    case CommunityChest.schoolFees

                        % Pay bank 150
                        [obj, isError] = obj.payCash(CommunityChest.schoolFees.idx, ...
                            obj.current, Transaction.cashPlayerToBank);
                        % Proceed to debt handling if necessary
                        if isError; debtHandling = true; oweTo = 0; [debt, isBankrupt] = ...
                            obj.calculateDebt(obj.current, CommunityChest.schoolFees.idx); end

                    case CommunityChest.stockSale

                        % Collect 50 from bank
                        [obj, ~] = obj.payCash(CommunityChest.stockSale.idx, ...
                            obj.current, Transaction.cashBankToPlayer);

                    case CommunityChest.streetRepairs

                        % Get number of houses and hotels
                        houses = obj.board.numHouses(obj.board.owner == obj.current);
                        numHouses = 0; numHotels = 0;
                        for i = 1:length(houses)
                            if houses(i) < 5
                                numHouses = numHouses + houses(i);
                            elseif houses(i) == 5
                                numHotels = numHotels + 1;
                            end
                        end

                        % Calculate amount owed and pay bank
                        owed = numHouses*CommunityChest.streetRepairs.idx(1) + ...
                            numHotels*CommunityChest.streetRepairs.idx(2);
                        [obj, isError] = obj.payCash(owed, obj.current, ...
                            Transaction.cashPlayerToBank);

                        % Proceed to debt handling if necessary
                        if isError; debtHandling = true; oweTo = 0; [debt, isBankrupt] = ...
                            obj.calculateDebt(obj.current, owed); end

                end

            case Tiles.go
                % Collect 200 from the bank
                [obj, ~] = obj.payCash(200, obj.current, Transaction.cashBankToPlayer);
            case Tiles.goToJail
                % Move to jail (do not pass Go)
                obj = obj.toJail(obj.current);
            case Tiles.incomeTax

                % Pay the minimum of 200 or 10%
                owed = min(200, ...
                    obj.assets.(current)(obj.assets.asset == Resource.netWorth)*0.1);
                [obj, isError] = obj.payCash(owed, obj.current, Transaction.cashPlayerToBank);
                % Proceed to debt handling if necessary
                if isError; debtHandling = true; oweTo = 0; [debt, isBankrupt] = ...
                    obj.calculateDebt(obj.current, owed); end

            case Tiles.luxuryTax

                % Pay the luxury tax of 75
                [obj, isError] = obj.payCash(75, obj.current, Transaction.cashPlayerToBank);
                % Proceed to debt handling if necessary
                if isError; debtHandling = true; oweTo = 0; [debt, isBankrupt] = ...
                    obj.calculateDebt(obj.current, 75); end

        end

    end

    % ---------------------------------------------------------------------
    % IF THE PLAYER LANDS ON A PROPERTY
    % ---------------------------------------------------------------------

    % Did the player land on a property?
    if obj.board.property(newTile) ~= Properties.null

        % If the property is owned by another player, pay what is owed
        if obj.board.isOwned(newTile) && obj.board.owner(newTile) ~= obj.current

            % Get the owner
            owner = obj.board.owner(newTile);

            % If the property is mortgaged, nothing is owed
            if obj.board.isMortgaged
                owed = 0;

                % Else, if it is a utility...
            elseif obj.board.property(newTile).isUtility

                % If the opponent owns both utilities, pay 10x roll
                if obj.board.owner(Properties.Electric.index) == ...
                        obj.board.owner(Properties.Water.index)
                    owed = 10*roll;
                else
                    % Else, pay 4x roll
                    owed = 4*roll;
                end

                % Else, if it is a railroad...
            elseif obj.board.property(newTile).isRailroad

                % How many railroads does the player own?
                temp = 0;
                if obj.board.owner(Properties.ReadingRR.index) == owner; temp = temp + 1; end
                if obj.board.owner(Properties.PennsylvaniaRR.index) == owner; temp = temp + 1; end
                if obj.board.owner(Properties.BandORR.index) == owner; temp = temp + 1; end
                if obj.board.owner(Properties.ShortLineRR.index) == owner; temp = temp + 1; end

                % Determine proper rent
                switch temp
                    case 1; owed = 25;
                    case 2; owed = 50;
                    case 3; owed = 100;
                    case 4; owed = 200;
                end

            else
                % If there are houses on the property, pay accordingly
                if obj.board.numHouses(newTile) > 0
                    owed = obj.board.property(newTile).rent(obj.board.numHouses(newTile) + 1);

                else

                    % Else, pay standard rent
                    owed = obj.board.property(newTile).rent(1);

                    % If all 2/3 properties are owned by the same player,
                    % pay double rent
                    temp = obj.board.owner(obj.board.set == obj.board.set(newTile));
                    if all(temp == owner); owed = owed*2; end

                end
            end

            % Pay the player. If there is an error, proceed to debt handling.
            [obj, isError] = obj.payCash(owed, obj.current, Transaction.cashPlayerToPlayer, owner);
            % Proceed to debt handling if necessary
            if isError; debtHandling = true; oweTo = owner; [debt, isBankrupt] = ...
                    obj.calculateDebt(obj.current, owed); end

        end

        % If the property is not owned, either buy it or auction it
        if ~obj.board.isOwned(newTile)

            auctionFLAG = false; P = obj.board.property(newTile);
            % First, decide whether to buy it, if player has cash
            if obj.assets.(current)(obj.assets.asset == Resource.cash) > ...
                    obj.board.property(newTile).purchasePrice
                % Run the scenario where the property is purchased
                [newObj, ~] = obj.buyProperty(P, obj.current);
                % Get the state vectors and make a selection
                selection = game.policy(newObj.getState(), model, 'epsilon', epsilon, 'baseline', obj.getState());
                % Auction the property if it is not purchased
                if selection == 1; obj = newObj; else; auctionFLAG = true; end

            end

            % Auction the property
            if auctionFLAG

                % The bidding is performed by starting at $10 and
                % increasing in $10 increments, passing the bid to each
                % player in sequence. If a player is unwilling to up the
                % bid, they are removed from the auction until only one
                % player remains.
                isBidding = ones(obj.numPlayers, 1); counter = obj.current;
                for i = 1:obj.numPlayers; if obj.isBankrupt(i); isBidding(i) = 0; end; end
                % Set starting bid
                bid = min(10, obj.assets.(current)(obj.assets.asset == Resource.cash));
                while sum(isBidding) > 1
                    % Skip iteration if player has passed
                    player = mod(counter, obj.numPlayers); if player == 0; player = obj.numPlayers; end
                    if ~isBidding(player); counter = counter + 1; continue; end
                    % For the current player, is the bid greater than cash?
                    if bid > obj.assets.("P" + string(player))(obj.assets.asset == Resource.cash)
                        isBidding(player) = 0;
                    else
                        % If not, do they want to make the offer?
                        [newObj, ~] = obj.buyProperty(P, player, bid);
                        selection = game.policy(newObj.getState(player), model, 'epsilon', epsilon, 'baseline', obj.getState(player));
                        if selection == 0
                            % If they don't want to make an offer, pass
                            isBidding(player) = 0;
                        else
                            % Else, up the bid by 10
                            bid = bid + 10;
                        end
                    end

                    % Increment the counter
                    counter = counter + 1;

                end; finalBid = bid - 10;

                % The last player who was bidding gets the property for the
                % bid price
                [~, player] = max(isBidding); [obj, ~] = obj.buyProperty(P, player, finalBid);

            end

        end

    end

    % ---------------------------------------------------------------------
    % DEBT HANDLING (mortgage properties or sell houses)
    % ---------------------------------------------------------------------
    
    % Enter this protocol, if necessary
    if debtHandling

        % If the debt is more than net worth, the player is bankrupt. Turn
        % over all assets to the player to whom the debt is owed (or the
        % bank) and end turn.
        if isBankrupt
            obj.isBankrupt(obj.current) = true;
            % Give all assets to "oweTo" (0 = bank)
            % IN THIS GAME, ASSETS WILL GO TO PLAYER WITH HIGHEST NET WORTH
            % TO INCENTIVIZE HIGHER NET WORTH (if owe to bank)
            if oweTo == 0
                % Decide who assets will be owed to
                highestNW = 0;
                for i = 1:obj.numPlayers
                    if i == obj.current; continue; end
                    if obj.assets.("P" + string(i))(obj.assets.asset == Resource.netWorth) > highestNW
                        highestNW = obj.assets.("P" + string(i))(obj.assets.asset == Resource.netWorth);
                        oweTo = i;
                    end
                end
            end

            % Cash + GOJFC
            [obj, ~] = obj.payCash(obj.assets.(current)(obj.assets.asset == Resource.cash), ...
                obj.current, Transaction.cashPlayerToPlayer, oweTo);

            obj.assets.("P" + string(oweTo))(obj.assets.asset == Resource.getOutOfJail) = ...
                obj.assets.("P" + string(oweTo))(obj.assets.asset == Resource.getOutOfJail) + ...
                obj.assets.(current)(obj.assets.asset == Resource.getOutOfJail);
            obj.assets.(current)(obj.assets.asset == Resource.getOutOfJail) = 0;
            % Proceed to properties (increment net worth for unmortgaged
            % properties and houses)
            P = obj.board.property(obj.board.owner == obj.current);
            for i = 1:size(P, 1)
                obj.board.owner(obj.board.property == P(i)) = oweTo;
                if ~obj.board.isMortgaged(obj.board.property == P(i))
                    obj.assets.("P" + string(oweTo))(obj.assets.asset == Resource.netWorth) = ...
                        obj.assets.("P" + string(oweTo))(obj.assets.asset == Resource.netWorth) + ...
                        P(i).mortgageValue;
                    if obj.board.numHouses(obj.board.property == P(i)) > 0
                        obj.assets.("P" + string(oweTo))(obj.assets.asset == Resource.netWorth) = ...
                            obj.assets.("P" + string(oweTo))(obj.assets.asset == Resource.netWorth) + ...
                            obj.board.numHouses(obj.board.property == P(i))*(P(i).housePrice/2);
                    end
                end
            end

            % Increment the counter and return
            obj.turn = obj.turn + 1;
            obj.current = mod(obj.current+1, obj.numPlayers);
            if obj.current == 0; obj.current = obj.numPlayers; end
            return
        end

        % If the player can theoretically come up with the cash, explore
        % options and consolidate state vectors.

        % Start by setting a target value for money to raise
        target = debt - obj.assets.(current)(obj.assets.asset == Resource.cash);
        raised = 0;
        while raised < target

            % Initialize placeholder for all possible states (mortgageable
            % properties and sellable houses
            states = []; objects = []; sellPrice = [];

            % Start with morgageable properties
            P = obj.board.property(obj.board.owner == obj.current & ...
                obj.board.isMortgaged == false & obj.board.numHouses == 0, :);

            if ~isempty(P)
                for i = 1:length(P)
                    % For each property, no property in the set can have a
                    % house
                    set = obj.board.set(obj.board.property == P(i));
                    set = obj.board.numHouses(obj.board.set == set);
                    if sum(set) > 0; continue; end
                    [newObj, ~] = obj.mortgage(P(i));
                    states = [states; newObj.getState()];
                    objects = [objects; newObj];
                    sellPrice = [sellPrice; P(i).mortgageValue];
                end
            end

            % Proceed to sellable houses
            P = obj.board.property(obj.board.owner == obj.current & ...
                obj.board.numHouses > 0);
            if ~isempty(P)
                for i = 1:length(P)
                    [newObj, ~] = obj.sellHouse(P(i));
                    states = [states; newObj.getState()];
                    objects = [objects; newObj];
                    sellPrice = [sellPrice; P(i).housePrice/2];
                end
            end

            % Select a preferred state vector using policy function
            selection = game.policy(states, model, 'epsilon', epsilon);
    
            % Update the Monopoly object based on the chosen state vector
            obj = objects(selection); raised = raised + sellPrice(selection);

        end

        % Pay the debt to the other player
        [obj, ~] = obj.payCash(debt, obj.current, Transaction.cashPlayerToPlayer, oweTo);

    end

    % ---------------------------------------------------------------------
    % TRADE PROPERTIES
    % ---------------------------------------------------------------------

    % Player may propose no more than one property swap per turn. First,
    % get tradeable properties for each player. Must be owned, not
    % mortgaged, and without houses.
    toGive = obj.board(obj.board.owner == obj.current & obj.board.isMortgaged == false & ...
        obj.board.numHouses == 0, :);
    toReceive = obj.board(obj.board.isOwned == true & obj.board.owner ~= obj.current & ...
        obj.board.isMortgaged == false & obj.board.numHouses == 0, :);
    % No other properties in the set can have houses, either
    if size(toGive, 1) > 0 && size(toReceive, 1) > 0
        toGive.isTradeable = true(size(toGive, 1), 1);
        toReceive.isTradeable = true(size(toReceive, 1), 1);
        for i = 1:size(toGive, 1)
            set = toGive.set(i); set = obj.board.numHouses(obj.board.set == set, :);
            if sum(set) > 0; toGive.isTradeable(i) = false; end
        end
        for i = 1:size(toReceive, 1)
            set = toReceive.set(i); set = obj.board.numHouses(obj.board.set == set, :);
            if sum(set) > 0; toReceive.isTradeable(i) = false; end
        end
        toGive(toGive.isTradeable == false, :) = [];
        toReceive(toReceive.isTradeable == false, :) = [];
    end

    % Compute the state vector for each pair of swaps.
    if size(toGive, 1) > 0 && size(toReceive, 1) > 0
        % Set placeholder
        states = zeros(size(toGive, 1)*size(toReceive, 1), obj.stateLength); counter = 1;
        pair = zeros(size(states, 1), 2);
        for i = 1:size(toGive, 1)
            for j = 1:size(toReceive, 1)
                [newObj, ~] = obj.swapProperties(obj.current, toReceive.owner(j), ...
                    toGive.property(i), toReceive.property(j));
                states(counter, :) = newObj.getState();
                pair(counter, :) = [i j]; counter = counter + 1;
            end
        end

        % Select the preferred state vector using policy function
        selection = game.policy(states, model, 'epsilon', epsilon, 'baseline', obj.getState());
        if selection ~= 0
            i = pair(selection, 1); j = pair(selection, 2);
            [obj, ~] = obj.swapProperties(obj.current, toReceive.owner(j), toGive.property(i), ...
                toReceive.property(j));
        end

    end

    % NOTE: Forbid raising capital apropos of nothing
    while false
    % ---------------------------------------------------------------------
    % SELLING HOUSES (WHILE LOOP)
    % ---------------------------------------------------------------------
    
    while true
        % Player may sell houses on own turn. To do so, first obtain a list
        % of properties with houses.
        owned = obj.board.property(obj.board.owner == obj.current & obj.board.numHouses > 0);
        % If no properties are owned, break
        if isempty(owned); break; end

        % Build state array
        states = zeros(size(owned, 1), obj.stateLength);

        % Sell house and obtain state vector
        for i = 1:size(owned, 1)
            [newObj, ~] = obj.sellHouse(owned(i));
            states(i, :) = newObj.getState();
        end
        
        % Select the preferred state vector using the policy function
        selection = game.policy(states, model, 'epsilon', epsilon, 'baseline', obj.getState());
        if selection ~= 0
            [obj, ~] = obj.sellHouse(owned(selection));
        else
            break
        end

    end

    % ---------------------------------------------------------------------
    % MORTGAGING (WHILE LOOP)
    % ---------------------------------------------------------------------
    while true
        % Player may mortgage a property that is owned, as long as there
        % are no houses on any propeerties of the set.

        % Start with morgageable properties
        P = obj.board.property(obj.board.owner == obj.current & ...
            obj.board.isMortgaged == false & obj.board.numHouses == 0, :);
        states = [];

        if ~isempty(P)
            for i = 1:length(P)
                % For each property, no property in the set can have a
                % house
                set = obj.board.set(obj.board.property == P(i));
                set = obj.board.numHouses(obj.board.set == set);
                if sum(set) > 0; continue; end
                [newObj, ~] = obj.mortgage(P(i));
                states = [states; newObj.getState()];
            end
        else
            break
        end

        % Select the preferred state vector using the policy function
        if ~isempty(states)
            selection = game.policy(states, model, 'epsilon', epsilon, 'baseline', obj.getState());
            if selection ~= 0
                [obj, ~] = obj.mortgage(P(selection));
            else
                break
            end
        else
            break
        end

    end
    end

    % ---------------------------------------------------------------------
    % BUILDING HOUSES (WHILE LOOP)
    % ---------------------------------------------------------------------

    while true
        % Player may build houses on own turn. To do so, first obtain a list of
        % buildable properties (completed set, none mortgaged, with less than
        % hotel).
        owned = obj.board(obj.board.owner == obj.current, :);
        % If no properties are owned, break
        if size(owned, 1) == 0; break; end
        owned.isBuildable = false(size(owned, 1), 1);
        for i = 1:size(owned, 1)
            % For the set to which the property belongs, if the player owns
            % them all, it may be buildable
            set = obj.board.owner(obj.board.set == owned.set(i));
            if all(set == obj.current)
                % None of the properties can be mortgaged, and the property
                % can't have more than five houses
                set = owned.isMortgaged(owned.set == owned.set(i));
                if all(set == false) && owned.numHouses(i) < 5
                    owned.isBuildable(i) = true;
                end
            end
        end; buildable = owned(owned.isBuildable == true, :);
        if size(buildable, 1) == 0; break; end
    
        % Filter list by player's cash limitations
        for i = 1:size(buildable, 1)
            if buildable.property(i).housePrice > obj.assets.(current)(obj.assets.asset == Resource.cash)
                buildable.isBuildable(i) = false;
            end
        end; buildable = buildable(buildable.isBuildable == true, :);
        if size(buildable, 1) == 0; break; end
    
        % Compute the state vector for each property modification
        states = zeros(size(buildable, 1), obj.stateLength);
        for i = 1:size(buildable, 1)
            % Make purchase
            [newObj, ~] = obj.buyHouse(buildable.property(i));
            % Get state
            states(i, :) = newObj.getState();
        end
    
        % Select the preferred state vector using the policy function
        selection = game.policy(states, model, 'epsilon', epsilon, 'baseline', obj.getState());
        if selection ~= 0
            [obj, ~] = obj.buyHouse(buildable.property(selection));
        else
            break
        end

    end

    % ---------------------------------------------------------------------
    % HOUSEKEEPING
    % ---------------------------------------------------------------------

    % Increment the turn counter. If the roll was double, do not move on to
    % the next player.
    obj.turn = obj.turn + 1;
    if ~isDouble; obj.current = mod(obj.current+1, obj.numPlayers); end
    if obj.current == 0; obj.current = obj.numPlayers; end

end