function obj = turnManager(obj)

    % ---------------------------------------------------------------------
    % This function runs one turn of the game given a value function and
    % specified policy.
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % JAIL MANAGEMENT
    % ---------------------------------------------------------------------
    % TO DO

    % ---------------------------------------------------------------------
    % REGULAR TURN; ROLL DICE AND MOVE
    % ---------------------------------------------------------------------

    % Get 'old tile' of current player
    oldTile = obj.board.index(obj.board.players(:, obj.current) == 1);

    % Get current player
    current = "P" + string(obj.current);

    % Set debt handling flag (true = requires debt handling)
    debtHandling = false; isBankrupt = false;

    % Roll the dice
    [roll, isDouble] = obj.roll();
    
    % If a double was rolled, increment the counter; else, clear.
    if isDouble; obj.doubleCounter = obj.doubleCounter + 1; ...
    else; obj.doubleCounter = 1; end
    % If this is the third double in a row, the player goes to jail and the
    % double counter is reset
    if obj.doubleCounter == 3; [obj, newTile] = obj.toJail(obj.current); end

    % If the player did has not rolled three doubles, move the token and
    % collect 200 if passed Go
    if obj.doubleCounter < 3; [obj, newTile] = obj.moveToken(roll, true, true); end

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
                idx = randi([1, len]); card = m(idx);
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
                    while ~isError
                        if counter ~= obj.current
                            [obj, isError] = obj.payCash(Chance.electedChairman.idx, ...
                                obj.current, Transaction.cashPlayerToPlayer, counter);
                            if ~isError; counter = counter + 1; end
                        else; counter = counter + 1;
                        end
                    end

                    % Proceed to debt handling if necessary
                    if isError; debtHandling = true; [debt, isBankrupt] = ...
                            obj.calculateDebt(obj.current, Chance.electedChairman.idx); end

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
                    if isError; debtHandling = true; [debt, isBankrupt] = ...
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
                    if isError; debtHandling = true; [debt, isBankrupt] = ...
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
                    idx = randi([1, len]); card = m(idx);
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
                            if i ~= obj.current
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
                        if isError; debtHandling = true; [debt, isBankrupt] = ...
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
                        if isError; debtHandling = true; [debt, isBankrupt] = ...
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
                            if i ~= obj.current
                                [obj, ~] = obj.payCash(CommunityChest.operaNight.idx, ...
                                    i, Transaction.cashPlayerToPlayer, obj.current);
                            end
                        end

                    case CommunityChest.schoolFees

                        % Pay bank 150
                        [obj, isError] = obj.payCash(CommunityChest.schoolFees.idx, ...
                            obj.current, Transaction.cashPlayerToBank);
                        % Proceed to debt handling if necessary
                        if isError; debtHandling = true; [debt, isBankrupt] = ...
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
                        if isError; debtHandling = true; [debt, isBankrupt] = ...
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
                if isError; debtHandling = true; [debt, isBankrupt] = ...
                    obj.calculateDebt(obj.current, owed); end

            case Tiles.luxuryTax

                % Pay the luxury tax of 75
                [obj, isError] = obj.payCash(75, obj.current, Transaction.cashPlayerToBank);
                % Proceed to debt handling if necessary
                if isError; debtHandling = true; [debt, isBankrupt] = ...
                    obj.calculateDebt(obj.current, 75); end

        end

    end

    % ---------------------------------------------------------------------
    % IF THE PLAYER LANDS ON A PROPERTY
    % ---------------------------------------------------------------------

    % Did the player land on a property?
    if obj.board.property(newTile) ~= Properties.null

        % If the property is owned by another player, pay what is owed
        if obj.board.isOwned(newTile) && obj.board.owner ~= obj.current

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
                if obj.board.numHouses > 0
                    owed = obj.board.property(newTile).rent(obj.board.numHouses + 1);

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
            [obj, isError] = payCash(owed, obj.current, Transaction.cashPlayerToPlayer, owner);
            % Proceed to debt handling if necessary
            if isError; debtHandling = true; [debt, isBankrupt] = ...
                    obj.calculateDebt(obj.current, owed); end

        end

        % If the property is not owned, either buy it or auction it
        if ~obj.board.isOwned(newTile)
            % TO DO
        end

    end

    % ---------------------------------------------------------------------
    % DEBT HANDLING (mortgage properties or sell houses)
    % ---------------------------------------------------------------------
    % If bankrupt, end game for player

    % ---------------------------------------------------------------------
    % TRADE PROPERTIES
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % BUILDING HOUSES
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % HOUSEKEEPING
    % ---------------------------------------------------------------------

    % Increment the turn counter. If the roll was double, do not move on to
    % the next player.
    obj.turn = obj.turn + 1;
    if ~isDouble; obj.current = mod(obj.current+1, obj.numPlayers); end

end