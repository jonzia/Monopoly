classdef Chance

    % Structure defining function of chance cards

    properties
        action  Action  % Action type to be performed
        idx             % Auxillary data
    end

    methods
        function C = Chance(action, idx)
            C.action = action; C.idx = idx;
        end
    end

    enumeration
        advanceToGo         (Action.moveTo, Tiles.go.index)
        advanceToIllinois   (Action.moveTo, Properties.Illinois.index)
        advanceToStCharles  (Action.moveTo, Properties.StCharles.index)
        advanceToUtility    (Action.moveTo, [Properties.Electric.index, Properties.Water.index])
        advanceToRailroad   (Action.moveTo, [Properties.ReadingRR.index, ...
            Properties.PennsylvaniaRR.index, Properties.BandORR.index, Properties.ShortLineRR.index])
        bankPays50          (Action.collectFromBank, 50)
        getOutOfJailFree    (Action.none, 0)
        goBack3             (Action.moveTo, -3)
        goToJail            (Action.goToJail, 0)
        generalRepairs      (Action.payBank, [25, 100])
        poorTax             (Action.payBank, 15)
        advanceToReading    (Action.moveTo, Properties.ReadingRR.index)
        advanceToBoardwalk  (Action.moveTo, Properties.Boardwalk.index)
        electedChairman     (Action.payPlayer, 50)
        loanMatures         (Action.collectFromBank, 150)
    end

end