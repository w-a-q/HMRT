function snr=SNR(I,In)
% 计算信号噪声比函数
% by Qulei 
% I :original signal
% In:noisy signal(ie. original signal + noise signal)
% snr=10*log10(sigma2(I2)/sigma2(I2-I1))

[row,col,nchannel]=size(I);

snr=0;
Ps=sum(sum((I-mean(mean(I))).^2));%signal power
Pn=sum(sum((I-In).^2));%noise power
snr=10*log10(Ps/Pn);
