%% Generate a plot to see what r looks like

% x.M, no. of global samples in the Multi-sample
x.M = 10000;
% x.no_sub_samp, the no of sets of sub-samples
x.no_sub_samp = 1;
% x.n, no. of samples in the sub-sample
x.n = x.M / x.no_sub_samp;

assert(x.n == norm(x.n), 'The number of Samples is not divisable by the number of sub-samples')

% x.dim, the dimension of the samples
x.dim = 2;
% x.sample, the global mutlisample
x.sample = randn(x.M, x.dim);

save('findR2.mat', '-v7.3')
    

%%
% produce r
r = 1 : x.M;

output = zeros(size(r));

for i = 1 : length(r)
    
    r_1 = r(i);
    
    q = r_1 : x.M;

    zeta = [2, x.dim+1];
    n2 = 1;
    zed = zeta(n2);

    n = x.M - r_1;
    k = q - r_1;

    beta_coefln =  betaln(n - k + 1, k+1);
    beta_coefln = log(1 ./ (n+1)) - beta_coefln  ;

    nom = betaln(x.M - q + zed, q - zed + 1);
    denom = betaln(zed, r_1 - zed + 1);

    total = beta_coefln + nom - denom;

    func = exp(total);
    func1 = func;
    func1(1) = [];
    func2 = func;
    func2(end) = [];
    
    func2 = [0, func2];
    func1 = [func1, 0];
    
    func3 = func2;
    func3(end) = [];
    func3 = [0, func3];
    
    func4 = func1;
    func4(1) = [];
    func4 = [func4, 0];
    
    func = [func1 ; func; func2; func3; func4];
    
    func = sum(func, 1);
    maxF = max(func);
    
    output(1, i) = r_1;
    output(2, i) = maxF;

end
%%
dif_1 = diff(output(2, :));

r_2 = output(1, :) + 0.5;
r_2(end) = [];

index = find(dif_1 <= 0.0001);
index = index(2);

rstar = r(index); 

fprintf('r = %d \n', rstar )

figure
plot(output(1,:), output(2, :))
grid on

figure
plot(r_2, dif_1)
grid on

ratio = rstar / x.M;

fprintf('ratio = %d \n', ratio)
