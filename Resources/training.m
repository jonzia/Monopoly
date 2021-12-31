%% Generate data for random policy
numGames = 500; counter = 33;
X = cell(numGames, 4); Y = cell(numGames, 1); M = cell(numGames, 1);

f = waitbar(counter/numGames, "Game " + string(counter) + " of " + string(numGames));
while counter <= numGames
    [temp, Y{counter}, M{counter}] = game.gameManager([], 1);
    for i = 1:4; X{counter, i} = temp{i}; end
    counter = counter + 1; save("test.mat", 'X', 'Y', 'M')
    waitbar(counter/numGames, f, "Game " + string(counter) + " of " + string(numGames));
end; close(f)

%% Train ensemble regression model on ranndom policy

% Remove net worth information from state (focus on assets)
for i = 1:numGames
    for j = 1:4
        X{i, j}(:, 61:64) = [];
    end
end; model = cell(4, 1);

% Combine data. For each game, choose a player to evaluate.
for i = 1:4
    disp("Training model for player " + string(i))
    X_all = []; Y_all = []; 
    for j = 1:numGames
        X_all = [X_all; X{j, i}];
        Y_all = [Y_all; Y{j}(:, i)];
    end
    model{i} = fitrensemble(X_all, Y_all, 'NumLearningCycles', 100);
end; save('model.mat', 'model');

% Optimize hyperparameters (10-fold cross validation)
% Mdl = fitrensemble(X_all,Y_all,'OptimizeHyperparameters', 'all', ...
%     'HyperparameterOptimizationOptions',struct('AcquisitionFunctionName','expected-improvement-plus'))
% Mdl = fitrensemble(X_all, Y_all, 'NumLearningCycles', 300);
% Mdl = fitrensemble(X_all(1:100000, :), Y_all(1:100000), 'NumLearningCycles', 300, 'CrossVal', 'on');
% kflc = kfoldLoss(Mdl,'Mode','cumulative'); figure; plot(kflc);
% ylabel('10-fold cross-validated MSE');
% xlabel('Learning cycle');

%% Assess performance of model against random policy

numGames = 100; counter = 1;
X = cell(numGames, 4); Y = cell(numGames, 1); M = cell(numGames, 1);

f = waitbar(counter/numGames, "Game " + string(counter) + " of " + string(numGames));
while counter <= numGames
    [temp, Y{counter}, M{counter}] = game.gameManager(model, [0, 1, 1, 1]);
    for i = 1:4; X{counter, i} = temp{i}; end
    [~, winner] = max(table2array(M{counter}.assets(1, 3:end)));
    counter = counter + 1; save("test_2.mat", 'X', 'Y', 'M')
    waitbar(counter/numGames, f, "Game " + string(counter) + " of " + ...
        string(numGames) + ". Winner: " + string(winner));
end; close(f)

X_all = []; Y_all = [];
for i = 1:numGames
    X_all = [X_all; X{i, 1}]; Y_all = [Y_all; Y{i}(:, 1)];
end; X_all(:, 61:64) = []; pred = predict(model{1}, X_all);
tar = Y_all; figure; scatter(tar, pred);
lm = fitlm(pred, tar); r2 = lm.Rsquared.Adjusted;

%% What about removing cash information as well?

numGames = size(X, 1);

% Remove cash and net worth information from state (focus on assets)
for i = 1:numGames
    for j = 1:4
        X{i, j}(:, 57:64) = [];
    end
end; model = cell(4, 1);

% Combine data. For each game, choose a player to evaluate.
for i = 1:4
    disp("Training model for player " + string(i))
    X_all = []; Y_all = []; 
    for j = 1:numGames
        X_all = [X_all; X{j, i}];
        Y_all = [Y_all; Y{j}(:, i)];
    end
    model{i} = fitrensemble(X_all(1:100000, :), Y_all(1:100000), 'NumLearningCycles', 200);
    pred = predict(model{i}, X_all(100001:end, :)); tar = Y_all(100001:end);
    figure; scatter(tar, pred); lm = fitlm(tar, pred); disp(lm.Rsquared.Ordinary)
end
save('model_2.mat', 'model');

%% Generate training data with lower epsilon

numGames = 500; counter = 413;
% X = cell(numGames, 4); Y = cell(numGames, 1); M = cell(numGames, 1);

f = waitbar(counter/numGames, "Game " + string(counter) + " of " + string(numGames));
while counter <= numGames
    [temp, Y{counter}, M{counter}] = game.gameManager(model, [0.5, 0.5, 0.5, 0.5]);
    for i = 1:4; X{counter, i} = temp{i}; end
    counter = counter + 1; save("test_3.mat", 'X', 'Y', 'M')
    waitbar(counter/numGames, f, "Game " + string(counter) + " of " + string(numGames));
end; close(f)

%% Train another ensemble regression model against the stronger policy (37% win)

numGames = size(X, 1);

% Remove cash and net worth information from state (focus on assets)
for i = 1:numGames
    if isempty(X{i, 1}); continue; end
    for j = 1:4
        X{i, j}(:, 61:64) = [];
    end
end; model = cell(4, 1);

% Combine data. For each game, choose a player to evaluate.
for i = 1:4
    disp("Training model for player " + string(i))
    X_all = []; Y_all = []; 
    for j = 1:numGames
        if isempty(X{j, 1}); continue; end
        X_all = [X_all; X{j, i}];
        Y_all = [Y_all; Y{j}(:, i)];
    end
    model{i} = fitrensemble(X_all, Y_all, 'NumLearningCycles', 100);
    % pred = predict(model{i}, X_all(100001:end, :)); tar = Y_all(100001:end);
    % figure; scatter(tar, pred); lm = fitlm(tar, pred); disp(lm.Rsquared.Ordinary)
end; save('model_3.mat', 'model');


%% Compare new models against older models (should underestimate score?)

load('test_3.mat');
temp = load('model.mat'); old_model = temp.model;
temp = load('model_3.mat'); new_model = temp.model;
numGames = size(X, 1);

% Remove net worth information from state (focus on assets)
for i = 1:numGames
    if isempty(X{i, 1}); continue; end
    for j = 1:4
        X{i, j}(:, 61:64) = [];
    end
end; model = cell(4, 1);

% Combine data. For each game, choose a player to evaluate.
player = 4;
disp("Testing models for player " + string(player))
X_all = []; Y_all = []; 
for j = 1:numGames
    if isempty(X{j, 1}); continue; end
    X_all = [X_all; X{j, player}];
    Y_all = [Y_all; Y{j}(:, player)];
end; X_all = X_all(100001:end, :); Y_all = Y_all(100001:end);
pred_old = predict(old_model{player}, X_all); tar = Y_all;
pred_new = predict(new_model{player}, X_all);
figure; scatter(tar, pred_old); hold on; scatter(tar, pred_new); 
lm_old = fitlm(tar, pred_old); lm_new = fitlm(tar, pred_new);
disp("Old: " + string(lm_old.Rsquared.Ordinary) + ", New: " + string(lm_new.Rsquared.Ordinary))

%% Assess performance of model against random policy (35% win)

numGames = 100; counter = 1;
X = cell(numGames, 4); Y = cell(numGames, 1); M = cell(numGames, 1);

f = waitbar(counter/numGames, "Game " + string(counter) + " of " + string(numGames));
while counter <= numGames
    [temp, Y{counter}, M{counter}] = game.gameManager(model, [0, 1, 1, 1]);
    for i = 1:4; X{counter, i} = temp{i}; end
    [~, winner] = max(table2array(M{counter}.assets(1, 3:end)));
    counter = counter + 1; save("test_4.mat", 'X', 'Y', 'M')
    waitbar(counter/numGames, f, "Game " + string(counter) + " of " + ...
        string(numGames) + ". Winner: " + string(winner));
end; close(f)

X_all = []; Y_all = [];
for i = 1:numGames
    X_all = [X_all; X{i, 1}]; Y_all = [Y_all; Y{i}(:, 1)];
end; X_all(:, 61:64) = []; pred = predict(model{1}, X_all);
tar = Y_all; figure; scatter(tar, pred);
lm = fitlm(pred, tar); r2 = lm.Rsquared.Adjusted;