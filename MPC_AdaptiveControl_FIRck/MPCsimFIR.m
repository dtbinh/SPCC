function [y, u, t1, yhat, main_bounds] = MPCsimFIR(bias, Time_out, nWidth, s)

% Run simulation with varying time Dynamics

TsFast = 0.005;

TsObvs = 0.01;

rng(s);
%% Define the Observer
M0 = 1.5;   M = M0;
m0 = 0.2;   m = m0;

[~, sysdObv, L, K_opt] = inverted_pen_T(TsObvs, M0, m0);

A = sysdObv.A;
B = sysdObv.B;
C = sysdObv.C;
D = sysdObv.D;

p = 10;

Q = C'*C;
R = 1;

% main_bounds = [x, phi, u]
main_bounds = [0.8, 0.15, 40]';

ratioTs = TsObvs / TsFast;
%% Initialise the variable masses
x = zeros(4, Time_out/TsFast);
y = zeros(2, Time_out/TsFast);

xhat = zeros(4, Time_out/TsObvs);
yhat = zeros(2, Time_out/TsObvs);

u = x(1, :);
u_adapt = u;
u_lq = u;

Ck = zeros(1, Time_out/TsFast);
c = 0;

maxF = 100;

[H, f, Ac, Ax, b1, lb, ub, opt] = MPC_vars(A-B*K_opt, B, C, K_opt, R, p, main_bounds, maxF);
% cholesky for mpcqpsolver
[L2, ~] = chol(H,'lower');
Linv = inv(L2);

% options for mpcqpsolver:
options = mpcqpsolverOptions;

adaptTime = 1500;
%%
k0 = 1;
for k = 1 : Time_out/TsFast
        
    % Observer
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if k / ratioTs == round(k/ratioTs)
        
        k0 = k/ ratioTs;
        
        varW = 0.0051;
        varV = 0.0051;
        w =  varW*randn(4, 1);
        w(3) = w(3)*0.1 + varV*rand(1, 1) - 0.5*varV;
        v =  varV*rand(2, 1);
        v(2) = v(2)*0.1; 
        
        xhat(:, k0 + 1) = (sysdObv.A - sysdObv.B*K_opt - L*sysdObv.C)*xhat(:, k0) + sysdObv.B*c + L*y(:, k) + w;
        yhat(:, k0 + 1) = sysdObv.C*xhat(:, k0) + v;
        
        X = xhat(:, k0);
        
        b = b1 + Ax*X;
        
        if k <= adaptTime - 1
            % [x,status] = mpcqpsolver(Linv,f,A,b,Aeq,beq,iA0,options)
            ck = mpcqpsolver(Linv, f, Ac, b, [], zeros(0,1), false(size(b)), options);
            % ck = quadprog(H, f, -Ac, -b, [], [], lb, ub, [], options);

            if isempty(ck) || abs(ck(1)) > 10
                c = 0;
            else
                c = ck(1);
            end
        end
    end       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    bnds = [0.8, 1.5]';
    if k > adaptTime  && k / ratioTs == round(k/ratioTs)
        
        k0 = k/ ratioTs;
        % take input and outputs and build 2 FIR models
        nFIR = 30;
        mFIR = nFIR+150;
        p = nFIR*2;
        % build FIR coefficients
        Fy = buildFIR(y(1, 1:k), Ck(1:k), nFIR, mFIR);
        Fp = buildFIR(y(2, 1:k), Ck(1:k), nFIR, mFIR);       
        % put the two coefs together
        Ffir = [Fy'; Fp'];
        Ffir = fliplr(Ffir);
        
        model.A = A-B*K_opt;
        model.B = B;
        model.C = C;
        model.K_opt = K_opt;
        
        [b, Acp, Acc, no_coefs, H] = MPC_FIR_ck(model, Ffir, p, bnds);
        
        chat = Ck(k-no_coefs:k-1)';
        b = b - Acp*chat;
                        
        %H = MPC_vars(A-B*K_opt, B, C, K_opt, R, p, bnds, maxF);
        % cholesky for mpcqpsolver
        [L2, ~] = chol(H,'lower');
        Linv = inv(L2);
        
        ck = mpcqpsolver(Linv, zeros(length(Linv),1), -Acc, -b, [], zeros(0,1), false(size(b)), options);
        if isempty(ck) || abs(ck(1)) > 10
            c = 0;
        else
            c = ck(1);
        end
    end    
    % Physical Model
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    M = M - 0.01*TsFast*M + 0.001*TsFast*randn(1,1);
    m = m - 0.01*TsFast*m + 0.001*TsFast*randn(1,1);
    
    varW = 0.0051;
    varV = 0.0051;
    w =  varW*randn(4, 1);
    w(3) = w(3)*0.1 + varV*rand(1, 1) - 0.5*varV;
    v =  varV*rand(2, 1);
    v(2) = v(2)*0.1; 
    
    sysd = inverted_pen_T_model(TsFast, M, m);
    % use the MPC output value
    Ck(1, k) = c+0.01*randn(1,1);
    
    uk = -K_opt*xhat(:, k0) + Ck(k); 
    
    % limit on uk
    if abs(uk) > 100
        uk = 100 * abs(uk)/uk;
    end    
    u(k) = uk;
    
    u_lq(k) = -K_opt*xhat(:, k0);
        
    Ad = sysd.A + nWidth*rand(4) - bias*nWidth*ones(4);
        
    x(:, k+1) = Ad*x(:, k) + sysd.B*uk + w;
    y(:, k+1) = sysd.C*x(:, k+1) + v;
     
end


%%
figure

t1 = linspace(0, Time_out, length(y(1, :)));
t2 = linspace(0, Time_out, length(yhat(1, :)));

plot(t1, y(1, :), 'r')
hold on
% plot(t2, yhat(1, :));
grid on

stairs([0, Time_out], [main_bounds(1), main_bounds(1)], 'k')
stairs([0, Time_out], [-main_bounds(1), -main_bounds(1)], 'k')

title('Cart Position MPC vs LQR')
xlabel('Time/s')
ylabel('Cart Position from Centre')

figure
plot(t1, y(2, :), 'r')
hold on
% plot(t2, yhat(2, :));

stairs([0, Time_out], [main_bounds(2), main_bounds(2)], 'k')
stairs([0, Time_out], [-main_bounds(2), -main_bounds(2)], 'k')

grid on
title('Angle of Pendulum phi')
xlabel('Time/s')
ylabel('Angle phi of Pendulum')

figure
stairs(u)

grid on
title('Reference Input MPC')
end