classdef Surface < Reactant
    %SURFACE defines a surface species that can be equilibrated with a
    %solution object. Each surface object should contain only one surface
    %(with or without different types)

    properties
        % name, number inherited from Reactant
        mass(1,1) double
        scm(1,1) string
        site_density(:,1) double
        surface_master_species(:, 1) string
        surface_species_reactions(:, 1) string
        log_k(:,1) double
        dh(:,1) double
        specific_surface_area(1,1) double {mustBeNonnegative}
        sites_units(1,1) string   % absolute or density
        edl_model(1,1) string
        edl_thickness {mustBeScalarOrEmpty}
        only_counter_ions(1,1) logical
        capacitances(:,1) double
        cd_music_coeffs(:,:) double
    end
    
    methods
        function obj = Surface()
            %SURFACE Construct an instance of this class
            obj.name = "surface";
            obj.number = 1;
        end

        function str = input_string(obj)
            %INPUT_STRING assemble the three surface blocks into one string,
            % ordered SURFACE_MASTER_SPECIES, SURFACE_SPECIES, then SURFACE.
            [surface_string, surface_master_string, surface_species_string] = obj.phreeqc_string();
            str = char(strjoin([string(surface_master_string) ...
                string(surface_species_string) string(surface_string)], newline));
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
            % SURFACE_MASTER_SPECIES block
            bm = PhreeqcBlock("SURFACE_MASTER_SPECIES");
            for i = 1:numel(obj.surface_master_species)
                bm = bm.line(obj.surface_master_species(i));
            end
            surface_master_string = bm.char();

            % SURFACE_SPECIES block
            bs = PhreeqcBlock("SURFACE_SPECIES");
            for i = 1:numel(obj.surface_species_reactions)
                bs = bs.line(obj.surface_species_reactions(i));
                bs = bs.kv("log_k", obj.log_k(i));
                bs = bs.kv("delta_h", obj.dh(i));
                if strcmpi(obj.scm, 'cd_music')
                    bs = bs.kv("-cd_music", obj.cd_music_coeffs(i,:));
                end
            end
            surface_species_string = bs.char();

            % SURFACE block
            bf = PhreeqcBlock("SURFACE", obj.number, obj.name);
            if strcmpi(obj.scm, 'cd_music')
                bf = bf.flag("-cd_music");
            end
            if strcmpi(obj.sites_units, 'absolute')
                bf = bf.kv("-sites_units", "absolute");
            else
                bf = bf.kv("-sites_units", "density");
            end
            ms = strsplit(obj.surface_master_species(1), ' ');
            bf = bf.kv(ms(1), obj.site_density(1), obj.specific_surface_area, obj.mass);
            for i = 2:numel(obj.surface_master_species)
                ms = strsplit(obj.surface_master_species(i), ' ');
                bf = bf.kv(ms(1), obj.site_density(i));
            end
            if strcmpi(obj.scm, 'cd_music')
                bf = bf.kv("-capacitances", obj.capacitances');
            end
            if strcmpi(obj.edl_model, 'diffuse_layer')
                bf = bf.kvopt("-diffuse_layer", obj.edl_thickness);
            elseif strcmpi(obj.edl_model, 'Donnan') || strcmpi(obj.edl_model, 'Donan')
                bf = bf.kvopt("-Donnan", obj.edl_thickness);
            elseif strcmpi(obj.edl_model, 'no_edl')
                bf = bf.flag("-no_edl");
            end
            if obj.only_counter_ions
                bf = bf.kv("-only_counter_ions", "true");
            end
            surface_string = bf.char();
        end

        function [sol_so_obj, surf_so_obj, dl_so_obj] = selected_output_object(obj, solution, varargin)
            % [sol_so_obj, surf_so_obj, dl_so_obj] = selected_output_object(obj, solution, varargin)
            % the last argument is an optional database file that must be
            % in the database folder
            % returns three selected output objects that can be appended to the
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
            element_names(strcmpi(element_names, 'Charge')) = [];
            element_names(strcmpi(element_names, 'H2O')) = [];

            % surf_sp_name = phreeqc_rm.GetSurfaceSpeciesNames();
            surf_type = phreeqc_rm.GetSurfaceTypes();
            b = split(surf_type{1}, '_');
            surf_name = strjoin(b(1:end-1), '_');
            sur_sp_list = strjoin(phreeqc_rm.GetSurfaceSpeciesNames());
            
            surf_call = strjoin(cellfun(@(x)(['SURF("' x '","' surf_name '")']), element_names, 'UniformOutput', false));
            edl_special = [{'Charge'}; {'Charge1'}; {'Charge2'}; {'sigma'}; {'sigma1'}; {'sigma2'}; {'psi'}; {'psi1'}; {'psi2'}; {'water'}];
            edl_in = [element_names; edl_special];
            edl_call = strjoin(cellfun(@(x)(['EDL("' x '","' surf_name '")']), edl_in, 'UniformOutput', false));
            
            % we create three different selected output blocks
            % sol_string that is the solution properties
            % surf_string that is the surface properties and composition
            % dl_string that is the composition of the double layer
            % 1- Solution selected output
            sol_so_obj = solution.selected_output_object();
            
            % 2- surface selected output
            surf_so_obj = SelectedOutput();
            surf_so_obj.name = "Surface";
            surf_so_obj.number = solution.number+1;
            surf_content = strings(1,3);
            surf_content(1) = "-reset false";
            surf_content(2) = strjoin(["-molalities" sur_sp_list]);
            surf_content(3) = strjoin(["-activities" sur_sp_list]);
            surf_punch = strings(1,2);
            surf_punch(1) = strjoin(["-headings "  element_names']);
            surf_punch(2) = strjoin(["10 PUNCH" surf_call]);
            surf_so_obj.content= surf_content;
            surf_so_obj.punch = surf_punch;
            
            % 3- DL selected output
            dl_so_obj = SelectedOutput();
            dl_so_obj.number = solution.number+2;
            dl_so_obj.name = "Double layer";
            dl_so_obj.content(1) = "-reset false";
            dl_so_obj.punch(1) = strjoin(["-headings "  edl_in']);
            dl_so_obj.punch(2) = strjoin(["10 PUNCH" edl_call]);
        end

        function [all_string, solution_string, surf_string, dl_string] = selected_output_string(obj, solution, varargin)
            % [all_string, solution_string, surf_string, dl_string] = selected_output_string(obj, solution, varargin)
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
            if nargin>2
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
            [sol_so_obj, surf_so_obj, dl_so_obj] = selected_output_object(obj, solution, data_file);
            solution_string = sol_so_obj.phreeqc_string();
            surf_string = surf_so_obj.phreeqc_string();
            dl_string = dl_so_obj.phreeqc_string();

            all_string = sprintf([sol_so_obj.phreeqc_string_without_end ...
                surf_so_obj.phreeqc_string_without_end ...
                dl_so_obj.phreeqc_string_without_end '\nEND\n']);
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
            catch ME
                out_string = 0;
                warning('PhreeqcMatlab:runFailed', ...
                    'Error running Phreeqc (check the solution and surface definition): %s', ME.message);
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
            if nargin>2
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
            phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread
            phreeqc_rm = phreeqc_rm.RM_Create();
            iph_string = obj.combine_surface_solution_string(solution);
            so_string = obj.selected_output_string(solution, data_file);
            all_string = combine_phreeqc_strings(iph_string, so_string);
            phreeqc_rm.RM_LoadDatabase(database_file(data_file));
            phreeqc_rm.RM_RunString(true, true, true, all_string);
            phreeqc_rm.RM_FindComponents(); % always run it first
            % initialize phreeqcRM
            phreeqc_rm.RM_SetSelectedOutputOn(true);
            phreeqc_rm.RM_SetComponentH2O(true);
            phreeqc_rm.RM_SetUnitsSolution(2);
            phreeqc_rm.RM_SetSpeciesSaveOn(1);
            ic1 = -1*ones(InitialConditions.N_REACTANTS, 1);
            ic2 = -1*ones(InitialConditions.N_REACTANTS, 1);
            f1 = ones(InitialConditions.N_REACTANTS, 1);
            ic1(InitialConditions.SOLUTION) = solution.number;
            ic1(InitialConditions.SURFACE)  = obj.number;
            phreeqc_rm.RM_InitialPhreeqc2Module(ic1, ic2, f1);
            phreeqc_rm.RM_RunCells();
%             t_out_solution = phreeqc_rm.GetSelectedOutputTable(obj.number);
            t_out_surface = phreeqc_rm.GetSelectedOutputTable(obj.number+1);
            t_out_dl = phreeqc_rm.GetSelectedOutputTable(obj.number+2);
%             v_out= phreeqc_rm.GetSelectedOutput(obj.number);
%             h_out = phreeqc_rm.GetSelectedOutputHeadings(obj.number);
%             v_out= phreeqc_rm.GetSelectedOutput(obj.number);
%             h_out = phreeqc_rm.GetSelectedOutputHeadings(obj.number);
%             v_out_dl = phreeqc_rm.GetSelectedOutput(obj.number+2);
%             h_out_dl = phreeqc_rm.GetSelectedOutputHeadings(obj.number+2);
            
            % prepare the output for the surface (as a SurfaceResults
            % class)
            surface_result = SurfaceResult(obj);
            surface_result.surface_species = string(phreeqc_rm.GetSurfaceSpeciesNames())';
            n_surf_species = length(surface_result.surface_species);
            % FRAGILE (revisit in M3 with a CD-MUSIC equilibrate test): this
            % slices the surface table by positional arithmetic on
            % keys()/values(). containers.Map orders entries by sorted key, not
            % insertion order, so this depends on the exact column names/order
            % emitted by the USER_PUNCH block. Left as-is until a reference-value
            % test exists to refactor it safely.
            h = t_out_surface.keys;
            surf_elements = h(1:end-2*n_surf_species);
            surface_result.surface_elements = string(surf_elements);
            surf_composition = cell2mat(t_out_surface.values); % surface species composition
            surface_result.surface_species_molalities = surf_composition(end-n_surf_species+1:end);
            surface_result.surface_species_mole_fraction = surface_result.surface_species_molalities/sum(surface_result.surface_species_molalities);
            surface_result.surface_species_log_activity = surf_composition(end-2*n_surf_species+1:end-n_surf_species);

            n_elements = length(surf_elements);
            dl_moles = zeros(1,n_elements);
            for i = 1:n_elements
                dl_moles(i) = map_value(t_out_dl, surf_elements{i}, 0);
            end
            surface_result.elements_edl = string(surf_elements);
            surface_result.element_moles_edl = dl_moles;
            % TODO: add surface species to the results
            % needs basid function EDL_SPECIES and more information about
            % the double layer thickness and surface area of the solid
            % EDL charges/potentials looked up by header (NaN if the chosen EDL
            % model did not emit that plane) so missing columns don't crash.
            surface_result.charge_plane_0 = map_value(t_out_dl, 'Charge');
            surface_result.charge_plane_1 = map_value(t_out_dl, 'Charge1');
            surface_result.charge_plane_2 = map_value(t_out_dl, 'Charge2');
            surface_result.charge_density_plane_0 = map_value(t_out_dl, 'sigma');
            surface_result.charge_density_plane_1 = map_value(t_out_dl, 'sigma1');
            surface_result.charge_density_plane_2 = map_value(t_out_dl, 'sigma2');
            surface_result.potential_plane_0 = map_value(t_out_dl, 'psi');
            surface_result.potential_plane_1 = map_value(t_out_dl, 'psi1');
            surface_result.potential_plane_2 = map_value(t_out_dl, 'psi2');
            surface_result.water_mass_dl = map_value(t_out_dl, 'water');

            % Get solution results from phreeqcrm
            solution_result = solution.results_from_phreeqcrm(phreeqc_rm);
            surface_result.water_mass = solution_result.water_mass;
        end

        function out_string = combine_surface_solution_string(obj, solution)
            % combines the phreeqc string of a solution and a surface to be equilibrated with each other
            sol_string = solution.phreeqc_string();
            [surf_string, surf_master_string, surf_sp_string] = obj.phreeqc_string();
            out_string = strjoin([surf_master_string, surf_sp_string, sol_string, surf_string, "-equilibrate ", num2str(solution.number), "\nEND\n"]);
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

            % Scalar 1:1 fields (SCM is set here so the Reactions block below
            % can test it for cd_music). MasterSpecies/Reactions are expanded
            % separately.
            obj = assign_json_fields(obj, surf_struct, [ ...
                "Name",         "name"; ...
                "Number",       "number"; ...
                "Mass",         "mass"; ...
                "SCM",          "scm"; ...
                "SpecificArea", "specific_surface_area"; ...
                "SitesUnits",   "sites_units"; ...
                "EDL",          "edl_model"; ...
                "Capacitances", "capacitances" ]);

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
            % Capacitances, if present, are set by the assign_json_fields call above.
        end
    end
end

