% Multiband SS (mband.m) sweep on car and babble at 0 and 10 dB.
% Every combination of number of bands x frequency spacing is evaluated,
% keeping all other parameters at mband's defaults (FLOOR=0.002, VAD=1,
% Noisefr=6, AVRGING=1).
% Every run is appended to results.txt; the full table is saved in
% mband_bands.csv. Each configuration takes ~1 min (4 conditions x ~14 s):
% 4 x 3 = 12 configurations ~12 min.
% To also vary FLOOR / VAD, add values to FLOORs / VADs (e.g. [0.02 0.05], [0 1]).

devConds={'car','0dB'; 'babble','0dB'; 'car','10dB'; 'babble','10dB'};
Nbands=[2 4 6 8];
spacings={'linear','log','mel'};
FLOORs=0.002;        % mband default
VADs=1;              % mband default

T=table();
for Nband=Nbands
    for spacing=spacings
        for FLOOR=FLOORs
            for VAD=VADs
                p=struct('Nband',Nband,'Freq_spacing',spacing{1},'FLOOR',FLOOR,'VAD',VAD);
                T=[T; runDev(p,devConds)];
                writetable(T,'mband_bands.csv');   % saved after every configuration
            end
        end
    end
end

best=bestConfig(T);
fprintf('\nBest mband (mean PESQ): N=%d %s FLOOR=%g VAD=%d\n', ...
    best.Nband,best.Freq_spacing,best.FLOOR,best.VAD);


%--------------------------------------------------------------------------

function rows=runDev(p,devConds)
% Evaluates mband with params p on every dev condition, one table row each
lbl=sprintf('N=%d %s FLOOR=%g VAD=%d',p.Nband,p.Freq_spacing,p.FLOOR,p.VAD);
rows=table();
for c=1:size(devConds,1)
    r=evaluation('mband',p,devConds{c,1},devConds{c,2},lbl);
    rows=[rows; table(string(devConds{c,1}),string(devConds{c,2}), ...
        p.Nband,string(p.Freq_spacing),p.FLOOR,p.VAD, ...
        r.segsnr,r.pesq,r.sig,r.bak,r.ovl,'VariableNames', ...
        {'noise','snr','Nband','spacing','FLOOR','VAD','segsnr','pesq','sig','bak','ovl'})];
end
end

function best=bestConfig(T)
% Parameter struct with the highest PESQ averaged over the dev conditions
[g,cfg]=findgroups(T(:,{'Nband','spacing','FLOOR','VAD'}));
m=splitapply(@mean,T.pesq,g);
[~,k]=max(m);
best=table2struct(cfg(k,:));
best.Freq_spacing=char(best.spacing);
best=rmfield(best,'spacing');
end
