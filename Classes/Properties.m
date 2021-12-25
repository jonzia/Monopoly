classdef Properties
    % Enumeration of properties
    
    properties
        index = 0               % Location of property
        purchasePrice = 0       % Price to purchase property
        housePrice = 0          % Price to buy house (if applicable)
        rent = zeros(6, 1)      % Rent [base, 1 house, ...] (if applicable)
        mortgageValue = 0       % Mortgage value of property
        isRailroad = false      % Is this a railroad?
        isUtility = false       % Is this a utility?
    end
    
    methods
        function P = Properties(index, purchasePrice, housePrice, rent, ...
                mortgageValue, isRailroad, isUtility)
            P.index = index;
            P.purchasePrice = purchasePrice;
            P.housePrice = housePrice;
            P.rent = rent;
            P.mortgageValue = mortgageValue;
            P.isRailroad = isRailroad;
            P.isUtility = isUtility;
        end
    end
    enumeration
        Mediterranean   (2, 60, 50, [2, 10, 30, 90, 160, 250], 30, false, false)
        Baltic          (4, 60, 50, [4, 20, 60, 180, 320, 450], 30, false, false)
        ReadingRR       (6, 200, nan, [25, 50, 100, 200, nan, nan], 100, true, false)
        Oriental        (7, 100, 50, [6, 30, 90, 270, 400, 550], 50, false, false)
        Vermont         (9, 100, 50, [6, 30, 90, 270, 400, 550], 50, false, false)
        Connecticut     (10, 120, 50, [8, 40, 100, 300, 450, 600], 60, false, false)
        StCharles       (12, 140, 100, [10, 50, 150, 450, 625, 750], 70, false, false)
        Electric        (13, 150, nan, [4, 10, nan, nan, nan, nan], 75, false, true)
        States          (14, 140, 100, [10, 50, 150, 450, 625, 750], 70, false, false)
        Virginia        (15, 160, 100, [12, 60, 180, 500, 700, 900], 80, false, false)
        PennsylvaniaRR  (16, 200, nan, [25, 50, 100, 200, nan, nan], 100, true, false)
        StJames         (17, 180, 100, [14, 70, 200, 550, 750, 950], 90, false, false)
        Tennessee       (19, 180, 100, [14, 70, 200, 550, 750, 950], 90, false, false)
        NewYork         (10, 200, 100, [16, 80, 220, 600, 800, 1000], 100, false, false)
        Kentucky        (22, 220, 150, [18, 90, 250, 700, 875, 1050], 110, false, false)
        Indiana         (24, 220, 150, [18, 90, 250, 700, 875, 1050], 110, false, false)
        Illinois        (25, 240, 150, [20, 100, 300, 750, 925, 1100], 120, false, false)
        BandORR         (26, 200, nan, [25, 50, 100, 200, nan, nan], 100, true, false)
        Atlantic        (27, 260, 150, [22, 110, 330, 800, 975, 1150], 130, false, false)
        Ventnor         (28, 260, 150, [22, 110, 330, 800, 975, 1150], 130, false, false)
        Water           (29, 150, nan, [4, 10, nan, nan, nan, nan], 75, false, true)
        MarvinGardens   (30, 280, 150, [24, 120, 360, 850, 1025, 1200], 140, false, false)
        Pacific         (32, 300, 200, [26, 130, 390, 900, 1100, 1275], 150, false, false)
        NorthCarolina   (33, 300, 200, [26, 130, 390, 900, 1100, 1275], 150, false, false)
        Pennsylvania    (35, 320, 200, [28, 150, 450, 1000, 1200, 1400], 160, false, false)
        ShortLineRR     (36, 200, nan, [25, 50, 100, 200, nan, nan], 100, true, false)
        ParkPlace       (38, 350, 200, [35, 175, 500, 1100, 1300, 1500], 175, false, false)
        Boardwalk       (40, 400, 200, [50, 200, 600, 1400, 1700, 2000], 200, false, false)
        null            (0, 0, 0, [0 0 0 0 0 0], 0, false, false)
    end
end

