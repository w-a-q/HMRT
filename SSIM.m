%clc;clear all;
function [ Sst ] = SSIM( R,F )
%R=imread('E:\daobmp\test1\00001.bmp');
R=double(R);
%F=imread('E:\daobmp\背景预测评价指标\result_bj\gaijin_tophat.bmp');
F=double(F);
%F=double(rgb2gray(F));
[m,n]=size(R);

r_mean=mean(R(:));
r_std=std(R(:));  %标准差

f_mean=mean(F(:));
f_std=std(F(:));  %标准差

for i=5:m-4
    for j=5:n-4
        a(i,j)=(R(i,j)-r_mean)*(F(i,j)-f_mean);
    end
end

add=sum(a(:));
cov_RF=add./(m*n-1);
cov_RF1=cov(R,F);
cov_RF=cov_RF1(1,2);
aa=0.001;
Sst=((2*r_mean*f_mean+aa)*(2*cov_RF+aa))./((r_mean.^2+f_mean.^2+aa)*(r_std.^2+f_std.^2+aa));
Sst=abs(Sst);
