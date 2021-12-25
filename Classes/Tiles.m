classdef Tiles
    
    % Enumeration of non-property tiles

    properties
        index           % Location of tile
        action  Action  % Action to perform on tile
        idx             % Relevant unit for action
    end

    methods
        function T = Tiles(index, action, idx)
            T.index = index; T.action = action; T.idx = idx;
        end
    end

    enumeration
        incomeTax       (5, Action.payBank, 75)
        chance          ([8, 23, 37], Action.drawChance, 1)
        communityChest  ([3, 18, 34], Action.drawCommunityChest, 1)
        luxuryTax       (39, Action.payBank, 200)
        parking         (21, Action.none, 0)
        goToJail        (31, Action.moveTo, Tiles.jail)
        jail            (11, Action.none, 0)
        go              (1, Action.collectFromBank, 200)
        null            (0, Action.none, 0)
    end

end