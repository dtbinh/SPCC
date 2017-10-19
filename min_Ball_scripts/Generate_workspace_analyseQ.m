% Try to load previous workspace
% if no previously stored workspace is avaliable then make and save a new
% one

try load('out_put_data.mat')

catch 
    disp('No output from previous run')
    
    multisample
    save('out_put_data.mat')
end

%% Unviolated Points Q 
% Find the frequency and PDF by binning the number of unviolated in the Multisample

% q: the number of unviolated points in x.M the global sample
Q = x.M .*(1 - cell2mat(Output_data(violation_factors_entry, :) ));

% Length of the array of bins
len_arrBound = 1000;

% bound: the bin size
bound = ( max(Q) - min(Q) ) / len_arrBound;
% make bound an integer number 
bound = round(bound);

% gives the Frequency of Q
[freqQ, cumFreqQ, arrBQ, indices] = bin_var(Q, bound);

% normalizes the cumlatiave frequency of Q
cumQ_norm = cumFreqQ ./ max(cumFreqQ);
% normalizes the array of Q points
arr_norm = arrBQ / x.M;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot frequency of q
figure
hold off
plot(arrBQ, freqQ, '.')
grid on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
hold off
plot(arr_norm, cumQ_norm)
grid on
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% String Manipulation for plots
strXlab = 'Number of Unviolated Points, bound size: ';
strBound = num2str(bound);
strXlab = strcat(strXlab,{' '},strBound);

title('Cumulative Distribution compared with Violation Probability')
ylabel('Cumulative Probability')
xlabel(strXlab)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This bins all the data that is betweent the bound in Q
output_bin = cell(2, length(arrBQ));

for i = 1 : length(arrBQ)
    
    output_bin{1, i} = Q( indices(i, :) );
    output_bin{2, i} = arrBQ(i);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Work out Theoretical plots
% zeta again
zeta = [2, x.dim+1];
% epsilon is 1 - q/x.M
% q/x.M = epsilon, epsilon = arr_norm

% Try Theorem 4:

n = x.M - zeta(1);
b_c = 1 / (n+1);

beta_coef = zeros(size(arrBQ));
for i = 1: length(arrBQ)
    
    k = arrBQ(i) - zeta(2);
    beta_coef(i) = b_c / beta(n - k + 1, k+1);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



