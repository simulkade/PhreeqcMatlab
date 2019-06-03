% a simple phreeqc example that plays with solution concentration
% adapted from phreeqc ex2 file. Change the temperature and observe its
% effect on the solubility of two minerals
% This is similar to ex2.m, but more concise since here I use
% PhreeqcSingleCell utility function to create and initialize the phreeqcrm object.
clc
phreeqc_rm = PhreeqcSingleCell('ex2_input.pqc', 'phreeqc.dat');

n_data = 51;

h_out = phreeqc_rm.GetSelectedOutputHeadings(1);

temperature = linspace(25.0, 75.0, n_data); % degree C

s_out = zeros(n_data, length(h_out));

for i = 1:length(temperature)
    phreeqc_rm.RM_SetTemperature(temperature(i));

    status = phreeqc_rm.RM_RunCells();
    c_out = phreeqc_rm.GetConcentrations();

    s_out(i, :) = phreeqc_rm.GetSelectedOutput(1);
end
plot(temperature, s_out, '-s');
legend(string(h_out));
xlabel('T (C)');
ylabel('SI');

% M = phreeqc_rm.GetSelectedOutputTable(1);

status = phreeqc_rm.RM_Destroy();


