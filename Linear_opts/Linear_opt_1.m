%% Linear Optimisation with Chance Constraints
% Moving plane problem


%% Gaussian distribution Samples and Subsamples
% generate a sample of N constraints fromt this m samples will be selected

N = 1000;  % number of global samples

P = [0 , 0]';           % defines the mean Point for the Gaussian

D = randn(2,N) + P;         % generates 2 by N Gaussian distributed number with mean at P
D = abs(D);             % keeps only positive numbers

m = 100;                % subset of samples
if m >= N
    error('m is the size of the subset of N: it must be small than N')
end

D1 = D(:,1:m);        % first subset

%% Define plane

c = [1 1]';             % the normal that defines the plane

d1 = c'*D1;             % vector: all distances from samples to plane

[dmax1,I1] = max(d1);        % greatest distance from plane which intersects a sample to origin, and index

x_d1 = D1(:,I1);        % finds the point that intersects normal which is furthest from origin

Plane_grad1 = -c(1) / c(2);     % finds the gradient of line of the plane

plane_Y_intercept = x_d1(2) - Plane_grad1*x_d1(1);          % find x and y intersepts for plotting purposes
plane_X_intercept = -plane_Y_intercept / Plane_grad1;       % find x and y intersepts for plotting purposes

plane = [0 plane_X_intercept  ; plane_Y_intercept  0];      % two points to plot plane

%% Violation Function

% find the number of points that are outside the plane

d = c'*D;           % perpendicular distances of all the points from the full sample N

eta_1 = d(d >= dmax1);      % all values from the greater set that Violate sub-sample

Probab_eta_1 = length(eta_1) / N;           % Probability eta
One_Minus_eta = 1 - Probab_eta_1;           % violation probability 1 - eta

violate_index_1 = find(d >= dmax1);
violate_1 = D(:,violate_index_1);



%% Plots figures necessary

figure

subplot(1,2,1)
axis square
plot(D(1,:),D(2,:),'.')         % plots Largest set of random samples
hold on 
plot(plane(1,:),plane(2,:),'r')
hold off

subplot(1,2,2)
axis square

plot(D1(1,:),D1(2,:),'.')         % plots Largest set of random samples
hold on 
plot(plane(1,:),plane(2,:),'r')

plot(violate_1(1,:),violate_1(2,:),'.')

hold off





