function selection = policy(states, model, varargin)
    % ---------------------------------------------------------------------
    % Returns a selection based on a model (to compute quality) and a
    % specified policy.
    % states    [MxN]   M states of size N
    % model             []: random selection
    % varargin:
    %   epsilon         Epsilon greedy policy [0, 1]
    %   baseline        Baseline state
    %   numPlayers      Number of players (default 4)
    % ---------------------------------------------------------------------

    % Parse varargin
    baseline = []; epsilon = ones(1, 8);
    if ~isempty(varargin)
        for i = 1:length(varargin)
            if strcmp(varargin{i}, 'epsilon'); epsilon = varargin{i+1};
            elseif strcmp(varargin{i}, 'baseline'); baseline = varargin{i+1};
            end
        end
    end; player = states(1, end); model = model{player}; epsilon = epsilon(player);

    % Must have random policy if model is empty
    if isempty(model); epsilon = 1; end

    % If epsilon = 1 or model = [], random policy
    if epsilon == 1 || isempty(model)
        if isempty(baseline)
            selection = randi([1, size(states, 1)]);
        else
            selection = randi([0, size(states, 1)]);
        end; return
    end

    % Otherwise, implement epsilon greedy policy
    quality = zeros(size(states, 1), 1);
    for i = 1:length(quality)
        quality(i) = predict(model, states(i, :));
    end
    % With probability 1-epsilon, select optimal policy
    if rand() > epsilon
        [q, selection] = max(quality);
        % If a baseline is provided, compare against the max proposed
        if ~isempty(baseline)
            baseline_quality = predict(model, baseline);
            if baseline_quality > q; selection = 0; end
        end
    else
        selection = randi([1, size(states, 1)]);
        % If a baseline is provided, randomly choose new state or base
        if ~isempty(baseline)
            if rand() > 0.5; selection = 0; end
        end
    end

end