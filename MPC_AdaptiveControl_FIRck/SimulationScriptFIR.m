%% Runs Adaptive MPC and MPC 
tic
% Bias on the Model variance
bias = 0.50;
% noise width for the uniform dist
nWidth = 0.053;
% Time out time
Time_out = 30;
% save in s the current random noise generator
s = 'default';

% Run Adaptive MPC FIR algorithm
[yAdapt, uAdapt, ~, yhatAdapt, ~] = AdaptiveMPCsimFIR(bias, Time_out, nWidth, s);

% Run MPC FIR algorithm
[yMPC, uMPC, t1, yhatMPC, main_bounds] = MPCsimFIR(bias, Time_out, nWidth, s);

toc
%% Count the Violations

noViolAdapt = countViolations(yAdapt, main_bounds);
eps_Adapt = noViolAdapt/(2*length(yAdapt(1, :)));

noViolMPC = countViolations(yMPC, main_bounds);
eps_MPC = noViolMPC/(2*length(yMPC(1, :)));

%% Plot figures 

figure
plot(t1, yMPC(1, :), 'r')
hold on
plot(t1, yAdapt(1, :), 'b')
grid on

stairs([0, Time_out], [main_bounds(1), main_bounds(1)], 'k')
stairs([0, Time_out], [-main_bounds(1), -main_bounds(1)], 'k')

title('Cart Position Adaptive vs MPC')
xlabel('Time/s')
ylabel('Cart Position from Centre')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
plot(t1, yMPC(2, :), 'r')
hold on
plot(t1, yAdapt(2, :), 'b')
grid on
title('Angle phi Adaptive vs MPC')
xlabel('Time/s')
ylabel('Angle phi of Pendulum')

stairs([0, Time_out], [main_bounds(2), main_bounds(2)], 'k')
stairs([0, Time_out], [-main_bounds(2), -main_bounds(2)], 'k')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Subplot of each individual output
figure
subplot(2,2,1)
plot(t1, yAdapt(1, :), 'b')
grid on
hold on
stairs([0, Time_out], [main_bounds(1), main_bounds(1)], 'k')
stairs([0, Time_out], [-main_bounds(1), -main_bounds(1)], 'k')
title('Cart Position Adaptive MPC')
xlabel('Time/s')
ylabel('Cart Position from Centre')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,2,2)
plot(t1, yMPC(1, :), 'r')
grid on
hold on
stairs([0, Time_out], [main_bounds(1), main_bounds(1)], 'k')
stairs([0, Time_out], [-main_bounds(1), -main_bounds(1)], 'k')
title('Cart Position MPC')
xlabel('Time/s')
ylabel('Cart Position from Centre')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,2,3)
plot(t1, yAdapt(2, :), 'b')
grid on
hold on
stairs([0, Time_out], [main_bounds(2), main_bounds(2)], 'k')
stairs([0, Time_out], [-main_bounds(2), -main_bounds(2)], 'k')
title('Angle phi Adaptive')
xlabel('Time/s')
ylabel('Angle phi of Pendulum')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,2,4)
plot(t1, yMPC(2, :), 'r')
grid on
hold on
stairs([0, Time_out], [main_bounds(2), main_bounds(2)], 'k')
stairs([0, Time_out], [-main_bounds(2), -main_bounds(2)], 'k')
title('Angle phi MPC')
xlabel('Time/s')
ylabel('Angle phi of Pendulum')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
figure

plot(t1, yAdapt(1, :), 'b')
grid on
hold on
stairs([0, Time_out], [main_bounds(1), main_bounds(1)], 'k')
stairs([0, Time_out], [-main_bounds(1), -main_bounds(1)], 'k')
title('Cart Position Adaptive MPC')
xlabel('Time/s')
ylabel('Cart Position from Centre')

axis([0 30 -1.5 1.5])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
plot(t1, yMPC(1, :), 'r')
grid on
hold on
stairs([0, Time_out], [main_bounds(1), main_bounds(1)], 'k')
stairs([0, Time_out], [-main_bounds(1), -main_bounds(1)], 'k')
title('Cart Position MPC')
xlabel('Time/s')
ylabel('Cart Position from Centre')

axis([0 30 -1.5 1.5])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
figure

plot(t1, yAdapt(2, :), 'b')
grid on
hold on
stairs([0, Time_out], [main_bounds(2), main_bounds(2)], 'k')
stairs([0, Time_out], [-main_bounds(2), -main_bounds(2)], 'k')
title('Angle phi Adaptive')
xlabel('Time/s')
ylabel('Angle phi of Pendulum')

axis([0 30 -0.5 0.9])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure

plot(t1, yMPC(2, :), 'r')
grid on
hold on
stairs([0, Time_out], [main_bounds(2), main_bounds(2)], 'k')
stairs([0, Time_out], [-main_bounds(2), -main_bounds(2)], 'k')
title('Angle phi MPC')
xlabel('Time/s')
ylabel('Angle phi of Pendulum')

axis([0 30 -0.5 0.9])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%