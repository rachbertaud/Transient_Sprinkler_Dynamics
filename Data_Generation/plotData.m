clc; clear; clf; close all;

trialCount = 1;
file = "1500f";

dt = 0.03366666;



% The following code ensures all he data is the same length so we can plot
% it on the same plot - if there is data that is longer/shorter than
% another, it inputs NaNs

for trial = 1:1:trialCount
    name = file + int2str(trial) + "_data.txt";
    data = readmatrix(name);
    
    % Defines "standard" length of data as that of trial 1
    if trial == 1
        fullData = data;
        N = length(data(:,1));
    else
        if(length(data(:,1)) ~= N)
            nShort = length(data(:,1));
            inN = N - nShort;

            if(inN < 0)
                % If trial data is longer, put extended time and NaNs in full data 
                % for all trails before
                fullData = [fullData; data(N+1:end, 1), NaN(abs(inN), trial-1)];
            else
                % If trial data is shorter, pad it with NaNs
                data(:,2) = [data(:,2); NaN(inN, 1)];
            end
        end

        % Append trials data to full data
        fullData = [fullData, data(:, 2)];
    end 
end 



% The following is an attempt to put the data on the same time scale - as
% they all start at different times

% kelly is suggesting using video to hear when the pump starts and use that
% for the time lag 

% is there a better way to do this shifting? Are we assuming too much here?


% Define Nx and Ny for full data set
[Nx, Ny] = size(fullData);

% Init an array to store a derivative estimate
deriv = zeros(Nx - 1, Ny - 1);

% Set same time scale for deriv and full data set
deriv(:, 1) = fullData(2:end, 1);

% derivate estimate 
for i = 2:1:Nx - 1
    deriv(i,2:trialCount + 1) = (fullData(i + 1,2:trialCount + 1) - fullData(i - 1,2:trialCount + 1))/(2*dt);
end 

% This finds the first location where the derivative is greater than zero
% for each trial - starts at 2 bc t is stored in 1
devLoc = [];
for i = 2:1:trialCount + 1
    devLoc = [devLoc, find(deriv(:,i) > 1, 1, 'first')];
end 

% Find the minimum time for all traisl - so whichever trial started first
minIdx = find(min(devLoc));
% 
% % Defines how many time steps are between each trial
% devDiffPre = (devLoc - devLoc(minIdx));

% Shifts all data to start at the minimum start time
devDiff = (devLoc - devLoc(minIdx))*dt;

% Defines a figure
f = figure(1);
f.Theme = "Light";


hold on 

t = fullData(:,1);


% Plots the shifted data
for trial = 1:1:trialCount
    dataName = "Trial " + int2str(trial);

    tShift = (t - devDiff(trial));

    plot(tShift, fullData(:,trial + 1), '-.', 'LineWidth', 2, 'DisplayName', dataName)
end 


% Defines common t domain
tCommon = t - max(devDiff);
% Init mean data vector
meanData = zeros(length(tCommon), 1);

% Interpolates data onto new t domain
for trial = 1:trialCount
    meanData = meanData + interp1(t - devDiff(trial), fullData(:, trial+1), tCommon, 'pchip');
end

% Determines where we want to cut time domain
cutT = find(tCommon >= 0 & tCommon <= 75);
% Determines mean on cut common time domain
meanData = meanData(cutT) / trialCount;
% Cuts common time domain
tCommon = tCommon(cutT);

% Plots mean data
plot(tCommon, meanData, '-', 'LineWidth', 2,  "DisplayName", "Mean of All Trials")
hold off
% Plot stuff
legend()
xlabel('Time (s)');
ylabel('Angular Displacement (degrees)');
title('Trial Data Comparison');

%%

name = "forward_1500_meanData.csv";

dataFinal = [tCommon, meanData];


writematrix(dataFinal, name, "Delimiter", ',');
type(name);