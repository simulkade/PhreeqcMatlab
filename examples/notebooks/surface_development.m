% Codes for the development of the SCM models. This script demonstrate the
% capabilities of the Surface object code. It is used in the development of
% the objects so it can become out of date. Look into other folders for
% more updated examples.

%% Equilibrate a solution with a solid surface
% Here, we use the predefined solutions and surfaces in PhreeqcMatlab
% define a solution 
seawater = Solution.seawater()

% Define a surface
calcite = Surface.calcite_surface_cd_music()

% equilibrate calcite with seawater
calcite.equilibrate_in_phreeqc(seawater)

%% Equilibrate in PhreeqcRM with accessible selected output values (IPhreeqc)
% create a selected output string for the seawater + calcite system
[sel_out_str, sol_str, surf_str, dl_str] = calcite.selected_output_string(seawater);
eq_string = calcite.combine_surface_solution_string(seawater);
% First, equilibrate calcite and seawater in Phreeqc with a selected output
% TBD, currently only doable by parsing the whole string in IPhreeqc
iph = IPhreeqc(); % load the library
iph = iph.CreateIPhreeqc(); % create an IPhreeqc instance
out_string = iph.RunPhreeqcString([eq_string(1:end-4) sel_out_str], database_file('phreeqc.dat'));
disp(out_string)

% The above code does not do anything because no output file is specified
% in the selected output block. It is possible to read the selected output
% values using the IPhreeqc instance (before destroying it).
% TBD: add the possibility of adding a file name to the selected output
% string. The current IPhreeqc helper functions can read output values and
% headers by providing the selected output block number. 
sel_out_id = 3; % can be 1, 2, or 3
% 1: Solution properties
% 2: Surface species composition
% 3: Double layer composition and charge/potential
[h,v] = iph.GetSelectedOutputTable(sel_out_id); 
iph.DestroyIPhreeqc();

%% Equilibrate in a cell (PhreeqcRM)
% The other way of equilibrating seawater with calcite is by defining a
% cell in PhreeqcRM. This is the preffered way of defining mixtures since
% the wrapper is easier to call and does not require string manipulation
% for, e.g., case studies.
% There are two ways of calling PhreeqcRM to equilibrate a mixture of brine
% and solid surface: the more convenient but rather limited method is by
% calling 'equilibrate_with' method of the Surface class, which simply
% equilibrates a surface with the specified Solution object:
[surf_res, sol_res] = calcite.equilibrate_with(seawater)

% The preferred method is the definition of a single cell, which
% automatically creates the relevant objects from a [modified] Phreeqc
% input files and sets up the PhreeqcRM object for case studies and
% sensitivity analyses.