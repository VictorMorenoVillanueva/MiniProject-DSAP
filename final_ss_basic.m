%% final_ss_basic.m  -  FASE B: resultados finales y audios de la SS basica
%
% Evalua con las 30 frases y las 4 condiciones:
%   - SS original (Berouti, FLOOR = 0.002)  -> referencia
%   - SS con la mejor configuracion (beta fija + FLOOR)
% Guarda:
%   results_ss_basic.csv  -> en el orden de columnas de la tabla Excel
%   audios_ss_basic/      -> frase de ejemplo: ruidosa, original, mejor y extremo
%
% Ejecutar desde la carpeta Files4miniproject_Students.
% Tarda bastante (30 frases x 4 condiciones x 2 sistemas).

clear; close all; clc;
addpath(pwd);
addpath(genpath('MATLAB_code'));

%% ---------------- CONFIGURACION ----------------
bestBeta  = 1.5;       % <-- pon aqui el resultado de tune_ss_basic.m
bestFloor = 0.05;    % <-- idem
extBeta   = 6;       % caso extremo para que se oiga el ruido musical
extFloor  = 0.001;
fraseEj   = 1;       % frase de ejemplo para los audios (sp01)
nFiles    = 30;
conds     = {'car',10; 'car',0; 'babble',10; 'babble',0};

%% ---------------- RESULTADOS (30 frases) ----------------
fprintf('SS original (Berouti, FLOOR = 0.002)...\n');
R_orig = eval_ss_cfg([], 0.002, conds, nFiles);
fprintf('SS mejor (beta = %g, FLOOR = %g)...\n', bestBeta, bestFloor);
R_best = eval_ss_cfg(bestBeta, bestFloor, conds, nFiles);

names = {'SS basic (Berouti, FLOOR=0.002)', ...
         sprintf('SS basic (beta=%g, FLOOR=%g)', bestBeta, bestFloor)};
R = {R_orig, R_best};

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

% Mostrar en pantalla
for s = 1:2
    fprintf('\n%s\n', names{s});
    for c = 1:size(conds,1)
        fprintf('  %-6s %2d dB | SegSNR %6.2f  PESQ %4.2f  sig %4.2f  bak %4.2f  ovl %4.2f\n', ...
                conds{c,1}, conds{c,2}, R{s}(c,:));
    end
end
save('results_ss_basic.mat','R_orig','R_best','bestBeta','bestFloor','conds','nFiles');
fprintf('\nGuardado results_ss_basic.csv\n');

%% ---------------- AUDIOS DE EJEMPLO ----------------
outDir = 'audios_ss_basic';
if ~exist(outDir,'dir'), mkdir(outDir); end
for c = 1:size(conds,1)
    noise = conds{c,1}; snr = conds{c,2};
    noisyFile = fullfile(noise, sprintf('%ddB',snr), ...
                         sprintf('sp%02d_%s_sn%d.wav',fraseEj,noise,snr));
    base = fullfile(outDir, sprintf('sp%02d_%s_%ddB',fraseEj,noise,snr));
    copyfile(noisyFile, [base '_1_ruidosa.wav']);
    specsub(noisyFile, [base '_2_original.wav'], [], 0.002);
    specsub(noisyFile, [base '_3_mejor.wav'], bestBeta, bestFloor);
    specsub(noisyFile, [base '_4_extremo.wav'], extBeta, extFloor);
end
copyfile(fullfile('clean',sprintf('sp%02d.wav',fraseEj)), ...
         fullfile(outDir,sprintf('sp%02d_0_limpia.wav',fraseEj)));
fprintf('Audios guardados en la carpeta %s\n', outDir);
