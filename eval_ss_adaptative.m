addpath(genpath('MATLAB_code'));

entrada = 'car/10dB/sp01_car_sn10.wav';

for f = [0.002 0.02 0.03]
    salida = sprintf('salida/sp01_car_0dB_floor_%g.wav',f);
    specsub(entrada,salida,[],f);
end

%% 

load('tuning_ss_adaptive.mat','conds');

R_default = eval_ss_cfg([],0.002,conds,30);
R_002     = eval_ss_cfg([],0.02,conds,30);
R_003     = eval_ss_cfg([],0.03,conds,30);

save('validation_ss_adaptive.mat', ...
    'R_default','R_002','R_003','conds');