% Prints the frequency bands that mband.m actually uses for every number of
% bands and spacing, taken from mband's own output (not recomputed here),
% and draws them in bands.png.
% For each band: FFT bins, frequency range (bin centres), number of bins and
% the delta weight the code applies (1 first band, 2.5 middle, 1.5 last).
% Bins shared by two bands are flagged: both bands add their power there.

addpath(genpath("MATLAB_code"));
f=dir(fullfile('car','10dB','*.wav'));
infile=fullfile(f(1).folder,f(1).name);
outfile=fullfile(tempdir,'show_bands.wav');

Nbands=[2 4 6 8];
spacings={'linear','log','mel'};

figure('Position',[100 100 1000 600]);
for s=1:numel(spacings)
    subplot(numel(spacings),1,s); hold on;
    for nb=Nbands
        b=mband(infile,outfile,nb,spacings{s});
        df=b.fs/b.fftl;                       % Hz per FFT bin
        fprintf('\n%s, %d bands  (%.2f Hz per bin)\n',upper(spacings{s}),nb,df);
        fprintf('  band   bins       frequency (Hz)    nbins  delta\n');
        for i=1:nb
            if i==1, delta=1; elseif i==nb, delta=1.5; else, delta=2.5; end
            shared='';
            if i<nb && b.hibin(i)>=b.lobin(i+1), shared='  <- shares bins with next band'; end
            fprintf('  %2d   %3d-%3d   %7.1f - %7.1f   %4d   %.1f%s\n',i,b.lobin(i),b.hibin(i), ...
                (b.lobin(i)-1)*df,(b.hibin(i)-1)*df,b.hibin(i)-b.lobin(i)+1,delta,shared);
            % one horizontal bar per band, coloured by delta
            col=[0.2 0.6 0.2]*(delta==1)+[0.85 0.3 0.1]*(delta==2.5)+[0.2 0.4 0.8]*(delta==1.5);
            x0=(b.lobin(i)-1.5)*df; x1=(b.hibin(i)-0.5)*df;
            patch([x0 x1 x1 x0],nb+[-0.35 -0.35 0.35 0.35],col,'EdgeColor','k');
        end
    end
    title(sprintf('%s spacing',spacings{s})); ylabel('Number of bands');
    yticks(Nbands); xlim([0 b.fs/2]); ylim([1 9]);
end
xlabel('Frequency (Hz)   [green: \delta=1, orange: \delta=2.5, blue: \delta=1.5]');
saveas(gcf,'bands.png');
