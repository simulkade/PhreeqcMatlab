classdef Surface
    %SURFACE defines a surface species that can be equilibrated with a
    %solution object. Each surface object should contain only one surface
    %(with or without different types)
    
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        mass(1,1) double
        scm(1,1) string
        site_density(1,:) double
        surface_master_species(:, 1) string
        surface_species_reactions(:, 1) string
        log_k(:,1) double
        dh(:,1) double
        specific_surface_area(1,1) double {mustBeNonnegative}
        sites_units(1,1) string   % absolute or density
        edl_model(1,1) string
        edl_thickness {mustBeScalarOrEmpty}
        only_counter_ions(1,1) logical
        capacitances(1,2) double
        cd_music_coeffs(:,:) double
    end
    
    methods
        function obj = Surface()
            %SURFACE Construct an instance of this class
            obj.name = "surface";
            obj.number = 1;
        end
        
        function [surface_string, surface_master_string, surface_species_string] = phreeqc_string(obj)
            % phreeqc_string returns a string in phreeqc format based on
            % the defined surface object. It does not run without mixing
            % with a solution object
            % There might be bugs in the conversion and more tests need to
            % be written
            % TBD: currently, surfaces that are linked to and equilibrium
            % or kinetic phases must be defined manually; they are only
            % important is a substantial amount of the surface dissolves or
            % precipitate. For, e.g. flow in a chalk reservoir, it is not
            % significant
            surface_master_string = "SURFACE_MASTER_SPECIES \n";
            for i = 1:length(obj.surface_master_species)
                surface_master_string = strjoin([surface_master_string obj.surface_master_species(i) "\n"]);
            end
            surface_master_string = sprintf(char(surface_master_string));

            surface_species_string = "SURFACE_SPECIES \n";
            for i = 1:length(obj.surface_species_reactions)
                surface_species_string = strjoin([surface_species_string obj.surface_species_reactions(i) "\n log_k" num2str(obj.log_k(i)) "\n delta_h" num2str(obj.dh(i)) "\n"]);
                if strcmpi(obj.scm, 'cd_music')
                    surface_species_string = strjoin([surface_species_string "-cd_music" num2str(obj.cd_music_coeffs(i,:)) "\n"]);
                end
            end
            surface_species_string = sprintf(char(surface_species_string));

            surface_string = ["SURFACE" num2str(obj.number) obj.name "\n"];
            if strcmpi(obj.scm, 'cd_music')
                surface_string = strjoin([surface_string "-cd_music \n"]);
            end
            if strcmpi(obj.sites_units, 'absolute')
                surface_string = strjoin([surface_string "-sites_units absolute \n"]);
            else
                surface_string = strjoin([surface_string "-sites_units density \n"]);
            end
            ms = strsplit(obj.surface_master_species(1), ' ');
            surface_string = strjoin([surface_string ms(1) num2str(obj.site_density(1)) num2str(obj.specific_surface_area) num2str(obj.mass) "\n"]);
            for i = 2:length(obj.surface_master_species)
                ms = strsplit(obj.surface_master_species(i), ' ');
                surface_string = strjoin([surface_string ms(1) num2str(obj.site_density(i)) "\n"]);
            end
            if strcmpi(obj.scm, 'cd_music')
                surface_string = strjoin([surface_string "-capacitances " num2str(obj.capacitances) "\n"]);
            end
            if strcmpi(obj.edl_model, 'diffuse_layer')
                surface_string = strjoin([surface_string "-diffuse_layer " num2str(obj.edl_thickness) "\n"]);
            elseif strcmpi(obj.edl_model, 'Donnan') || strcmpi(obj.edl_model, 'Donan')
                surface_string = strjoin([surface_string "-Donnan " num2str(obj.edl_thickness) "\n"]);
            elseif strcmpi(obj.edl_model, 'no_edl')
                surface_string = strjoin([surface_string "-no_edl \n"]);
            end
            if obj.only_counter_ions
                surface_string = strjoin([surface_string "-only_counter_ions true \n"]);
            end
            surface_string = sprintf(char(surface_string));
        end

        function [all_string, solution_string, surf_string, dl_string] = selected_output_string(obj, solution, varargin)
            % so_string = surf_selected_output(obj, solution, varargin)
            % the last argument is an optional database file that must be
            % in the database folder
            % returns a selected output string that can be appended to the
            % current phreeqc string of the surface object to obtain most of
            % the physical and chemical properties calculated by phreeqc
            % for a surface in equilibrium with a solution
            % a solution must be specified since some of the selected output lines
            % are constructed after running a Phreeqc equilibration
            % note that the new string must be called followed by the
            % RM_RunCells to obtain the selected output values
            % step 1: run the equilibration
            phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread
            phreeqc_rm = phreeqc_rm.RM_Create(); % create a PhreeqcRM instance
            if nargin>2
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
            % run phreeqc string in phreeqcRM
            iph_string = obj.combine_surface_solution_string(solution);
            phreeqc_rm.RM_LoadDatabase(database_file(data_file));
            phreeqc_rm.RM_RunString(true, true, true, iph_string);
            phreeqc_rm.RM_FindComponents(); % always run it first
            element_names = phreeqc_rm.GetComponents();
            % surf_sp_name = phreeqc_rm.GetSurfaceSpeciesNames();
            surf_type = phreeqc_rm.GetSurfaceTypes();
            b = split(surf_type{1}, '_');
            surf_name = strjoin(b(1:end-1), '_');
            sur_sp_list = strjoin(phreeqc_rm.GetSurfaceSpeciesNames());
            ind_charge = find(strcmpi(element_names, 'Charge'));
            surf_call = strjoin(cellfun(@(x)(['SURF("' x '","' surf_name '")']), element_names(ind_charge+1:end), 'UniformOutput', false));
            edl_special = [{'Charge'}; {'Charge1'}; {'Charge2'}; {'sigma'}; {'sigma1'}; {'sigma2'}; {'psi'}; {'psi1'}; {'psi2'}; {'water'}];
            edl_in = [element_names(ind_charge+1:end); edl_special];
            edl_call = strjoin(cellfun(@(x)(['EDL("' x '","' surf_name '")']), edl_in, 'UniformOutput', false));
            
            % we create three different selected output blocks
            % sol_string that is the solution properties
            % surf_string that is the surface properties and composition
            % dl_string that is the composition of the double layer
            % 1- Solution selected output
            solution_string = solution.selected_output_string();
            % 2- surface selected output
            surf_string = strjoin(["\nSELECTED_OUTPUT" num2str(solution.number+1) "\n"]);
            surf_string = strjoin([surf_string  "-reset false\n"]);
            surf_string = strjoin([surf_string "-molalities" sur_sp_list "\n"]);
            surf_string = strjoin([surf_string  "USER_PUNCH" num2str(solution.number+1) "\n"]);
            surf_string = strjoin([surf_string  "-headings "  element_names(ind_charge+1:end)' "\n"]);
            surf_string = strjoin([surf_string  "10 PUNCH" surf_call "\n"]);
            surf_string = strjoin([surf_string  "END"]);
            % 3- DL selected output
            dl_string = strjoin(["\nSELECTED_OUTPUT" num2str(solution.number+2) "\n"]);
            dl_string = strjoin([dl_string  "-reset false\n"]);
            dl_string = strjoin([dl_string  "USER_PUNCH"  num2str(solution.number+2) "\n"]);
            dl_string = strjoin([dl_string  "-headings "  edl_in' "\n"]);
            dl_string = strjoin([dl_string  "10 PUNCH" edl_call "\n"]);
            dl_string = strjoin([dl_string  "END"]);
            dl_string = sprintf(char(dl_string));
            % combined strings:
            all_string = sprintf(char([solution_string surf_string dl_string]));
        end
    
        function out_string = equilibrate_in_phreeqc(obj, solution, varargin)
            % function output_string = equilibrate_in_phreeqc(obj, solution_object, [databasename], [sel_output_string])
            % The function equilibrates a solution defined as a Solution class
            % the procedure is relatively simple. A phreeqc string is created for both 
            % surface and solution, and the combined string is run in IPhreeqc
            % Note that the latest version of IPhreeqc crashes Matlab; therefore,
            % IPhreeqc 3.7 is called within this function
            % both databasename and sel_output_string are optional
            % parameters
            iph_string = obj.combine_surface_solution_string(solution);
            iph = IPhreeqc(); % load the library
            iph = iph.CreateIPhreeqc(); % create an IPhreeqc instance
            if nargin>2
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
            try
                out_string = iph.RunPhreeqcString(iph_string, database_file(data_file));
                iph.DestroyIPhreeqc();
            catch
                out_string = 0;
                disp('An error occured running Phreeqc. Please check the solution and surface definition');
                iph.DestroyIPhreeqc();
            end
        end

        function [surface_result, solution_result] = equilibrate_with(obj, solution, varargin)
            % function output_string = equilibrate_with(obj, solution_object)
            % The function equilibrates a solution defined as a Solution class
            % the procedure is relatively simple. A phreeqc string is created for both 
            % surface and solution, and the combined string is run in PhreeqcRM
            % I have some problems with IPhreeqc on Windows machines, which is something I will 
            % fix later (if possible, and not a priority)
            phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread
            iph_string = obj.combine_surface_solution_string(solution);
            so_string = obj.selected_output_string(solution, varargin{end});
            all_string = combine_phreeqc_strings(iph_string, so_string);
            if nargin>2
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
            phreeqc_rm.RM_LoadDatabase(database_file(data_file));
            phreeqc_rm.RM_RunString(true, true, true, all_string);
            phreeqc_rm.RM_FindComponents(); % always run it first
            % initialize phreeqcRM
            phreeqc_rm.RM_SetSelectedOutputOn(true);
            phreeqc_rm.RM_SetComponentH2O(true);
            phreeqc_rm.RM_SetUnitsSolution(2);
            phreeqc_rm.RM_SetSpeciesSaveOn(ture);
            ic1 = -1*ones(7, 1);
            ic2 = -1*ones(7, 1);
            % 1 solution, 2 eq phase, 3 exchange, 4 surface, 5 gas, 6 solid solution, 7 kinetic
            f1 = ones(7, 1);
            ic1(1) = solution.number;              % Solution seawater
            ic1(4) = obj.number;         % Surface calcite
            phreeqc_rm.RM_InitialPhreeqc2Module(ic1, ic2, f1);
            phreeqc_rm.RM_RunCells();
            t_out1 = phreeqc_rm.GetSelectedOutputTable(obj.number);
            t_out2 = phreeqc_rm.GetSelectedOutputTable(obj.number+1);
            t_out3 = phreeqc_rm.GetSelectedOutputTable(obj.number+2);
            v_out= phreeqc_rm.GetSelectedOutput(obj.number)
            h_out = phreeqc_rm.GetSelectedOutputHeadings(obj.number)

            % prepare the output
            solution_result = solution.results_from_phreeqcrm(phreeqc_rm);
            % TBD
        end

        function out_string = combine_surface_solution_string(obj, solution)
            % combines the phreeqc string of a solution and a surface to be equilibrated with each other
            sol_string = solution.phreeqc_string();
            [surf_string, surf_master_string, surf_sp_string] = obj.phreeqc_string();
            out_string = strjoin([surf_master_string, surf_sp_string, sol_string, surf_string, "-equilibrate ", num2str(solution.number), "\nEND"]);
            out_string = sprintf(char(out_string));
        end
    end

    methods(Static)
        function obj = calcite_surface()
            s=fileread(database_file('surfaces.json'));
            d = jsondecode(s);
            obj = Surface();
            obj = obj.read_json(d.Surface.Chalk_DLM);
        end

        function obj = calcite_surface_cd_music()
            s=fileread(database_file('surfaces.json'));
            d = jsondecode(s);
            obj = Surface();
            obj = obj.read_json(d.Surface.Chalk_CD_MUSIC);
        end
        
        function obj = clay_surface()
            obj = Surface();
            % TBD
        end

        function obj = oil_surface()
            s=fileread(database_file('surfaces.json'));
            d = jsondecode(s);
            obj = Surface();
            obj = obj.read_json(d.Surface.Oil_DLM);
        end        

        function [surface_string, surface_master_string, surface_species_string] = ...
                combine_surfaces(surf1, surf2, new_name, new_number)
            % mixes two surface definitions and creates a phreeqc string
            % that contains both surfaces as a single SURFACE block
            % NOTE: only surfaces with the same model can be combined
            if strcmpi(surf1.scm, surf2.scm)
                % TBD
                [st1, sms1, sss1] = surf1.phreeqc_string();
                [~, sms2, sss2] = surf2.phreeqc_string();
                sms1 = split(sms1, '\n');
                sms2 = split(sms2, '\n');
                surface_master_string = strjoin([sms1, sms2(2:end)], '\n');

                sss1 = split(sss1, '\n');
                sss2 = split(sss2, '\n');
                surface_species_string = strjoin([sss1, sss2(2:end)], '\n');
                
                st1 = split(st1, '\n');
                st1(1) = ["SURFACE" num2str(new_number) new_name "\n"];
                surface_string = strjoin(st1, '\n');
                ms = strsplit(surf2.surface_master_species(1), ' ');
                surface_string = strjoin([surface_string ms(1) num2str(surf2.site_density(1)) num2str(surf2.specific_surface_area) num2str(surf2.mass) "\n"]);
                for i = 2:length(surf2.surface_master_species)
                    ms = strsplit(surf2.surface_master_species(i), ' ');
                    surface_string = strjoin([surface_string ms(1) num2str(surf2.site_density(i)) "\n"]);
                end
            else
                error('Input surfaces use different models and cannot be combined!')
            end
        end

        function obj = read_json(surf_struct)
            % read_json creates a Solution object from a decoded JSON
            % string
            % input:
            %       sol: decoded JSON string to a Matlab structure
            obj = Surface();

            if isfield(surf_struct, 'Name')
                obj.name = surf_struct.Name;
            end

            if isfield(surf_struct, 'Number')
                obj.number = surf_struct.Number;
            end

            if isfield(surf_struct, 'Mass')
                obj.mass = surf_struct.Mass;
            end

            if isfield(surf_struct, 'SCM')
                obj.scm = surf_struct.SCM;
            end

            if isfield(surf_struct, 'SpecificArea')
                obj.specific_surface_area = surf_struct.SpecificArea;
            end

            if isfield(surf_struct, 'MasterSpecies')
                f_names = fieldnames(surf_struct.MasterSpecies); % get the list of components
                s = string(zeros(1, length(f_names)));
                site_dens = zeros(1, length(f_names));
                ms = cellfun(@(x)strjoin(string(getfield(surf_struct.MasterSpecies, x, 'Species'))), fieldnames(surf_struct.MasterSpecies), 'UniformOutput', false);
                sd = cellfun(@(x)getfield(surf_struct.MasterSpecies, x, 'SiteDensity'), fieldnames(surf_struct.MasterSpecies), 'UniformOutput', false);
                s(:) = ms(:);
                site_dens(:) = cell2mat(sd(:));
                obj.surface_master_species = s;
                obj.site_density = site_dens;
                % TBD site_density
            end

            if isfield(surf_struct, 'Reactions')
                f_names = fieldnames(surf_struct.Reactions); % get the list of components
                s = string(zeros(1, length(f_names)));
                dh_val = zeros(1, length(f_names));
                k = zeros(1, length(f_names));
                cdm = zeros(1, length(f_names));
                ms = cellfun(@(x)string(getfield(surf_struct.Reactions, x, 'Reaction')), f_names, 'UniformOutput', false);
                k_cell = cellfun(@(x)getfield(surf_struct.Reactions, x, 'logK'), f_names, 'UniformOutput', false);
                k(:) = cell2mat(k_cell(:));
                try
                    dh_cell = cellfun(@(x)getfield(surf_struct.Reactions, x, 'DeltaH'), f_names, 'UniformOutput', false);
                    dh_val(:) = cell2mat(dh_cell(:));
                catch
                    warning('Values for the enthalpy of surface complexation reactions are not specified; assumed zero.')
                end
                try
                    if strcmpi(obj.scm, 'cd_music')
                        cdm_cell = cellfun(@(x)getfield(surf_struct.Reactions, x, 'cd_music')', f_names, 'UniformOutput', false);
                        cdm = cell2mat(cdm_cell);
                    end
                catch
                    warning('CD MUSIC model coefficients are not assigned.')
                end
                s(:) = ms(:);
                obj.surface_species_reactions = s;
                obj.log_k = k;
                obj.dh = dh_val;
                obj.cd_music_coeffs = cdm;
            end

            if isfield(surf_struct, 'SitesUnits')
                obj.sites_units = surf_struct.SitesUnits;
            end

            if isfield(surf_struct, 'EDL')
                obj.edl_model = surf_struct.EDL;
            end

            if isfield(surf_struct, 'EDL_thickness')
                obj.edl_thickness = surf_struct.EDL_thickness;
            else
                obj.edl_thickness = 1e-8;
            end

            if isfield(surf_struct, 'only_counter_ions')
                obj.only_counter_ions = surf_struct.only_counter_ions;
            else
                obj.only_counter_ions = false;
            end

            if isfield(surf_struct, 'Capacitances')
                obj.capacitances = surf_struct.Capacitances;
            end
        end
    end
end

