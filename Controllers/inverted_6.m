%% Make the Inverted Pendulum model
% Physical data stored in a struct
data.m = 0.2;
data.M = 1.5;
data.I = 0.005;
data.l = 0.5;
data.b = 0.1;
data.g = 9.81;

states = {'x', 'x_dot', 'phi', 'phi_dot'};
output = {'x', 'phi'};
input = {'u'};

Ts = 1 / 100;

[sys, sysd] = pendulum_ss(data, Ts);

%% Controllability

Q_c = ctrb(sysd);
Q_b = obsv(sysd);

CntrlBT = rank(Q_c);
ObsrvBT = rank(Q_b);

assert(CntrlBT == length(sysd.C), 'The model is not Controllable')
assert(ObsrvBT == length(sysd.C), 'The model is not Observable')

%% LQRD

Q = sysd.C'*sys.C;
R = 1;
K_opt = dlqr(sysd.A,sysd.B,Q,R);

Ak = sysd.A - sysd.B*K_opt;
Bk = sysd.B;
Ck = sysd.C;
Dk = sysd.D;

sys_lqr = ss(Ak, Bk,Ck, Dk, Ts, 'statename',states,'inputname',input,'outputname',output);

t = 0 : Ts : 10;
r = 0.2*ones(size(t));

% [y,t,x] = lsim(sys_lqr, r, t);

poles_A = eig(Ak);
%% Find poles 
sysc_lqr = d2c(sys_lqr,'zoh');

polesCA = eig(sysc_lqr.A);

%% Discrete Observer Implementation
% make observer poles 10x faster than LQR poles
multiple = 1;

% Put poles near orgin of unit circle in z-domain
poles_lqr = [0.0001, 0.001, 0.002, 0.0002]';
obvs_poles = multiple * real(poles_lqr);

% make sure poles are negative
if obvs_poles > 0
    obvs_poles = -1 * obvs_poles;
end

if obvs_poles == 0
    error('Poles are at zero')
end

L = place(sys_lqr.A', sys_lqr.C', obvs_poles);
L = L';

% Built the Observer model

Aobv = [sysd.A - sysd.B*K_opt, sysd.B*K_opt;
        zeros(size(sys.A)),    sysd.A - L*Ck];
    
Bobv = [ sysd.B;
         zeros(size( sysd.B ))];
         
Cobv = [Ck, zeros(size(Ck))];

Dobv = [0; 0];

states = {'x' 'x_dot' 'phi' 'phi_dot' 'e1' 'e2' 'e3' 'e4'};
input = {'r'};
output = {'x'; 'phi'};

sys_obv = ss(Aobv,Bobv,Cobv,Dobv,Ts,'statename',states,'inputname',input,'outputname',output);
    
% Step Input and Plot

t = 0 : Ts : 20-Ts;
unitstep = t>=0;
r1 = 10*ones(size(t));

w1 = 0.001*betarnd(2, 5, [2, length(r1)]);
v = 0.001*randn(size(r1));

F = [1; 0; 1; 0];

[x, y] = simulate(sys_obv, r1, t, v, w1);

figure
[AX1, H11, H21] = plotyy(t, y(1,:), t, y(2,:), 'plot');

set(get(AX1(1),'Ylabel'),'String','cart position (m)')
set(get(AX1(2),'Ylabel'),'String','pendulum angle (radians)')

title('Step Response with Digital Observer-Based State-Feedback Control')
grid on

figure
plot(t, r1,'r')
hold on
plot(t, y(1,:),'b')
hold on 
plot(t, y(2,:),'m')

grid on


%% Find error on y

e = x(5:8, :);
y_hat = Ck*(x(1:4, :) - e);
ey = y - y_hat;

figure
plot(t, ey(1,:),'.')
hold on
plot(t, ey(2,:),'.')
grid on

%% Analyse noise on y and find delta i

smp = 116;

ey_smp = ey(:, 1: smp);
n = 1;
t_smp = t(1, 1: smp);

coef_x = polyfit(t_smp, ey_smp(1,:), 1);
coef_phi = polyfit(t_smp, ey_smp(2,:), 1);
%

ey_smp_max = (ey_smp - [ coef_x(2); coef_phi(2) ]).^2;
ey_smp_max_x = max(ey_smp_max(1,:));
ey_smp_max_phi = max(ey_smp_max(2,:)); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% delta i is here:
ey_smp_max_x = sqrt(ey_smp_max_x);
ey_smp_max_phi = sqrt(ey_smp_max_phi);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hold on 
plot(t, ey_smp_max_x*ones(size(t)),'-');
hold on
plot(t, -ey_smp_max_x*ones(size(t)),'-');

% Violation Probab

viol = ey(1,:).^2 > ey_smp_max_x^2;

viol = sum(viol, 2) ./length(ey);
one_minus = 1 - viol;

fprintf('1 - epsilon = %d \n', one_minus)

%% Work out Ci

ABG = Aobv * x - Bobv*r1;
% remove the last as it is xk
ABG(:, end) = [];
% xCi is the xk+1 values 
xCi = x;
% remove first element
xCi(:, 1) = [];
% find out Ci the total noise elements from the system between steps
Ci = xCi - ABG;
yCi = Cobv*Ci;

