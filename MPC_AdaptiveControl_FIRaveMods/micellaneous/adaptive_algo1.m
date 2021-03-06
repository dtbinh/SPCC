function ck = adaptive_algo1(y, c, p, Q_bar, bnds, Ts)


%% 
ep_lo = 0.05;
ep_hi = 0.10;

Ppor = 0.9;
Ppst = 0.95;

x.dim = 2;
x.sample = y;
x.M = length(x.sample);

[rstar, ~, Ntrial, q_min, q_max] = algo1(x, ep_lo, ep_hi, Ppor, Ppst);

%%
Ntrial = round(Ntrial);
% take samples from the end/ most recent time samples
y_samp = fliplr(y);
c_samp = fliplr(c);

% preallocate c the input
c = zeros(p, Ntrial);
% make a Model cell arrays
Model = cell(4, Ntrial);

%% Parameters for Adaptive control

params.m = 4;
params.n = rstar - params.m;
params.Ts = Ts;

%% Calculate all the 
for i = 1: Ntrial
    
    y_inter = fliplr(y_samp(:, (i-1)*params.n +1 : end));
    c_inter = fliplr(c_samp(:, (i-1)*params.n +1 : end));
    
    [c(:, i), Model{1, i}, Model{2, i},  Model{3, i}, Model{4, 1}] = adaptiveControl5(Q_bar, y_inter, c_inter, p, params, bnds);
    
    
end

counter = zeros(1:Ntrial);

for j = 1: Ntrial
% choose an input from c to try all Models
input_seq = c(:, j);
% choose a set from Models
    for i = 1: Ntrial
        
        Phip = Model{1, i};
        Bp   = Model{2, i};
        Cp   = Model{3, i};
        
        x_t = Model{4, i};
        % Run each model 
        for t = 1:p
           
            x_t = Phip*x_t + Bp*input_seq(t, 1);
            y_t = Cp*x_t;
            
            if y_t.^2 < bnds(1:2, 1).^2
                
                counter(i) = counter(i) +1;
            end
        end
    end      
end
%% Choose Optimal model input:

compare = 0.5*(q_min + q_max);

diff = compare - counter;
[~, opt_index] = min(abs(diff));

% choose the optimal input which gives the optimal number of violations
ck = c(1, opt_index);


end