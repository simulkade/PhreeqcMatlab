% run example 11 of phreeqc in PhreeqcMatlab
[phreeqc_rm, c_x_t] = PhreeqcAdvection('ex11_simple_input.pqc' , 'ex11_simple_phreeqc_matlab.pqm');
plot(squeeze(c_x_t(:, 4:end, end))); % plot the concentrations at the outlet
comps = phreeqc_rm.GetComponents();
legend(comps{4:end});