%% Adaptive SS: blue/red waveforms, power spectrograms and PESQ baseline
% Run this script from MATLAB. Paths are resolved relative to this file.
% Waveforms: blue = noisy input, red = processed speech.
% Spectrogram colors encode power density, using one common color scale.
% Processed speech is NOT the original clean reference.
% The original clean recording is used as the PESQ reference.
% The shared specsub.m, VAD and noise initialization are not modified.

clear; clc;
projectDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(projectDir,'MATLAB_code')));
addpath(projectDir,'-begin');

%% Configuration
nFiles = 30;
conds = {'car',10; 'car',0; 'babble',10; 'babble',0};
calculatePESQ = true; % Set false to regenerate only the figures.

% Example shown in the spectrograms. Change these three settings as needed.
exampleNoise = 'car';
exampleSNR = 10;
examplePhrase = 1;

% Read the optimum selected by tune_ss_adaptive.m.
configFile = fullfile(projectDir,'tuning_ss_adaptive.mat');
config = load(configFile,'bestFloor');
assert(isfield(config,'bestFloor'), ...
    'The tuning MAT file does not contain bestFloor. Run tune_ss_adaptive first.');
optimalFloor = config.bestFloor;
assert(isscalar(optimalFloor) && isfinite(optimalFloor) && optimalFloor>=0, ...
    'bestFloor must be a finite nonnegative scalar.');

outputDir = fullfile(projectDir,'outputs','spectrogramas_pesq');
if ~exist(outputDir,'dir'), mkdir(outputDir); end

%% 1. Generate the selected example using adaptive Berouti subtraction
exampleClean = fullfile(projectDir,'clean',sprintf('sp%02d.wav',examplePhrase));
exampleNoisy = fullfile(projectDir,exampleNoise,sprintf('%ddB',exampleSNR), ...
    sprintf('sp%02d_%s_sn%d.wav',examplePhrase,exampleNoise,exampleSNR));
baseName = sprintf('sp%02d_%s_%ddB_floor_%g', ...
    examplePhrase,exampleNoise,exampleSNR,optimalFloor);
exampleProcessed = fullfile(outputDir,[baseName '_adaptive.wav']);

% [] is essential: it selects adaptive beta rather than a fixed value.
specsub(exampleNoisy,exampleProcessed,[],optimalFloor);
[x,fsNoisy] = audioread(exampleNoisy);
[y,fsProcessed] = audioread(exampleProcessed);
[~,fsClean] = audioread(exampleClean);
assert(fsNoisy==fsProcessed && fsNoisy==fsClean, ...
    'Clean, noisy and processed recordings must have the same sample rate.');
assert(size(x,2)==1 && size(y,2)==1,'This script expects mono recordings.');

% Match duration only for the visual comparison. PESQ uses the original files.
commonLength = min(size(x,1),size(y,1));
x = x(1:commonLength);
y = y(1:commonLength);

%% 1a. Time-domain waveforms: noisy input in blue, processed output in red
ink = [0.12 0.12 0.12];
waveTime = (0:commonLength-1)'/fsNoisy;
figWave = figure('Name','Noisy and adaptive SS waveforms', ...
    'Color','w','Position',[100 100 1200 500]);
axWave = axes(figWave);
plot(axWave,waveTime,x,'Color',[0.10 0.35 0.85],'LineWidth',0.8);
hold(axWave,'on');
plot(axWave,waveTime,y,'Color',[0.85 0.12 0.12],'LineWidth',0.8);
hold(axWave,'off');
xlabel(axWave,'Time (s)','Color',ink);
ylabel(axWave,'Amplitude (normalized audio samples)','Color',ink);
title(axWave,sprintf('sp%02d, %s, %d dB: adaptive Berouti, FLOOR = %g', ...
    examplePhrase,exampleNoise,exampleSNR,optimalFloor),'Color',ink);
set(axWave,'Color','w','XColor',ink,'YColor',ink, ...
    'FontName','Arial','FontSize',12,'GridColor',[0.75 0.75 0.75]);
grid(axWave,'on');
xlim(axWave,[0 commonLength/fsNoisy]);
amplitudeLimit = 1.05*max([abs(x);abs(y);eps]);
ylim(axWave,[-amplitudeLimit amplitudeLimit]);
legend(axWave,{'Noisy input','Adaptive output'},'Location','northeast', ...
    'Color','w','TextColor',ink,'FontSize',12);
% Both waveforms use the actual sample amplitudes, with no separate scaling.
exportgraphics(figWave,fullfile(outputDir,[baseName '_waveforms.png']),'Resolution',200);
savefig(figWave,fullfile(outputDir,[baseName '_waveforms.fig']));

%% 1b. Spectrograms: the SAME multicolor power-density scale in both panels
frameLength = floor(0.020*fsNoisy);
if rem(frameLength,2)==1, frameLength=frameLength+1; end
win = hamming(frameLength);
overlap = frameLength/2;
nFFT = 2*2^nextpow2(frameLength);
[~,freq,time,psdNoisy] = spectrogram(x,win,overlap,nFFT,fsNoisy);
[~,freqProcessed,timeProcessed,psdProcessed] = spectrogram(y,win,overlap,nFFT,fsProcessed);
assert(isequal(freq,freqProcessed) && isequal(time,timeProcessed));

% The fourth spectrogram output is power spectral density (power per Hz).
% Samples have the normalized audioread amplitude scale. Do not normalize
% each spectrogram independently: an identical color must mean identical PSD.
noisyDB = 10*log10(max(psdNoisy,eps));
processedDB = 10*log10(max(psdProcessed,eps));
peakDB = 10*ceil(max([noisyDB(:);processedDB(:)])/10);
colorLimits = [peakDB-80 peakDB];
powerMap = turbo(256);

fig = figure('Name','Noisy and adaptive SS spectrograms', ...
    'Color','w','Position',[100 100 1200 760]);
layout = tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
axNoisy = nexttile(layout);
imagesc(axNoisy,time,freq/1000,noisyDB);
axis(axNoisy,'xy');
clim(axNoisy,colorLimits);
colormap(axNoisy,powerMap);
ylabel(axNoisy,'Frequency (kHz)');
title(axNoisy,'Noisy input','Color',[0.10 0.35 0.80]);
barNoisy = colorbar(axNoisy);
barNoisy.Label.String = 'Power spectral density (dB/Hz)';

axProcessed = nexttile(layout);
imagesc(axProcessed,time,freq/1000,processedDB);
axis(axProcessed,'xy');
clim(axProcessed,colorLimits);
colormap(axProcessed,powerMap);
xlabel(axProcessed,'Time (s)');
ylabel(axProcessed,'Frequency (kHz)');
title(axProcessed,sprintf('Adaptive Berouti output, FLOOR = %g',optimalFloor), ...
    'Color',[0.80 0.10 0.10]);
barProcessed = colorbar(axProcessed);
barProcessed.Label.String = 'Power spectral density (dB/Hz)';
linkaxes([axNoisy axProcessed],'xy');
xlim(axNoisy,[0 commonLength/fsNoisy]);
ylim(axNoisy,[0 fsNoisy/2000]);
% Keep labels readable even when MATLAB uses a dark desktop theme.
set([axNoisy axProcessed],'XColor',ink,'YColor',ink, ...
    'FontName','Arial','FontSize',12);
axNoisy.YLabel.Color = ink;
axProcessed.XLabel.Color = ink;
axProcessed.YLabel.Color = ink;
set([barNoisy barProcessed],'Color',ink,'FontSize',11);
title(layout,sprintf('sp%02d, %s, input SNR = %d dB', ...
    examplePhrase,exampleNoise,exampleSNR),'FontSize',16,'Color',ink);

exportgraphics(fig,fullfile(outputDir,[baseName '_spectrograms.png']),'Resolution',200);
savefig(fig,fullfile(outputDir,[baseName '_spectrograms.fig']));

%% 2. Evaluate noisy input and adaptive output against the SAME clean reference
if calculatePESQ
% Save individual phrase scores as well as means. This also makes paired
% comparisons possible later. Negative improvement is retained, not hidden.
nConds = size(conds,1);
PESQNoisy = zeros(nFiles,nConds);
PESQAdaptive = zeros(nFiles,nConds);
temporaryAudio = [tempname(outputDir) '.wav'];
fprintf('Adaptive beta, FLOOR = %g. Evaluating %d phrases x %d conditions.\n', ...
    optimalFloor,nFiles,nConds);

try
    for c = 1:nConds
        noise = conds{c,1};
        inputSNR = conds{c,2};
        fprintf('\n%s, %d dB\n',noise,inputSNR);
        for n = 1:nFiles
            cleanFile = fullfile(projectDir,'clean',sprintf('sp%02d.wav',n));
            noisyFile = fullfile(projectDir,noise,sprintf('%ddB',inputSNR), ...
                sprintf('sp%02d_%s_sn%d.wav',n,noise,inputSNR));
            PESQNoisy(n,c) = pesq(cleanFile,noisyFile);
            specsub(noisyFile,temporaryAudio,[],optimalFloor);
            PESQAdaptive(n,c) = pesq(cleanFile,temporaryAudio);
            if mod(n,5)==0 || n==nFiles
                fprintf('  %d/%d phrases completed\n',n,nFiles);
            end
        end
    end
catch evaluationError
    if exist(temporaryAudio,'file'), delete(temporaryAudio); end
    rethrow(evaluationError);
end
if exist(temporaryAudio,'file'), delete(temporaryAudio); end

%% 3. Export tables and numerical results
meanNoisy = mean(PESQNoisy,1)';
meanAdaptive = mean(PESQAdaptive,1)';
TSummary = table(conds(:,1),cell2mat(conds(:,2)), ...
    repmat(nFiles,nConds,1),repmat(optimalFloor,nConds,1), ...
    meanNoisy,meanAdaptive,meanAdaptive-meanNoisy, ...
    'VariableNames',{'Noise','SNR_dB','NumPhrases','FLOOR', ...
    'PESQ_Noisy','PESQ_Adaptive','DeltaPESQ'});

TPerPhrase = table(repelem(conds(:,1),nFiles), ...
    repelem(cell2mat(conds(:,2)),nFiles),repmat((1:nFiles)',nConds,1), ...
    repmat(optimalFloor,nFiles*nConds,1), ...
    PESQNoisy(:),PESQAdaptive(:),PESQAdaptive(:)-PESQNoisy(:), ...
    'VariableNames',{'Noise','SNR_dB','Phrase','FLOOR', ...
    'PESQ_Noisy','PESQ_Adaptive','DeltaPESQ'});

writetable(TSummary,fullfile(outputDir,'pesq_noisy_vs_adaptive_summary.csv'));
writetable(TPerPhrase,fullfile(outputDir,'pesq_noisy_vs_adaptive_per_phrase.csv'));
save(fullfile(outputDir,'spectrograms_and_pesq_results.mat'), ...
    'TSummary','TPerPhrase','PESQNoisy','PESQAdaptive','optimalFloor', ...
    'conds','nFiles','exampleNoise','exampleSNR','examplePhrase', ...
    'x','y','waveTime','fsNoisy','psdNoisy','psdProcessed', ...
    'noisyDB','processedDB','freq','time','colorLimits');

fprintf('\nPESQ summary: each row averages %d phrases.\n',nFiles);
disp(TSummary);
fprintf('Mean noisy PESQ: %.4f\n',mean(meanNoisy));
fprintf('Mean adaptive PESQ: %.4f\n',mean(meanAdaptive));
fprintf('Mean improvement (adaptive minus noisy): %+.4f\n',mean(meanAdaptive-meanNoisy));
fprintf('Outputs saved in: %s\n',outputDir);
else
    % This branch is enabled by changing calculatePESQ to false above.
    fprintf('Waveforms and power spectrograms saved in: %s\n',outputDir); %#ok<UNRCH>
    fprintf('PESQ was not recalculated. Set calculatePESQ = true to evaluate it.\n');
end
