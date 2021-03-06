function [x_hat, q_hat] = algo1_return(x, Ntrail, q_min, q_max)

x.M = length(x.sample);
no_sub_samps = x.M / Ntrail;

% Take a round number which is smaller than 
if no_sub_samps >= round(no_sub_samps)
    no_sub_samps = round(no_sub_samps);
else
   no_sub_samps = round(no_sub_samps) - 1; 
end

% find the remainder and remove these from x
r = rem(x.M, no_sub_samps);

x_data = x.sample;

if r ~= 0
   x_data(:, 1:r) = []; 
end

x_reshape = reshape(x_data, [], no_sub_samps);

%% Optimisation step
% least squares a go
[~, len_samples] = size(x_reshape);

t = 1: len_samples;
n = 1;

coef = zeros(no_sub_samps, n+1);
max_dist = zeros(1, no_sub_samps);
phi_dist = max_dist;

for i = 1: length(x_data) / no_sub_samps
       
   coef_inter = polyfit(t, x_reshape(i, :), n); 
    
   coef(i, :) = coef_inter;
   % y_model = coef_inter*[t; ones(1, length(t))];
   
   c = [coef_inter(1, 1), 1]';
   
   x_opt = x_reshape(i, :);
   x_opt = x_opt - coef_inter(1, 2);
   
   x_opt = [t; x_opt];
   x_opt = x_opt;
   
   phi = atan(c(1));
   % rotation matrix
   % R = [c -s; c  s];
   % phi = 0;
   R = [cos(phi), -sin(phi);    
        sin(phi),   cos(phi)];
    
   x_R = R * x_opt;
   
   phi_dist(1, i) = phi;
   max_dist(1, i) = max(x_R(2, :));
   
end

%% find out which trial produced the best result

% model data contains the angle above the maximum value
model_data = [phi_dist; max_dist];
q_vals = zeros(1, no_sub_samps);

for i = 1: no_sub_samps
    % take each rotation
    % apply it to each the whole sample
    % find how many are within the max for that angle
    phi  = model_data(1, i);
    dist = model_data(2, i);
    
    R = [cos(phi), -sin(phi);    
        sin(phi),   cos(phi)];
    
    x_R = R*[1: length(x.sample); x.sample];
    
    logic_x_R = x_R(2, :) <= dist;  
    
    q_vals(1, i) = sum(logic_x_R, 2);
    
end

%% Find xhat and qhat by looking for the best model

compare = 0.5*(q_min + q_max);

diff = compare - q_vals;
[~, opt_index] = min(abs(diff));

x_hat = model_data(:, opt_index);
q_hat = q_vals(opt_index);

end