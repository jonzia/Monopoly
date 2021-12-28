%% Generate data for random policy
numGames = 2; counter = 1;
X = cell(numGames, 4); Y = cell(numGames, 1); M = cell(numGames, 1);

f = waitbar(counter/numGames, "Game " + string(counter) + " of " + string(numGames));
while counter <= numGames
    [temp, Y{counter}, M{counter}] = game.gameManager([], 1);
    for i = 1:4; X{counter, i} = temp{i}; end
    counter = counter + 1; save("test.mat", 'X', 'Y', 'M')
    waitbar(counter/numGames, f, "Game " + string(counter) + " of " + string(numGames));
end; close(f)