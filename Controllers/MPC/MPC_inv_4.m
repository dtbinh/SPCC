%% Initialise physical model and parameters for controller
% This script is implements the correct Lyapunov hessian weight P_bar
% Uses quadprog instead of mpcqpsolver
% separates MPC hessians from quadprog
% updated inverted_pen to reduce gain for observer 
% added Algo 1 for cart position

[sys_obv, L, K_opt] = inverted_pen;

A = sys_obv.A;
B = sys_obv.B;
C = sys_obv.C;
D = sys_obv.D;
Ts = sys_obv.Ts;

[~, no_states] = size(A);
[no_outputs, ~] = size(D);


%% Find MPC optimal

% z(k|k) = [x(k|k) ck]'
% z(k+i|k) = psi^i * z(k|k)

% horizon window length
p = 5;

Q = C'*C;
R = 1;
% bounds on 
% main_bounds = [x, phi, u]
main_bounds = [1, 0.2, 1]';
% bounds = [bounds; bounds];

%% 
ep_lo = 0.05;
ep_hi = 0.10;

Ppor = 0.9;
Ppst = 0.95;

%%
Time_out = 20;
x = zeros(no_states, Time_out/Ts);
y = zeros(no_outputs, Time_out/Ts);

x2 = x;
y2 = y;

Ck = zeros(1, Time_out/Ts);

X = x(:, 1);
maxF = 100;

[H, f, Ac, Ax, b1, lb, ub, options] = MPC_vars(A, B, C, K_opt, R, p, main_bounds, maxF);

b1_inter = zeros(1, Time_out/Ts);

for k = 1: (Time_out/Ts)-1 
    
    % Run algo 1 to update bounds
    if k >= 500
        
        ey = struct;
        ey_inter = [zeros(2, 4), C(:, 1:4)]*x(:, 1:k );
        
        ey.sample = ey_inter(1, :);
        ey.dim = 2;
        
        [r_star, Ptrail, Ntrail, q_min, q_max] = algo1(ey, ep_lo, ep_hi, Ppor, Ppst);
        [x_hat, q_hat] = algo1_return(ey, Ntrail, q_min, q_max);
        
        b1_inter(k) = x_hat(2, 1);
        
    end
    b2_algo1 = b1_inter(k)*ones(size(b1));
    
    b = b1 + b2_algo1 + Ax*X;
    
    ck = quadprog(H, f, -Ac, -b, [], [], lb, ub, [], options);
    
    if isempty(ck)
        c = 0;
    else
    c = ck(1);
    end
    
    varW = 0.01;
    varV = 0.01;
    
    w =  varW*randn(no_states, 1);
    w(3) = w(3)*0.1 + varV*rand(1, 1) - 0.5*varV;
    
    v =  varV*rand(no_outputs, 1);
    v(2) = v(2)*0.1; 
    
    x(:, k+1) = A*x(:, k) + B*c + w;
    y(:, k) = C*x(:, k) + v;
    
    X = x(:, k);
    
    x2(:, k+1) = A*x2(:, k) + w;
    y2(:, k) = C*x2(:, k) + v;
    
    
    Ck(k) = c;
end

%%
figure
plot(y(1, :))
hold on
plot(y2(1, :));
grid on

stairs(main_bounds(1) - b1_inter, 'k')
stairs(-main_bounds(1) + b1_inter, 'k')

plot(y(2, :), 'b')
hold on
plot(y2(2, :), 'r');

figure
plot(y(2, :))
hold on
plot(y2(2, :));

stairs(main_bounds(2) - b1_inter, 'k')
stairs(-main_bounds(2) + b1_inter, 'k')

grid on

figure
stairs(Ck)

grid on
