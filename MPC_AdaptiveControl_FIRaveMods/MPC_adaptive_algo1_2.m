%% Initialise physical model and parameters for controller
% This script is implements the correct Lyapunov hessian weight P_bar
% Uses quadprog instead of mpcqpsolver
% separates MPC hessians from quadprog
% updated inverted_pen to reduce gain for observer 
% added Algo 1 for cart position
% Run Algo 1 on the cart angle
% variable Variance after k = 1000;
% finite size on algo 1 data
% gather confidences of algo 1 on both x and phi
% Replace quadprog with mpcqpsolver

tic
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

% horizon window length make sure divisible by 3
p = 12;

Q = C'*C;
R = 1;
% bounds on 
% main_bounds = [x, phi, u]
main_bounds = [0.8, 0.15, 0.4]';
% bounds = [bounds; bounds];

%% 
ep_lo = 0.05;
ep_hi = 0.10;

Ppor = 0.9;
Ppst = 0.95;

%% prepare MPC 
Time_out = 30;
x = zeros(no_states, Time_out/Ts);
y = zeros(no_outputs, Time_out/Ts);

x2 = x;
y2 = y;

Xp = zeros(4, Time_out/Ts);

u = x(1, :);
u_adapt = u;

Ck = zeros(1, Time_out/Ts);

X = x(:, 1);
maxF = 100;

[H, f, Ac, Ax, b1, lb, ub, opt] = MPC_vars(A, B, C, K_opt, R, p, main_bounds, maxF);
% cholesky for mpcqpsolver
[L2, ~] = chol(H,'lower');
Linv = inv(L2);

% options for mpcqpsolver:
options = mpcqpsolverOptions;

b1_inter = zeros(1, Time_out/Ts);
b2_inter = zeros(1, Time_out/Ts);

% preallocate the confidence of algorithm1
confid = b1_inter;
confid2 = confid;

fprintf('Progress:')
%% For loop for MPC

for k = 1: (Time_out/Ts)-1 
    
    % progress bar
    if k/100 == round(k/100)
       fprintf('#') 
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if k < 1299
    % Run algo 1 to update bound    
    b = b1 + Ax*X;
        
    % [x,status] = mpcqpsolver(Linv,f,A,b,Aeq,beq,iA0,options)
    ck = mpcqpsolver(Linv, zeros(p, 1), Ac, b, [], zeros(0,1), false(size(b)), options);
    % ck = quadprog(H, f, -Ac, -b, [], [], lb, ub, [], options);
    
        if isempty(ck) || abs(ck(1)) > 10
            c = 0;
        else
            c = ck(1);
        end
     % initialise the adaptive control/ input/ output models
        if k == 1298
            % Try statement 

            params.m = 4;
            params.n = 100 - params.m;
            params.Ts = Ts;

            [~, ~, P, ~] = least_squares_params(y(:, 1: k-1), u(:, 1:k-1), params.n, params.m);

            [Ap2, Bp2, Cp2] = estSS(P, params.m);

            Kp2 = dlqr(Ap2,Bp2,Cp2'*Cp2,1,0);
            
            PhiP2 = Ap2 - Bp2*Kp2;
            % generate the states for the parameter estimation
            Xp = getState_n_4(y(:, 1:k-1), u(:, 1:k-1), PhiP2, Bp2, Cp2);
            
            bnds = [0.8, 1.5, 0.4]';
            [Q_bar, ~, ~, ~, ~, ~, ~, ~] = MPC_vars(PhiP2, Bp2, Cp2, Kp2, R, p, bnds, maxF);
            
            % This would be threaded used to generate RStarModels
            M = 80;
        
            params.m = 4;
            params.n = 10;
            [ck, Mmodels, RstarModel, entry] = ACSA_1(M, y(:, 1:k-1), u(:, 1:k-1), p, params, Q_bar, bnds, Xp);
                        
        end
     
     else
        M = 80;
        
        params.m = 4;
        params.n = 10;

        
        if k/25 == round(k/25)
            
            Xp = getState_n_4(y(:, 1:k-1), u(:, 1:k-1), PhiP2, Bp2, Cp2);
            
            [~, Mmodels, RstarModel, entry] = ACSA_1(M, y(:, 1:k-1), u(:, 1:k-1), p, params, Q_bar, bnds, Xp);
        end
        % genereate the states from set RstarModel
        % generate uk = [Kopt1, ... Kopti, ... KoptR]*[Xp1,...XpR]' + ck
        [uk, ck] = RmodelOutput(Q_bar, RstarModel, entry, y(:, 1:k-1), u(:, 1:k-1), p);
        
        if abs(uk) > 10 || abs(ck(1)) > 10
            uk = 0;
            ck = 0;
        end
        
        c = uk(1);
        u_adapt(k) = uk;
        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    varW = 0.01;
    varV = 0.01;
    
    w =  varW*randn(no_states, 1);
    w(3) = w(3)*0.1 + varV*rand(1, 1) - 0.5*varV;
    
    v =  varV*rand(no_outputs, 1);
    v(2) = v(2)*0.1; 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    x(:, k+1) = A*x(:, k) + B*c + w;
    y(:, k) = C*x(:, k) + v;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    X = x(:, k);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    x2(:, k+1) = A*x2(:, k) + w;
    y2(:, k) = C*x2(:, k) + v;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    u(1, k) = [K_opt, zeros(1, 4)]*X + c;
    
    Ck(k) = c;
       
end

fprintf('\n')
%%
figure
plot(y(1, :))
hold on
plot(y2(1, :));
grid on

stairs(main_bounds(1) - b1_inter, 'k')
stairs(-main_bounds(1) + b1_inter, 'k')

title('Cart Position MPC vs LQR')
xlabel('Time Steps')
ylabel('Cart Position from Centre')

figure
plot(y(2, :))
hold on
plot(y2(2, :));

stairs(main_bounds(2) - b2_inter, 'k')
stairs(-main_bounds(2) + b2_inter, 'k')

grid on
title('Angle of Pendulum phi')
xlabel('Time Steps')
ylabel('Angle phi of Pendulum')

figure
stairs(Ck)

grid on
title('Reference Input MPC')

toc