try 
    
    a  = y;
    
catch
    
    load('output_input.mat')
    
end

M = 60;
p = 12;

params.m = 4;
params.n = 26;

Q_bar = eye(p);
bnds = [0.8, 1.5, 0.6]';

Ts = 0.01;

[~, Mmodels] = ACSA_1(M, y, Ck, p, params, Q_bar, bnds);
