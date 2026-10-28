% Global comparison: every final configuration on car/babble at 0 and 10 dB.
% Replace the TODO parameters with the best values found in the sweeps.
% Results are appended to results.txt and saved in comparison.csv, and
% PESQ / OVL tables (configuration x condition) are printed.
% 6 configurations x 4 conditions x ~14 s = ~6 min.

configs={ ...
    'Noisy (unprocessed)',   'noisy',   struct(); ...
    'SS default',            'specsub', struct(); ...
    'SS fixed beta (tuned)', 'specsub', struct('beta_fixed',3,'FLOOR',0.002); ...  % TODO best of Step 1
    'SS Berouti (tuned)',    'specsub', struct('FLOOR',0.002); ...                 % TODO best of Steps 2-3
    'MB default',            'mband',   struct('Nband',6,'Freq_spacing','linear'); ...
    'MB tuned',              'mband',   struct('Nband',4,'Freq_spacing','log','FLOOR',0.005,'VAD',0,'Noisefr',7); ... % best of run_mband_sweep (0/10 dB)
    };

noiseTypes={'car','babble'};
snrLevels={'0dB','10dB'};

C=table();
for k=1:size(configs,1)
    for t=1:numel(noiseTypes)
        for s=1:numel(snrLevels)
            r=evaluation(configs{k,2},configs{k,3},noiseTypes{t},snrLevels{s},configs{k,1});
            C=[C; table(string(configs{k,1}),string(noiseTypes{t}),string(snrLevels{s}), ...
                r.segsnr,r.pesq,r.sig,r.bak,r.ovl,'VariableNames', ...
                {'config','noise','snr','segsnr','pesq','sig','bak','ovl'})];
        end
    end
end
writetable(C,'comparison.csv');

% One row per configuration, one column per condition
C.cond=C.noise+"_"+C.snr;
disp('PESQ'); disp(unstack(C(:,{'config','cond','pesq'}),'pesq','cond'));
disp('OVL');  disp(unstack(C(:,{'config','cond','ovl'}),'ovl','cond'));
