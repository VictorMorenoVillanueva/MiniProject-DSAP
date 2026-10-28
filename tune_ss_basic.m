%% tune_ss_basic.m  -  STEP A: parameter sweep for basic spectral subtraction
%
% 1) Fix FLOOR = 0.002 and try several fixed over-subtraction values
%    (plus Berouti's adaptive beta, the original code, as reference).
% 2) With the best over-subtraction, try several FLOOR values.
% The VAD and the 5 initial noise frames are not changed.
%
% nFiles sets how many sentences are used. Saves:
%   tuning_beta.csv, tuning_floor.csv  -> parameter tables
%   tuning_ss_basic.mat                -> everything
% and plots PESQ and OVL against each parameter.
%
% Run from the Files4miniproject_Students folder.

clear; close all; clc;
addpath(pwd);
addpath(genpath('MATLAB_code'));

%% ---------------- CONFIGURATION ----------------
nFiles  = 30;                                   % sentences per condition
conds   = {'car',10; 'car',0; 'babble',10; 'babble',0};
betas   = [NaN 0.5 1 1.5 2 3 4 5 6 8];          % NaN = Berouti (original)
floors  = [0.001 0.002 0.005 0.01 0.02 0.05 0.1 0.2 0.5];
FLOOR_0 = 0.002;                                % FLOOR used in step 1
criterio = 2;                                   % selection criterion: 2 = PESQ, 5 = OVL

condNames = cellfun(@(a,b) sprintf('%s_%ddB',a,b), conds(:,1), conds(:,2), ...
                    'UniformOutput', false);

%% ---------------- STEP 1: over-subtraction ----------------
fprintf('STEP 1: beta sweep (FLOOR = %g)\n', FLOOR_0);
Rb = zeros(numel(conds(:,1)),5,numel(betas));
for i = 1:numel(betas)
    tic;
    Rb(:,:,i) = eval_ss_cfg(betas(i), FLOOR_0, conds, nFiles);
    fprintf('  beta = %-7s  mean PESQ = %.3f  mean OVL = %.3f  (%.0f s)\n', ...
            betaTxt(betas(i)), mean(Rb(:,2,i)), mean(Rb(:,5,i)), toc);
end
writeTable('tuning_beta.csv', betas, repmat(FLOOR_0,size(betas)), Rb, condNames);

% Best fixed beta (criterion averaged over the 4 conditions)
fijos = find(~isnan(betas));
[~, k] = max(squeeze(mean(Rb(:,criterio,fijos),1)));
bestBeta = betas(fijos(k));
fprintf('--> Best fixed beta: %g\n\n', bestBeta);

%% ---------------- STEP 2: FLOOR ----------------
fprintf('STEP 2: FLOOR sweep (beta = %g)\n', bestBeta);
Rf = zeros(numel(conds(:,1)),5,numel(floors));
for i = 1:numel(floors)
    tic;
    Rf(:,:,i) = eval_ss_cfg(bestBeta, floors(i), conds, nFiles);
    fprintf('  FLOOR = %-6g  mean PESQ = %.3f  mean OVL = %.3f  (%.0f s)\n', ...
            floors(i), mean(Rf(:,2,i)), mean(Rf(:,5,i)), toc);
end
writeTable('tuning_floor.csv', repmat(bestBeta,size(floors)), floors, Rf, condNames);

% Best FLOOR (criterion averaged over the 4 conditions)
[~, k] = max(squeeze(mean(Rf(:,criterio,:),1)));
bestFloor = floors(k);
fprintf('--> Best FLOOR: %g\n', bestFloor);
fprintf('\nBEST CONFIGURATION (%d sentences): beta = %g, FLOOR = %g\n', ...
        nFiles, bestBeta, bestFloor);
fprintf('Put it in final_ss_basic.m and run it with all 30 sentences.\n');

save('tuning_ss_basic.mat','betas','floors','Rb','Rf','conds','nFiles', ...
     'bestBeta','bestFloor','FLOOR_0');

%% ---------------- PLOTS ----------------
xb = betas(fijos);
figure('Name','Beta sweep');
subplot(1,2,1); plot(xb, squeeze(Rb(:,2,fijos))', '-o'); grid on;
xlabel('\beta (fixed over-subtraction)'); ylabel('PESQ'); title(sprintf('FLOOR = %g',FLOOR_0));
subplot(1,2,2); plot(xb, squeeze(Rb(:,5,fijos))', '-o'); grid on;
xlabel('\beta (fixed over-subtraction)'); ylabel('OVL');
legend(strrep(condNames,'_',' '),'Location','best');

figure('Name','FLOOR sweep');
subplot(1,2,1); semilogx(floors, squeeze(Rf(:,2,:))', '-o'); grid on;
xlabel('FLOOR'); ylabel('PESQ'); title(sprintf('\\beta = %g',bestBeta));
subplot(1,2,2); semilogx(floors, squeeze(Rf(:,5,:))', '-o'); grid on;
xlabel('FLOOR'); ylabel('OVL');
legend(strrep(condNames,'_',' '),'Location','best');

%% ---------------- HELPER FUNCTIONS ----------------
% Label for a beta value ('Berouti' for the adaptive original)
function s = betaTxt(b)
if isnan(b), s = 'Berouti'; else, s = sprintf('%g',b); end
end

% Write a results table (one row per configuration) as a CSV file
function writeTable(file, betas, floors, R, condNames)
meas = {'SegSNR','PESQ','sig','bak','ovl'};
fid = fopen(file,'w');
fprintf(fid,'beta;FLOOR');
for m = 1:5
    for c = 1:numel(condNames), fprintf(fid,';%s_%s',meas{m},condNames{c}); end
end
fprintf(fid,'\n');
for i = 1:numel(betas)
    fprintf(fid,'%s;%g', betaTxt(betas(i)), floors(i));
    for m = 1:5
        for c = 1:numel(condNames), fprintf(fid,';%.3f',R(c,m,i)); end
    end
    fprintf(fid,'\n');
end
fclose(fid);
fprintf('  (saved %s)\n', file);
end