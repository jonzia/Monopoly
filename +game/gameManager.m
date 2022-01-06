function [X, Y, M] = gameManager(model, epsilon, varargin)

    % ---------------------------------------------------------------------
    % Runs a game as a sequential set of turns until end conditions are
    % met. Stores states and corresponding target outcome at each turn.
    % Inputs:
    % maxTurns          double      Maximum turns (default: 1000)
    % numPlayers        double      Number of players (default: 4)
    % lambda            double      \lambda for TD-\lambda (default: 30)
    %
    % Outputs:
    % X                 [M, N]      Data for M turns
    % Y                 double      Targets for M turns
    % M                 Monopoly    Final state
    % ---------------------------------------------------------------------

    % Set defaults and parse input
    maxTurns = 1000; lambda = 30; numPlayers = 4;
    if ~isempty(varargin)
        for i = 1:length(varargin)
            if strcmp(varargin{i}, 'maxTurns'); maxTurns = varargin{i+1}; end
            if strcmp(varargin{i}, 'lambda'); lambda = varargin{i+1}; end
            if strcmp(varargin{i}, 'numPlayers'); numPlayers = varargin{i+1}; end
        end
    end

    % Set placeholder for return values
    X = cell(1, numPlayers); Y = [];

    % NOTE: R = return, Y = accumulated return over next \lambda steps

    % Run game until maxTurns or 3 players are bankrupt
    turnCounter = 1; numBankrupt = 0; M = Monopoly(numPlayers);
    while (turnCounter <= maxTurns) && (numBankrupt < numPlayers - 1)

        % Get starting R
        R0 = zeros(1, numPlayers); R = zeros(1, numPlayers);
        for i = 1:numPlayers; R0(i) = M.target(i); end

        % Run turn
        M = game.turnManager(M, model, epsilon);

        % Get data and reward for current turn
        for i = 1:numPlayers; X{1, i} = [M.getState(i); X{1, i}]; ...
                R(i) = M.target(i)/lambda; end; Y = [R; Y];
        for i = 2:lambda
            if i > size(Y, 1); break; end
            Y(i, :) = Y(i, :) + R;
        end

        % Compute end conditions
        numBankrupt = sum(M.isBankrupt);
        turnCounter = turnCounter + 1;

    end

    if size(Y, 1) > lambda
        for i = 1:numPlayers; X{i} = flipud(X{i}(lambda+1:end, :)); end
        Y = flipud(Y(lambda+1:end, :));
    else
        X = []; Y = [];
    end

end