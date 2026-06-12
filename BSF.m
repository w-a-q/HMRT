function [ output ] = BSF( in,out )
in=double(in);
out=double(out);
sigma_out=double(std(out(:)))
sigma_in=double(std(in(:)))

 output=(sigma_out/sigma_in)*10;
%output=(sigma_in/sigma_out)*10;

end

