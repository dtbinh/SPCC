

try load('simple_alg_0.mat')
    
catch  
    multisample_3
    
end

r = 300;

sub_s = x.sample((1 : r),:);

[R, c, no_viol] = min_R_SOCP(sub_s);

data = x.sample;
data(1:r,:) = [];

radii = zeros(1, length(data));

hold off

for i = 1 : length(data)
    fprintf('%d\n',i)
    
    radii(1,i) = R;
    
    poin = data(i,:);
    
    if norm(poin - c) < R
        
        arr = (sub_s - c);
        val = arr.^2;
        val = sum(val, 2);
        
        val = val - R^2;
        val = abs(val);
        
        [~, index] = min(val);
        
        sub_s(index,:) = poin;
      
        [R, c, no_viol] = min_R_SOCP(sub_s);
        
    else 
        fprintf('Outside Hypersphere \n')
    end
    
    t = linspace(0,2*pi);
    
    
    plot(R*cos(t) + c(1,1), R*sin(t) + c(1,2))
    hold on
    plot(sub_s(:,1),sub_s(:,2),'.')

    plot(c(1,1),c(1,2),'+')
    
    plot(poin(1), poin(2), 'x')
    grid on
    axis equal
    
    if i == x.M - r
        break 
    end
    
end

difs = diff(radii);

plot(R*cos(t) + c(1,1), R*sin(t) + c(1,2),'b')
hold on
plot(sub_s(:,1),sub_s(:,2),'.')

plot(c(1,1),c(1,2),'X')

plot(poin(1), poin(2), 'x')
grid on
axis equal

%% new figure
plot(x.sample(:,1), x.sample(:,2),'+')
hold on
plot(R*cos(t) + c(1,1), R*sin(t) + c(1,2), 'k')

plot(sub_s(:,1),sub_s(:,2),'.')

plot(c(1,1),c(1,2),'X')

plot(poin(1), poin(2), 'x')


grid on
axis equal

figure 

plot(x.sample(:,1), x.sample(:,2),'.')
hold on
plot(R*cos(t) + c(1,1), R*sin(t) + c(1,2), 'b')

plot(sub_s(:,1),sub_s(:,2),'.')

plot(c(1,1),c(1,2),'X')

plot(poin(1), poin(2), 'x')


grid on
axis equal

hold off
%%
% 
% [R, c, no_viol] = min_R_SOCP(sub_s);
% 
% figure 
% 
% plot(x.sample(:,1), x.sample(:,2),'+')
% hold on
% plot(R*cos(t) + c(1,1), R*sin(t) + c(1,2),'b')
% 
% plot(sub_s(:,1),sub_s(:,2),'.')
% 
% plot(c(1,1),c(1,2),'X')
% 
% plot(poin(1), poin(2), 'x')
% 
% 
% grid on
% axis equal
% 
% hold off
