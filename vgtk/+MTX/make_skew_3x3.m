%
%  Copyright (c) 2018 James Pritts
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts
%
function S = mtx_make_skew_3x3(e1)
S = [  0   -e1(3)  e1(2); ...
     e1(3)    0   -e1(1); ...
    -e1(2)  e1(1)   0];