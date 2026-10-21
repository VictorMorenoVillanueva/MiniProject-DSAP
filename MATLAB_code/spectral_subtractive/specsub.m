function specsub(filename,outfile,params)

%  Implements the basic power spectral subtraction algorithm [1].
%
%  Usage:  specsub(noisyFile, outputFile)
%          specsub(noisyFile, outputFile, params)
%
%         noisyFile - noisy speech file in .wav format
%         outputFile - enhanced output file in .wav format
%         params - (optional) struct, any missing field takes its default:
%           alpha      - power exponent: 2 power SS, 1 magnitude SS (default 2)
%           FLOOR      - spectral floor, Berouti's "beta" (default 0.002)
%           beta_fixed - fixed oversubtraction factor, Berouti's "alpha".
%                        [] uses the SNR-dependent rule berouti() (default [])
%           useVAD     - 1 updates the noise psd with the simple VAD, 0 keeps
%                        the initial estimate for the whole file (default 1)
%           Thres      - VAD threshold in dB SNRseg (default 3)
%           G          - noise update smoothing factor (default 0.9)
%           Nnoise     - number of initial frames for noise psd (default 5)
%
%   Algorithm uses the first Nnoise frames to estimate the noise psd, and
%   then uses a very simple VAD algorithm for updating the noise psd.
%   Alternatively, the VAD in the file ss_rdc.m (this folder) can be used.
%
%   NOTE on notation: in this code "alpha" is the power exponent and "beta"
%   the oversubtraction factor, while in [1] alpha is the oversubtraction
%   factor and beta the spectral floor (FLOOR here).
%
%  References:
%   [1] Berouti, M., Schwartz, M., and Makhoul, J. (1979). Enhancement of speech 
%       corrupted by acoustic noise. Proc. IEEE Int. Conf. Acoust., Speech, 
%       Signal Processing, 208-211.
%
% Author: Philipos C. Loizou
%
% Copyright (c) 2006 by Philipos C. Loizou
% $Revision: 0.0 $  $Date: 10/09/2006 $
%-------------------------------------------------------------------------

if nargin<2
   fprintf('Usage: specsub noisyfile.wav outFile.wav \n\n');
   return;
end
if nargin<3, params=struct(); end

[x,Srate]=audioread(filename);


% =============== Initialize variables ===============
%

len=floor(20*Srate/1000); % Frame size in samples
if rem(len,2)==1, len=len+1; end;
PERC=50; % window overlap in percent of frame size
len1=floor(len*PERC/100);
len2=len-len1; 


Thres=getparam(params,'Thres',3); % VAD threshold in dB SNRseg
alpha=getparam(params,'alpha',2.0); % power exponent
FLOOR=getparam(params,'FLOOR',0.002);
G=getparam(params,'G',0.9);
beta_fixed=getparam(params,'beta_fixed',[]); % [] -> SNR-dependent oversubtraction
useVAD=getparam(params,'useVAD',1);
Nnoise=getparam(params,'Nnoise',5);

win=hamming(len); %tukey(len,PERC);  % define window
winGain=len2/sum(win); % normalization gain for overlap+add with 50% overlap

% Noise magnitude calculations - assuming that the first Nnoise frames is noise/silence
%
nFFT=2*2^nextpow2(len);
noise_mean=zeros(nFFT,1);
j=1;
for k=1:Nnoise
   noise_mean=noise_mean+abs(fft(win.*x(j:j+len-1),nFFT));
   j=j+len;
end
noise_mu=noise_mean/Nnoise;

%--- allocate memory and initialize various variables
   
k=1;
img=sqrt(-1);
x_old=zeros(len1,1);
Nframes=floor(length(x)/len2)-1;
xfinal=zeros(Nframes*len2,1);

%===============================  Start Processing ==================================
%
for n=1:Nframes 
   
   insign=win.*x(k:k+len-1);     %Windowing  
   spec=fft(insign,nFFT);     %compute fourier transform of a frame
   sig=abs(spec); % compute the magnitude
   
   %save the noisy phase information 
   theta=angle(spec);  
   
   SNRseg=10*log10(norm(sig,2)^2/norm(noise_mu,2)^2);
   
   if ~isempty(beta_fixed)
      beta=beta_fixed;
   elseif alpha==1.0
      beta=berouti1(SNRseg);
   else
     beta=berouti(SNRseg);
  end
   
   
   %&&&&&&&&&
   sub_speech=sig.^alpha - beta*noise_mu.^alpha;
   diffw = sub_speech-FLOOR*noise_mu.^alpha;
   
   % Floor negative components
   z=find(diffw <0);  
   if~isempty(z)
      sub_speech(z)=FLOOR*noise_mu(z).^alpha;
   end
   
   
   % --- implement a simple VAD detector --------------
   %
   if useVAD && (SNRseg < Thres)   % Update noise spectrum
      noise_temp = G*noise_mu.^alpha+(1-G)*sig.^alpha;   
      noise_mu=noise_temp.^(1/alpha);   % new noise spectrum
   end
   
   
   sub_speech(nFFT/2+2:nFFT)=flipud(sub_speech(2:nFFT/2));  % to ensure conjugate symmetry for real reconstruction
  
   x_phase=(sub_speech.^(1/alpha)).*(cos(theta)+img*(sin(theta)));
  
   
   % take the IFFT 
   xi=real(ifft(x_phase));
       
   % --- Overlap and add ---------------
   xfinal(k:k+len2-1)=x_old+xi(1:len1);
   x_old=xi(1+len1:len);
  
  

 k=k+len2;
end
%========================================================================================


audiowrite(outfile,winGain*xfinal,Srate,'BitsPerSample',16);


%--------------------------------------------------------------------------

function v=getparam(params,name,default)
% Returns params.(name) if present, otherwise the default value
if isfield(params,name)
   v=params.(name);
else
   v=default;
end

function a=berouti1(SNR)

if SNR>=-5.0 & SNR<=20
   a=3-SNR*2/20;
else
   
  if SNR<-5.0
   a=4;
  end

  if SNR>20
    a=1;
  end
  
end

function a=berouti(SNR)

if SNR>=-5.0 & SNR<=20
   a=4-SNR*3/20; 
else
   
  if SNR<-5.0
   a=5;
  end

  if SNR>20
    a=1;
  end
  
end
