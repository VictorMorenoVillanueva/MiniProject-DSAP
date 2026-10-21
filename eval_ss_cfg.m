function M = eval_ss_cfg(BETA_FIJO, FLOOR, conds, nFiles)
% EVAL_SS_CFG  Evalua la SS basica con una configuracion (beta, FLOOR).
%
%   M = eval_ss_cfg(BETA_FIJO, FLOOR, conds, nFiles)
%
%   BETA_FIJO : sobresustraccion fija, o [] / NaN para Berouti (original)
%   FLOOR     : suelo espectral
%   conds     : {'car',10; 'car',0; 'babble',10; 'babble',0}
%   nFiles    : numero de frases (5 para barrido rapido, 30 para final)
%
%   M : matriz [nConds x 5] con la media de [SegSNR PESQ sig bak ovl]

if ~isempty(BETA_FIJO) && isnan(BETA_FIJO), BETA_FIJO = []; end

nConds = size(conds,1);
M   = zeros(nConds,5);
out = [tempname '.wav'];

for c = 1:nConds
    noise = conds{c,1};
    snr   = conds{c,2};
    V = zeros(nFiles,5);
    for n = 1:nFiles
        cleanFile = fullfile('clean', sprintf('sp%02d.wav',n));
        noisyFile = fullfile(noise, sprintf('%ddB',snr), ...
                             sprintf('sp%02d_%s_sn%d.wav',n,noise,snr));

        specsub(noisyFile, out, BETA_FIJO, FLOOR);

        [~, segsnr]     = comp_snr(cleanFile, out);
        p               = pesq(cleanFile, out);
        [sig, bak, ovl] = composite(cleanFile, out);
        V(n,:) = [segsnr p sig bak ovl];
    end
    M(c,:) = mean(V,1);
end

if exist(out,'file'), delete(out); end
end
