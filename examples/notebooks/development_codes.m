%% let's see if things work fine:
% create a seawater solution
sw = Solution.seawater;
% sw.run;
% or try sw.run_in_phreeqc; both must work and create 
% a report on seawater composition
% create a calcite surface
calcite = Surface.calcite_surface_cd_music;
calcite.mass = 10.0;

calcite.edl_thickness = [];
% Combine the surfaces as a string and run in PhreeqcRM
iph_string = calcite.combine_surface_solution_string(sw)

%% running in phreeqcrm
phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread
phreeqc_rm = phreeqc_rm.RM_Create();
data_file = 'phreeqc.dat';
phreeqc_rm.RM_LoadDatabase(database_file(data_file));
phreeqc_rm.RM_SetSelectedOutputOn(true);
phreeqc_rm.RM_RunString(true, true, true, iph_string);
phreeqc_rm.RM_FindComponents() % always run it first

%% creating selected output for surfaces
element_names = phreeqc_rm.GetComponents()
surf_sp_name = phreeqc_rm.GetSurfaceSpeciesNames()
surf_type = phreeqc_rm.GetSurfaceTypes()
b = split(surf_type{1}, '_');
surf_name = strjoin(b(1:end-1), '_')
sur_sp_list = strjoin(phreeqc_rm.GetSurfaceSpeciesNames())
% a = 'chalk_fast_a';
% b = split(a, '_');
% strjoin(b(1:end-1), '_')
sur_sp_list = strjoin(phreeqc_rm.GetSurfaceSpeciesNames())
% element_names(4:end)
ind_charge = find(strcmpi(element_names, 'Charge'));
surf_call = strjoin(cellfun(@(x)(['SURF("' x '","' surf_name '")']), element_names(ind_charge+1:end), 'UniformOutput', false))
edl_special = [{'Charge'}; {'Charge1'}; {'Charge2'}; {'sigma'}; {'sigma1'}; {'sigma2'}; {'psi'}; {'psi1'}; {'psi2'}; {'water'}]
edl_in = [element_names(ind_charge+1:end); edl_special]
edl_call = strjoin(cellfun(@(x)(['EDL("' x '","' surf_name '")']), edl_in, 'UniformOutput', false))
% TODO: try with EDL_SPECIES as well
% https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-61.htm#50593797_44206

%% the string
solution_so = sw.selected_output_string();

so_string = strjoin(["\nSELECTED_OUTPUT" num2str(sw.number+1) "\n"]);
so_string = strjoin([so_string  "-reset false\n"]);
so_string = strjoin([so_string "-molalities" sur_sp_list "\n"]);
so_string = strjoin([so_string  "USER_PUNCH" num2str(sw.number+1) "\n"]);
so_string = strjoin([so_string  "-headings "  element_names(ind_charge+1:end)' "\n"]);
so_string = strjoin([so_string  "10 PUNCH" surf_call "\n"]);
so_string = strjoin([so_string  "END"]);

dl_string = strjoin(["\nSELECTED_OUTPUT" num2str(sw.number+2) "\n"]);
dl_string = strjoin([dl_string  "-reset false\n"]);
dl_string = strjoin([dl_string  "USER_PUNCH"  num2str(sw.number+2) "\n"]);
dl_string = strjoin([dl_string  "-headings "  edl_in' "\n"]);
dl_string = strjoin([dl_string  "10 PUNCH" edl_call "\n"]);
dl_string = strjoin([dl_string  "END"]);
dl_string = sprintf(char(dl_string));
new_string = sprintf(char([iph_string "\n" solution_so so_string dl_string]))

%% run and destroy
phreeqc_rm.RM_RunString(true, true, true, new_string);
phreeqc_rm.RM_FindComponents(); % always run it first
phreeqc_rm.RM_SetSelectedOutputOn(true);
phreeqc_rm.RM_SetComponentH2O(true);
phreeqc_rm.RM_SetUnitsSolution(2);
phreeqc_rm.RM_SetSpeciesSaveOn(true);
ic1 = -1*ones(7, 1);
ic2 = -1*ones(7, 1);
% 1 solution, 2 eq phase, 3 exchange, 4 surface, 5 gas, 6 solid solution, 7 kinetic
f1 = ones(7, 1);
ic1(1) = sw.number;              % Solution seawater
ic1(4) = calcite.number;         % Surface calcite
phreeqc_rm.RM_InitialPhreeqc2Module(ic1, ic2, f1);
phreeqc_rm.RM_RunCells();
t_out1 = phreeqc_rm.GetSelectedOutputTable(calcite.number);
t_out2 = phreeqc_rm.GetSelectedOutputTable(calcite.number+1);
t_out3 = phreeqc_rm.GetSelectedOutputTable(calcite.number+2);
v_out= phreeqc_rm.GetSelectedOutput(calcite.number)
h_out = phreeqc_rm.GetSelectedOutputHeadings(calcite.number)
% phreeqc_rm.RM_Destroy()
