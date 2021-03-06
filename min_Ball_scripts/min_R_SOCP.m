function [R, c, no_violate] = min_R_SOCP(x, params)
%Solves minimum radius SOCP problem using Gurobi interior point sovler.
%This set up as a SOCP with cone constraints.
%
% min:   R
% s.t. || x_i - c ||_2 <= R 
% input Args:
%       Arg 1: x: the distribution that is required to be be placed 
%              within a ball 
%              The number of samples is the same as number of rows
%              Dimension of the samples is number of columns
%
%       Arg 2: params: this is a struct containing gurobi
%              parameters e.g. params.outflag = 0
%     Returns: 
%               R = radius of ball
%               c = centre of ball 

if nargin == 1
    
    clear params
    params.outputflag = 0;
    params.Timelimit = 60;    
    
end

[N_samp, dim_x] = size(x); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assert(dim_x < N_samp, 'Number of Rows = Number of Samples || Number of Columns = Dimension of Samples')
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% begin with the zeros to delete the scalar R
A_mat = zeros( N_samp*dim_x, 1 );
% Add in the repeated Identity_matrix(dim_x) matrices 
A_mat = [A_mat, repmat( eye(dim_x), N_samp, 1)];
% add in the final 
A_mat = [A_mat, eye( dim_x*N_samp )];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

b_mat = reshape(x, dim_x*N_samp ,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check that no. of columns of A_mat and b_mat are the same:
row_A = size(A_mat);
% number of columns of A_mat which is the length of X
len_X = row_A(1,2);

row_A = row_A(1,1);

row_b = size(b_mat);
row_b = row_b(1,1);

assert(row_A == row_b, 'The number of rows of A_mat and b_mat are not equal')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% conical constraints: 
% these are for Gurobi: http://www.gurobi.com/documentation/7.5/refman/matlab_gurobi.html
% each element in the array is a cone constraint
% cones(j).index = [k, idx] :
% x(k)^2 >= sum(x(idx).^2), x(k) >= 0
%  R ^ 2 >= sum(Xv(idx).^2), R >= 0 
%  R ^ 2 >= ||w_j - c||^2,     R >= 0

% Preallocate cones as an empty list
cones = []*N_samp;

% Looks for the indices of X for Xv which is the data points
for i = 1 : N_samp
    cones(i).index = [ 1, (dim_x + 1) + (dim_x)*( i - 1 ) + (1 : dim_x ) ];  
end

%% Try to make the Gurobi model

clear model;
% Model upper bound
up_bound = 1e8;

% A: Linear Sparse Matrix  
model.A = sparse(A_mat);
model.rhs = b_mat;
model.cones = cones;
% model.obj: defines f'*X = R 
model.obj = [1; zeros( (len_X - 1), 1 )];
model.sense = '=';
model.vtype = 'C';
model.ub = (up_bound)*ones(len_X,1);
model.lb = - model.ub;

gurobi_write(model, 'min_R_SOCP_1.lp');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

result = gurobi(model, params);

R = result.x(1);
c = result.x(1 + (1:dim_x));

c = c';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('Finished\n')

%% Count how many points are violate the above constraint

centre_points = x - c;
centre_points_sq = centre_points.^2;

sum_vects = sum(centre_points_sq, 2);

R_sqd = R^2;

logics = sum_vects > R_sqd;

one_mat = ones( length( logics ), 1);

no_violate = logics' * one_mat;

if nargin > 2
    fprintf('The number of points that violate are %d. \n', no_violate )
end

%% This part is in the Try statement: it plots the Circle and the points of interest
% t = linspace(0,2*pi);
% hold on
% axis equal
% 
% plot(R*cos(t) + c(1,1), R*sin(t) + c(1,2),'r')
% plot(x(:,1),x(:,2),'.')
% 
% plot(c(1,1),c(1,2),'+')

end