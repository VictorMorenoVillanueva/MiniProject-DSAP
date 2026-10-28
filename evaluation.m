%%
clear all;
addpath(genpath("MATLAB_code")); % We will use the Matlab code from Loizou

% Use |audioDatastore| to create a datastore for the files in the "..." folder.
noisy=audioDatastore("car/10dB/"); % Change it to the proper folder
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
            specsub(noisyFile,cleanedFile,params);
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
