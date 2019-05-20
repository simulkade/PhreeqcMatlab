function c_out = simple_advect(c, bc_conc, ncomps, nxyz)
    c_out = reshape(c, nxyz, ncomps);
    c_out(2:nxyz/2, :) = c_out(1:nxyz/2-1, :);
%     for i = nxyz/2:-1:1
%         for j = 1:ncomps
%             c_out((j * nxyz + i) = c(j * nxyz + i - 1);
%         end
%     end
    % Cell 0 gets boundary condition
    for j = 1:ncomps
        c_out(1, j) = bc_conc(j);
    end
    c_out = c_out(:);
end

