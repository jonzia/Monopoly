classdef CommunityChest

    % Structure defining function of community chest cards

    properties
        action  Action  % Action type to be performed
        idx             % Auxillary data
    end

    methods
        function C = CommunityChest(action, idx)
            C.action = action; C.idx = idx;
        end
    end

    enumeration
        advanceToGo         (Action.moveTo, Tiles.go)
        bankError           (Action.collectFromBank, 200)
        doctorsFees         (Action.payBank, 50)
        stockSale           (Action.collectFromBank, 50)
        getOutOfJailFree    (Action.none, 0)
        goToJail            (Action.goToJail, 0)
        operaNight          (Action.collectFromPlayers, 50)
        christmasFund       (Action.collectFromBank, 100)
        incomeTaxRefund     (Action.collectFromBank, 20)
        birthday            (Action.collectFromPlayers, 10)
        lifeInsurance       (Action.collectFromBank, 100)
        hospitalFees        (Action.payBank, 100)
        schoolFees          (Action.payBank, 150)
        feeForServices      (Action.collectFromBank, 25)
        streetRepairs       (Action.payBank, [40, 115])
        beautyContest       (Action.collectFromBank, 10)
        inherit             (Action.collectFromBank, 100)
    end

end