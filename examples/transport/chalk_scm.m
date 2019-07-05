[phreeqc_rm, c_x_t] = PhreeqcAdvection('chalk_scm_input.pqc' , 'chalk_scm_matlab.pqm');
plot(squeeze(c_x_t(end, 4:end, :))'); % plot the concentrations at the outlet
comps = phreeqc_rm.GetComponents();
legend(comps{4:end});
phreeqc_rm.RM_Destroy();