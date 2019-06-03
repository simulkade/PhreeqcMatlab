% Example 5 of phreeqc; Add 0.0 to 0.05 moles of NaCl and Oxygen and
% equilibrate the solution. The input file is in ex5_input.pqc file

clc
phreeqc_rm = PhreeqcSingleCell('ex5_input.pqc', 'phreeqc.dat');

status = phreeqc_rm.RM_SetFilePrefix('Advect_cpp');
phreeqc_rm.RM_OpenFiles();
phreeqc_rm.RM_SetPrintChemistryOn(true, true, true);

comp_name = phreeqc_rm.GetComponents();
ind_Na = find(contains(comp_name, 'Na'), 1);
ind_Cl = find(contains(comp_name, 'Cl'), 1);
ind_O  = find(contains(comp_name, 'O'), 1);

c = phreeqc_rm.GetConcentrations();
h_out = phreeqc_rm.GetSelectedOutputHeadings(1);

c_Na = [0.0, 0.001, 0.005, 0.01, 0.03, 0.05];
d_CO2 = zeros(length(c_Na),1);
d_calcite = zeros(length(c_Na),1);
d_pyrite = zeros(length(c_Na),1);
d_geothite = zeros(length(c_Na),1);
d_gypsum = zeros(length(c_Na),1);
si_Gypsum = zeros(length(c_Na),1);


for i = 1:length(c_Na)
    c_new = c;
    c_new(ind_Na) = c(ind_Na)+0.5*c_Na(i);
    c_new(ind_Cl) = c(ind_Cl)+0.5*c_Na(i);
    c_new(ind_O)  = c(ind_O)+2*c_Na(i);
    phreeqc_rm.RM_SetConcentrations(c_new);
    phreeqc_rm.RM_RunCells();
    % get the required output:
    so = phreeqc_rm.GetSelectedOutputTable(1);
    d_CO2(i) = so('d_CO2(g)');
    d_calcite(i) = so('d_calcite');
    d_pyrite(i) = so('d_pyrite');
    d_geothite(i) = so('d_goethite');
    d_gypsum(i) = so('d_gypsum');
    si_Gypsum(i) = so('si_Gypsum');
end

yyaxis left
plot(c_Na, -1000*[d_CO2, d_calcite, d_pyrite, d_geothite, d_gypsum]');
yyaxis right
plot(c_Na, si_Gypsum);

phreeqc_rm.RM_CloseFiles();
status = phreeqc_rm.RM_Destroy();

%% Load the phreeqc result
pqc_res = readtable('../phreeqc/ex5.csv');
hold on
yyaxis left
solubility = 1000*[pqc_res.d_CO2_g_, pqc_res.d_calcite, pqc_res.d_pyrite, pqc_res.d_goethite ...
, pqc_res.d_gypsum];
plot(c_Na, solubility(2:end,:), 'o');
yyaxis right
plot(c_Na, pqc_res.si_Gypsum(2:end), 's');
hold off