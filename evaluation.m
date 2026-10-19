

%%
clear all;
addpath(genpath("MATLAB_code")); % We will use the Matlab code from Loizou
fileID = fopen('results.txt','w'); % Results will be saved for comparison

% Use |audioDatastore| to create a datastore for the files in the "..." folder.
noisy=audioDatastore("car/10db"); % Change it to the proper folder
clean=audioDatastore("clean");

% Read and process the contents of each file from the datastore
n=1;
samplingFreq=8000;
for n=1:30
    
    [NoisySignal] = read(noisy);
    [CleanSignal] = read(clean);
 
    % Process the file, put the cleaned signal in CleanedSignal
    audiowrite("NoisySignal.wav",NoisySignal,samplingFreq);
    wiener_as("NoisySignal.wav","CleanedSignal.wav"); % Wiener filter
    
    % Compute evaluation measures
    audiowrite("CleanSignal.wav",CleanSignal,samplingFreq);
    [snr_mean(n), segsnr_mean(n)]= comp_snr("CleanSignal.wav","CleanedSignal.wav");
    Pesq(n)=pesq("CleanSignal.wav","CleanedSignal.wav");
    [sig(n),bak(n),ovl(n)]=composite("CleanSignal.wav","CleanedSignal.wav");
end

% Average measures
snr_m=mean(snr_mean);
segsnr_m=mean(segsnr_mean);
pesq_m=mean(Pesq);

sig_m=mean(sig); % predicted rating [1-5] of speech distortion
bak_m=mean(bak); % predicted rating [1-5] of noise distortion
ovl_m=mean(ovl); % predicted rating [1-5] of overall quality

% Print results in file results.txt
fprintf(fileID,'\n segsnr_m=%1.1f pesq_m=%1.1f sig_m=%1.1f bak_m=%1.1f ovl_m=%1.1f\n',segsnr_m, pesq_m, sig_m, bak_m, ovl_m);
