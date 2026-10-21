% Step 0: unprocessed (noisy vs clean) baseline for every noise condition.
% Every enhancement result is compared against these numbers.

noiseTypes={'car','babble'};
snrLevels={'0dB','5dB','10dB','15dB'};

for t=1:numel(noiseTypes)
    for s=1:numel(snrLevels)
        res=evaluation('noisy',struct(),noiseTypes{t},snrLevels{s},'baseline');
        fprintf('%-6s %-4s  segsnr=%.2f pesq=%.3f sig=%.3f bak=%.3f ovl=%.3f\n', ...
            noiseTypes{t},snrLevels{s},res.segsnr,res.pesq,res.sig,res.bak,res.ovl);
    end
end
