function [X,cspond,G] = make_cspond_same_Rt(N,w,h)
x = LAF.make_random(N);
t = 0.9*rand(2,N)-0.45;
x1 = translate(x,t);
x2 = do_rigid_xform(x1);
x = reshape([x1;x2],9,[]);
M = [[w 0; 0 h] [0 0]';0 0 1];

X = reshape(M*reshape(x,3,[]),9,[]);

cspond = reshape([1:2*N],2,[]);
G = reshape(repmat([1:N],2,1),1,[]);
          
function x2 = do_rigid_xform(x1)
N = size(x1,2);
theta = repmat(2*pi*rand(1),1,size(x1,2));
n = [cos(theta);sin(theta)];
a = [(-0.5-x1(4,:))./n(1,:);
     (0.5-x1(4,:))./n(1,:); ...
     (-0.5-x1(5,:))./n(2,:);
     (0.5-x1(5,:))./n(2,:)];
[as,ind] = sort(a,1);
l = max(as(2,:));
u = min(as(3,:));
x2 = zeros(size(x1));
t = (u-l)*(0.9*rand(1)+0.1);
A = Rt.params_to_mtx([theta;bsxfun(@times,t,n);ones(1,N)]);
x2 = PT.mtimesx(A,x1);

function v = translate(u,t)
z = zeros(1,size(t,2));
o = ones(1,size(t,2));
A = Rt.params_to_mtx([z;t;o]);
v = PT.mtimesx(A,u);