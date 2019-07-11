function c_new = SimpleAdvection1D(c, cb)
%SIMPLEADVECTION1D shifts the cells in c to the right.
% Input:
%       c: array of length (nxyz, n_comp)
%       cb: left boundary condition (1, n_comp)
c_new = c;
c_new(1, :) = cb;
c_new(2:end, :) = c(1:end-1, :);
end

