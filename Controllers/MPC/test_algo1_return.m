%% test 

M = 1000;

x = struct;
x.sample = randn(1, M);

[x_hat, q_hat] = algo1_return(x, 6, 90, 99);

%%
figure
plot(x.sample,'.')
hold on
plot([1, M], [x_hat(2, 1), x_hat(2, 1)])
hold on
plot([1, M], [-x_hat(2, 1), -x_hat(2, 1)])
