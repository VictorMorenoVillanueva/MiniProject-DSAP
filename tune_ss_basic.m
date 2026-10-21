%% tune_ss_basic.m  -  FASE A: barrido rapido de la SS basica
%
% 1) Fija FLOOR = 0.002 y prueba varios valores de sobresustraccion fija
%    (y Berouti, el original, como referencia).
% 2) Con la mejor sobresustraccion, prueba varios FLOOR.
% El VAD y las 5 tramas iniciales no se tocan.
%
% Usa pocas frases (nFiles) para ir rapido. Guarda:
%   tuning_beta.csv, tuning_floor.csv  -> tablas de parametros
%   tuning_ss_basic.mat                -> todo
% y dibuja PESQ y ovl frente a cada parametro.
%
% Ejecutar desde la carpeta Files4miniproject_Students.

clear; close all; clc;
addpath(pwd);
addpath(genpath('MATLAB_code'));

%% ---------------- CONFIGURACION ----------------
nFiles  = 5;                                    % frases por condicion
conds   = {'car',10; 'car',0; 'babble',10; 'babble',0};
betas   = [NaN 0.5 1 1.5 2 3 4 5 6 8];                    % NaN = Berouti (original)
floors  = [0.001 0.002 0.005 0.01 0.02 0.05 0.1 0.2 0.5];
FLOOR_0 = 0.002;                                % FLOOR durante el paso 1
criterio = 2;                                   % 2 = PESQ, 5 = ovl

condNames = cellfun(@(a,b) sprintf('%s_%ddB',a,b), conds(:,1), conds(:,2), ...
                    'UniformOutput', false);

%% ---------------- PASO 1: sobresustraccion ----------------
fprintf('PASO 1: barrido de beta (FLOOR = %g)\n', FLOOR_0);
Rb = zeros(numel(conds(:,1)),5,numel(betas));
for i = 1:numel(betas)
    tic;
    Rb(:,:,i) = eval_ss_cfg(betas(i), FLOOR_0, conds, nFiles);
    fprintf('  beta = %-7s  PESQ medio = %.3f  ovl medio = %.3f  (%.0f s)\n', ...
            betaTxt(betas(i)), mean(Rb(:,2,i)), mean(Rb(:,5,i)), toc);
end
writeTable('tuning_beta.csv', betas, repmat(FLOOR_0,size(betas)), Rb, condNames);

% Mejor beta fija (media del criterio sobre las 4 condiciones)
fijos = find(~isnan(betas));
[~, k] = max(squeeze(mean(Rb(:,criterio,fijos),1)));
bestBeta = betas(fijos(k));
fprintf('--> Mejor beta fija: %g\n\n', bestBeta);

%% ---------------- PASO 2: suelo ----------------
fprintf('PASO 2: barrido de FLOOR (beta = %g)\n', bestBeta);
Rf = zeros(numel(conds(:,1)),5,numel(floors));
for i = 1:numel(floors)
    tic;
    Rf(:,:,i) = eval_ss_cfg(bestBeta, floors(i), conds, nFiles);
    fprintf('  FLOOR = %-6g  PESQ medio = %.3f  ovl medio = %.3f  (%.0f s)\n', ...
            floors(i), mean(Rf(:,2,i)), mean(Rf(:,5,i)), toc);
end
writeTable('tuning_floor.csv', repmat(bestBeta,size(floors)), floors, Rf, condNames);

[~, k] = max(squeeze(mean(Rf(:,criterio,:),1)));
bestFloor = floors(k);
fprintf('--> Mejor FLOOR: %g\n', bestFloor);
fprintf('\nMEJOR CONFIGURACION (con %d frases): beta = %g, FLOOR = %g\n', ...
        nFiles, bestBeta, bestFloor);
fprintf('Ponla en final_ss_basic.m y ejecutalo con las 30 frases.\n');

save('tuning_ss_basic.mat','betas','floors','Rb','Rf','conds','nFiles', ...
     'bestBeta','bestFloor','FLOOR_0');

%% ---------------- GRAFICAS ----------------
xb = betas(fijos);
figure('Name','Barrido beta');
subplot(1,2,1); plot(xb, squeeze(Rb(:,2,fijos))', '-o'); grid on;
xlabel('\beta (sobresustraccion fija)'); ylabel('PESQ'); title(sprintf('FLOOR = %g',FLOOR_0));
subplot(1,2,2); plot(xb, squeeze(Rb(:,5,fijos))', '-o'); grid on;
xlabel('\beta (sobresustraccion fija)'); ylabel('ovl');
legend(strrep(condNames,'_',' '),'Location','best');

figure('Name','Barrido FLOOR');
subplot(1,2,1); semilogx(floors, squeeze(Rf(:,2,:))', '-o'); grid on;
xlabel('FLOOR'); ylabel('PESQ'); title(sprintf('\\beta = %g',bestBeta));
subplot(1,2,2); semilogx(floors, squeeze(Rf(:,5,:))', '-o'); grid on;
xlabel('FLOOR'); ylabel('ovl');
legend(strrep(condNames,'_',' '),'Location','best');

%% ---------------- FUNCIONES AUXILIARES ----------------
function s = betaTxt(b)
if isnan(b), s = 'Berouti'; else, s = sprintf('%g',b); end
end

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
fprintf('  (guardado %s)\n', file);
end
