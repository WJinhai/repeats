function [J,labels] = msac_objective_fn(C,u,s,cfg)
C2 = sum(C.^2);
labels = C2/cfg.tsq < 1;

T = cfg.tsq*9/4;
z = C2/T;
z(z>1) = 1;
J = sum(z);