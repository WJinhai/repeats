function invK = mtx_inv_K(K);
invK = [1/K(1,1)   0       -K(1,3)/K(1,1); ...
        0     1/K(2,2)  -K(2,3)/K(2,2); ...
        0       0              1];