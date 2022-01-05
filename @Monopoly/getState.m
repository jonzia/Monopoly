function state = getState(obj, varargin)

    % ---------------------------------------------------------------------
    % Compresses board configuration to state vector (table):
    % owner(1)...(n), numHouses(1)...(n) [-1 indicates mortgaged],
    % cash(1)...(m), GOJFC (1)...(m), isJailed (1)...(m),
    % isBankrupt (1)...(m), player
    % ---------------------------------------------------------------------

    player = obj.current;
    if ~isempty(varargin); player = varargin{1}; end

    % Enumerate the properties
    P = enumeration("Properties"); P(end) = [];
    N = length(P); m = obj.numPlayers;

    % Initialize feature vector
    state = zeros(1, 2*N);

    % ---------------------------------------------------------------------
    % Populate Ownership
    % ---------------------------------------------------------------------
    
    for i = 1:N
        state(i) = obj.board.owner(obj.board.property == P(i));
    end

    % ---------------------------------------------------------------------
    % Populate Houses/Mortgages
    % ---------------------------------------------------------------------

    for i = N+1:2*N
        idx = mod(i, N); if idx == 0; idx = N; end
        state(i) = obj.board.numHouses(obj.board.property == P(idx));
        if obj.board.isMortgaged(obj.board.property == P(idx)); state(i) = -1; end
    end

    % ---------------------------------------------------------------------
    % Populate Cash, Net Worth, GOJFC
    % ---------------------------------------------------------------------

    cash = zeros(1, m); netWorth = zeros(1, m); GOJFC = zeros(1, m);
    isJailed = zeros(1, m); isBankrupt = zeros(1, m);
    for i = 1:m
        cash(i) = obj.assets.("P" + string(i))(obj.assets.asset == Resource.cash);
        % netWorth(i) = obj.assets.("P" + string(i))(obj.assets.asset == Resource.netWorth);
        GOJFC(i) = obj.assets.("P" + string(i))(obj.assets.asset == Resource.getOutOfJail);
    end

    % state = [state cash netWorth GOJFC obj.isJailed obj.isBankrupt player];
    state = [state cash GOJFC obj.isJailed obj.isBankrupt player];

end