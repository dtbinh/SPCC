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

[y,t,x] = lsim(sys_lqr, r, t);

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
r1 = 0.2*ones(size(t));

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
%% take the ouput y and and do 

y_x = y(1, :);
y_phi = y(2, :);

y_out.x = reshape(y_x, t(end)+Ts, []);
y_out.phi = reshape(y_x, t(end)+Ts, []);
y_out.t = reshape(t ,t(end)+Ts, []);

n = 1;

coefsX = zeros(n+1, length(y_out.x(1, :) ))';
coefsPhi = zeros(n+1, length(y_out.x(1, :) ))';

for i = 1 : length(y_out.x(1, :))
    
    coefsX_inter = polyfit(y_out.t(:,i), y_out.x(:, i), n);
    coefsX(i, :) = coefsX_inter; 
    
    coefsPhi(i, :) = polyfit(y_out.t(:,i), y_out.phi(:, i), n);
    
end


