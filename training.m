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

%% Generate traininng data with lower epsilon

numGames = 500; counter = 1;
X = cell(numGames, 4); Y = cell(numGames, 1); M = cell(numGames, 1);

f = waitbar(counter/numGames, "Game " + string(counter) + " of " + string(numGames));
while counter <= numGames
    [temp, Y{counter}, M{counter}] = game.gameManager(model, [0.5, 0.5, 0.5, 0.5]);
    for i = 1:4; X{counter, i} = temp{i}; end
    counter = counter + 1; save("test_3.mat", 'X', 'Y', 'M')
    waitbar(counter/numGames, f, "Game " + string(counter) + " of " + string(numGames));
end; close(f)