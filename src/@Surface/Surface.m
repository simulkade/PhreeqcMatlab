classdef Surface
    %SURFACE defines a surface species that can be equilibrated with a
    %solution object
    
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
        edl_thickness(1,1) double
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
        
        function surface_string = phreeqc_string(obj)
           surface_string = ["SURFACE" num2str(obj.number) obj.name "\n"];
        end
    end
    
    methods (Static)
        function obj = calcite_surface()
            obj = Surface();
        end
        
        function obj = clay_surface()
            obj = Surface();
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
                dh = zeros(1, length(f_names));
                k = zeros(1, length(f_names));
                cdm = zeros(1, length(f_names));
                ms = cellfun(@(x)string(getfield(surf_struct.Reactions, x, 'Reaction')), f_names, 'UniformOutput', false);
                k_cell = cellfun(@(x)getfield(surf_struct.Reactions, x, 'logK'), f_names, 'UniformOutput', false);
                k(:) = cell2mat(k_cell(:));
                try
                    dh_cell = cellfun(@(x)getfield(surf_struct.Reactions, x, 'DeltaH'), f_names, 'UniformOutput', false);
                    dh(:) = cell2mat(dh_cell(:));
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
                obj.dh = dh;
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

