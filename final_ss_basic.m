%% final_ss_basic.m  -  STEP B: final results and audio examples for basic SS
%
% Evaluates on all 30 sentences and the 4 conditions:
%   - Original SS (Berouti, FLOOR = 0.002)  -> reference
%   - SS with the best configuration (fixed beta + FLOOR)
% Saves:
%   results_ss_basic.csv  -> same column order as the Excel results table
%   audios_ss_basic/      -> example sentence: noisy, original, best and extreme
%
% Run from the Files4miniproject_Students folder.
% Takes a while (30 sentences x 4 conditions x 2 systems).

clear; close all; clc;
addpath(pwd);
addpath(genpath('MATLAB_code'));

%% ---------------- CONFIGURATION ----------------
bestBeta  = 5;        % <-- result of tune_ss_basic.m
bestFloor = 0.002;    % <-- same
extBeta   = 6;        % extreme case, so the musical noise can be heard
extFloor  = 0.001;
fraseEj   = 1;        % example sentence for the audio files (sp01)
nFiles    = 30;
conds     = {'car',10; 'car',0; 'babble',10; 'babble',0};

%% ---------------- RESULTS (30 sentences) ----------------
fprintf('Original SS (Berouti, FLOOR = 0.002)...\n');
R_orig = eval_ss_cfg([], 0.002, conds, nFiles);
fprintf('Best SS (beta = %g, FLOOR = %g)...\n', bestBeta, bestFloor);
R_best = eval_ss_cfg(bestBeta, bestFloor, conds, nFiles);

names = {'SS basic (Berouti, FLOOR=0.002)', ...
         sprintf('SS basic (beta=%g, FLOOR=%g)', bestBeta, bestFloor)};
R = {R_orig, R_best};

% Write the results as CSV (same column order as the Excel table)
meas = {'SegSNR','PESQ','sig','bak','ovl'};
fid = fopen('results_ss_basic.csv','w');
fprintf(fid,'Technique');
for m = 1:5
    for c = 1:size(conds,1), fprintf(fid,';%s_%s_%ddB',meas{m},conds{c,1},conds{c,2}); end
end
fprintf(fid,'\n');
for s = 1:2
    fprintf(fid,'%s',names{s});
    for m = 1:5
        for c = 1:size(conds,1), fprintf(fid,';%.2f',R{s}(c,m)); end
    end
    fprintf(fid,'\n');
end
fclose(fid);

% Show the results on screen
for s = 1:2
    fprintf('\n%s\n', names{s});
    for c = 1:size(conds,1)
        fprintf('  %-6s %2d dB | SegSNR %6.2f  PESQ %4.2f  sig %4.2f  bak %4.2f  ovl %4.2f\n', ...
                conds{c,1}, conds{c,2}, R{s}(c,:));
    end
end
save('results_ss_basic.mat','R_orig','R_best','bestBeta','bestFloor','conds','nFiles');
fprintf('\nSaved results_ss_basic.csv\n');

%% ---------------- AUDIO EXAMPLES ----------------
% Note: the file names (_1_ruidosa, _2_original, _3_mejor, _4_extremo, _0_limpia)
% are kept as they are because make_figures.m reads these exact names.
outDir = 'audios_ss_basic';
if ~exist(outDir,'dir'), mkdir(outDir); end
for c = 1:size(conds,1)
    noise = conds{c,1}; snr = conds{c,2};
    noisyFile = fullfile(noise, sprintf('%ddB',snr), ...
                         sprintf('sp%02d_%s_sn%d.wav',fraseEj,noise,snr));
    base = fullfile(outDir, sprintf('sp%02d_%s_%ddB',fraseEj,noise,snr));
    copyfile(noisyFile, [base '_1_ruidosa.wav']);                  % noisy
    specsub(noisyFile, [base '_2_original.wav'], [], 0.002);        % original SS
    specsub(noisyFile, [base '_3_mejor.wav'], bestBeta, bestFloor); % best configuration
    specsub(noisyFile, [base '_4_extremo.wav'], extBeta, extFloor); % extreme (musical noise)
end
copyfile(fullfile('clean',sprintf('sp%02d.wav',fraseEj)), ...
         fullfile(outDir,sprintf('sp%02d_0_limpia.wav',fraseEj)));  % clean reference
fprintf('Audio files saved in folder %s\n', outDir);