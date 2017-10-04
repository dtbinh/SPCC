%% MPI test Gurobi software
%
% maximise: 
%           x + y + 2*z 
% subject to: 
%           x + 2*y + 3*z =< 4
%           x + y         >= 1

names = {'x', 'y', 'z'};

try
    clear model;
    model.A = sparse([1 2 3; 1 1 0]);
    model.obj = [1 1 2];
    model.rhs = [4; 1];
    model.sense = '<>';
    model.vtype = 'B';
    model.modelsense = 'max';
    model.varnames = names;

    gurobi_write(model, 'mip1.lp');

    clear params;
    params.outputflag = 0;

    result = gurobi(model, params);

    disp(result)

    for v=1:length(names)
        fprintf('%s %d\n', names{v}, result.x(v));
    end

    fprintf('Obj: %e\n', result.objval);

catch gurobiErrorS
    fprintf('Error reported\n');
end