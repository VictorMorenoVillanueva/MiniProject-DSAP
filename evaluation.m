function res = evaluation(method, params, noiseType, snrLevel, label)

% Runs an enhancement method over all files of one noise condition and
% returns (and appends to results.txt) the average objective measures.
%
%  Usage:  res = evaluation(method, params, noiseType, snrLevel, label)
%
%         method    - 'noisy' (unprocessed baseline), 'specsub', 'mband'
%                     or 'wiener_as'
%         params    - struct with the method parameters:
%                     specsub: beta_fixed ([] = Berouti, default) and FLOOR
%                              (default 0.002), see help specsub
%                     mband:   Nband (default 6), Freq_spacing (default
%                              'linear') and any field of help mband
%         noiseType - 'car' or 'babble'
%         snrLevel  - '0dB', '5dB', '10dB' or '15dB'
%         label     - (optional) text to identify the configuration in results.txt
%
%  Example:
%         p.Nband=4; p.Freq_spacing='log'; p.FLOOR=0.02;
%         evaluation('mband', p, 'car', '0dB', 'MB 4 log FLOOR=0.02');

if nargin<2 || isempty(params), params=struct(); end
if nargin<3, noiseType='car'; end
if nargin<4, snrLevel='10dB'; end
if nargin<5, label=''; end

addpath(genpath("MATLAB_code")); % We will use the Matlab code from Loizou

% Use |audioDatastore| to create a datastore for the files in each folder.
noisy=audioDatastore(fullfile(noiseType,snrLevel));
clean=audioDatastore("clean");
nFiles=numel(noisy.Files);

noisyFile=fullfile(tempdir,"NoisySignal.wav");
cleanFile=fullfile(tempdir,"CleanSignal.wav");
cleanedFile=fullfile(tempdir,"CleanedSignal.wav");

snr_mean=zeros(1,nFiles); segsnr_mean=zeros(1,nFiles); Pesq=zeros(1,nFiles);
sig=zeros(1,nFiles); bak=zeros(1,nFiles); ovl=zeros(1,nFiles);

% Read and process the contents of each file from the datastore
for n=1:nFiles

    [NoisySignal,info] = read(noisy);
    [CleanSignal] = read(clean);
    samplingFreq=info.SampleRate;

    % Process the file, put the cleaned signal in CleanedSignal
    audiowrite(noisyFile,NoisySignal,samplingFreq);
    switch method
        case 'noisy'
            copyfile(noisyFile,cleanedFile);
        case 'specsub'
            beta_fixed=[]; FLOOR=0.002;
            if isfield(params,'beta_fixed'), beta_fixed=params.beta_fixed; end
            if isfield(params,'FLOOR'), FLOOR=params.FLOOR; end
            specsub(noisyFile,cleanedFile,beta_fixed,FLOOR);
        case 'mband'
            Nband=6; Freq_spacing='linear';
            if isfield(params,'Nband'), Nband=params.Nband; end
            if isfield(params,'Freq_spacing'), Freq_spacing=params.Freq_spacing; end
            mband(noisyFile,cleanedFile,Nband,Freq_spacing,params);
        case 'wiener_as'
            wiener_as(noisyFile,cleanedFile); % Wiener filter
        otherwise
            error('evaluation: unknown method "%s"',method);
    end

    % Compute evaluation measures
    audiowrite(cleanFile,CleanSignal,samplingFreq);
    [snr_mean(n), segsnr_mean(n)]= comp_snr(cleanFile,cleanedFile);
    Pesq(n)=pesq(cleanFile,cleanedFile);
    [sig(n),bak(n),ovl(n)]=composite(cleanFile,cleanedFile);
end

% Average measures
res.snr=mean(snr_mean);
res.segsnr=mean(segsnr_mean);
res.pesq=mean(Pesq);
res.sig=mean(sig); % predicted rating [1-5] of speech distortion
res.bak=mean(bak); % predicted rating [1-5] of noise distortion
res.ovl=mean(ovl); % predicted rating [1-5] of overall quality

% Append results to results.txt, one line per run
fileID = fopen('results.txt','a');
fprintf(fileID,'%s | %s | %s %s | %s | snr=%.2f segsnr=%.2f pesq=%.3f sig=%.3f bak=%.3f ovl=%.3f\n', ...
    datestr(now,'yyyy-mm-dd HH:MM'), method, noiseType, snrLevel, label, ...
    res.snr, res.segsnr, res.pesq, res.sig, res.bak, res.ovl);
fclose(fileID);
