classdef Action
    % Action types
    enumeration
        payBank, payPlayer, collectFromBank, collectFromPlayers, trade, ...
            moveTo, build, demolish, mortgage, drawChance, drawCommunityChest, ...
            buy, auction, goToJail, none
    end
end