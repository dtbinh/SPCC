%% Initialise physical model and parameters for controller
% This script is implements the correct Lyapunov hessian weight P_bar
% Uses quadprog instead of mpcqpsolver

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
p = 10;

Q = C'*C;
R = 1;
% bounds on 
main_bounds = [1, 1]';
% bounds = [bounds; bounds];

%%
Time_out = 20;
x = zeros(no_states, Time_out/Ts);
y = zeros(no_outputs, Time_out/Ts);

x2 = x;
y2 = y;

Ck = zeros(1, Time_out/Ts);

X = x(:, 1);
maxF = 50;

for k = 1: (Time_out/Ts)-1 
    
    bounds = main_bounds;
    
    ck = optimal_input(A, B, C, X, K_opt, R, p, bounds, maxF);
    
    if isempty(ck)
        c = 0;
    else
    c = ck(1);
    end
       
    w =  0.01*randn(no_states, 1);
    w(2) = w(2)*0.1;
    v =  0.01*randn(no_outputs, 1);
    
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
plot(y(2, :));
hold on

plot(y2(1, :))
hold on
plot(y2(2, :));

grid on

figure
stairs(Ck)

grid on
%% Function for working out constrained MPC optimal input
function ck = optimal_input(A, B, C, X, K_opt, R, p, bounds, maxF)

% A is A + B*K_opt
phi = A;
[~, no_states] = size(A);

K_opt = [K_opt, zeros(1, no_states - length(K_opt))];

M = [zeros(p-1, 1), eye(p-1);
     zeros(1, p)];    

eN = eye(p);
eN = eN(1, :);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make psi
psi = [phi,                     B*eN;
       zeros(p, length(phi)),   M];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
E = [1, zeros(1, p-1)];

[len_output, ~] = size(C);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
F = [C, zeros(len_output, p);
     K_opt*eye(no_states), E];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
Q = C'*C;

Q_bar2 = [K_opt'*R*K_opt,   K_opt'*R*E;
          E'*R*K_opt,       E'*R*E];

[size_Qx, ~] = size(Q);
Q_bar = Q_bar2;
Q_bar(1: size_Qx, 1: size_Qx) = Q(1:size_Qx, 1: size_Qx) + Q;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% solve discrete Lyapunov equation:
P_bar = dlyap(psi', Q_bar);
% Construct -As x <= b, the -As part:

% [ax, ay] = size(F);

% initialise As
As = F;
for i = 1 : p-1
    % inefficient but easy to make
    As = [As ; F*psi^i];
    % A( (i)*ax + 1 : (i + 1)*ax, :) = F*psi^i; 
end
% split As into Ac and Ax
Ac = As(:, (no_states+1):end);
Ax = As(:, 1: no_states);

% repeat A
As = [As; -As];
Ac = [Ac; -Ac];
Ax = [Ax; -Ax];
% Make A negative
As = -As;
Ac = -Ac;

%% Construct -Ax <= -b, the -b part:

bounds2 = bounds;
for i = 1: length(As)/length(bounds) -1
    bounds2 = [bounds2; bounds];
end
    
b = -1*bounds2 + Ax*X;
%% Find H = Pcc from P_bar 
% Takes bottom right hand corner of P_bar this is the hessian
H = P_bar(no_states+1 : end, no_states+1 : end);

options = optimoptions('quadprog');
options.ConstraintTolerance = 1e-8;

%% Use equality constraints to feed in current position
% f is a vector of zeros
f = zeros(1, p)';

% x = quadprog(H,f,A,b,Aeq,beq,lb,ub,x0,options)
ck = quadprog(H, f, -Ac, -b, [], [], -maxF*ones(p, 1), maxF*ones(p, 1),[], options);
end
