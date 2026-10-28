% Tune adaptive Berouti subtraction by varying only the spectral floor.
% Each condition's metrics are averaged over the first nFiles phrases.
% Run from the project folder. Set nFiles = 30 for the full dataset.
clear; clc;
addpath(pwd);
addpath(genpath('MATLAB_code'));

conds = {'car',10; 'car',0; 'babble',10; 'babble',0};

nFiles = 30;

floors = [0.001 0.002 0.005 0.01 0.02 0.05 0.1 0.2 0.5];

nConds = size(conds,1);
R = zeros(nConds,5,numel(floors));
meanPESQ = zeros(numel(floors),1);

fprintf('Adaptive Berouti: %d floors x %d conditions x %d phrases = %d runs.\n', ...
    numel(floors),nConds,nFiles,numel(floors)*nConds*nFiles);
for i = 1:numel(floors)
    fprintf('Floor %d/%d: %g ...\n',i,numel(floors),floors(i));
    floorTimer = tic;
    R(:,:,i) = eval_ss_cfg([], floors(i), conds, nFiles);
    meanPESQ(i) = mean(R(:,2,i));
    fprintf('  Mean PESQ: %.4f (%.1f s)\n',meanPESQ(i),toc(floorTimer));
end

[~,idx] = max(meanPESQ);
bestFloor = floors(idx);

% Wide table: one row per floor, one PESQ column per noise/SNR pair.
T = table(floors(:),'VariableNames',{'FLOOR'});
for c = 1:nConds
    columnName = sprintf('PESQ_%s_%ddB',conds{c,1},conds{c,2});
    T.(columnName) = reshape(R(c,2,:),[],1);
end
T.MeanPESQ = meanPESQ; % Equal-weight average over all eight conditions.
fprintf('\nPESQ by condition (each score averages %d phrases):\n',nFiles);
disp(T);
fprintf('Best adaptive FLOOR by mean PESQ: %g (PESQ %.4f)\n', ...
    bestFloor,meanPESQ(idx));

% Long table: all metrics for every floor/noise/SNR combination.
metricNames = {'SegSNR','PESQ','sig','bak','ovl'};
nRows = numel(floors)*nConds;
floorColumn = repelem(floors(:),nConds);
noiseColumn = repmat(conds(:,1),numel(floors),1);
snrColumn = repmat(cell2mat(conds(:,2)),numel(floors),1);
phraseCount = repmat(nFiles,nRows,1);
metrics = reshape(permute(R,[1 3 2]),nRows,5);
T_details = [table(floorColumn,noiseColumn,snrColumn,phraseCount, ...
    'VariableNames',{'FLOOR','Noise','SNR_dB','NumPhrases'}), ...
    array2table(metrics,'VariableNames',metricNames)];

writetable(T,'tuning_floor_adaptive.csv');
writetable(T_details,'tuning_floor_adaptive_details.csv');
save('tuning_ss_adaptive.mat', ...
    'R','floors','meanPESQ','bestFloor','conds','nFiles', ...
    'T','T_details','metricNames');
fprintf('Saved tuning_floor_adaptive.csv, tuning_floor_adaptive_details.csv, and tuning_ss_adaptive.mat.\n');
