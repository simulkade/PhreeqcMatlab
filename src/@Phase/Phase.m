classdef Phase
    %{
    PHASE 
    define a new phase (e.g. a mineral) that is in equilibrium with a
    solution defined by @solution class
    for gas phases, use gas class
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        phase_names(1,:) string
        alternative_formula(1,:) string
        moles(1,:) double
        saturation_indices(1,:) double
        force_equality(1,:) logical
        dissolve_only(1,:) logical
        precipitate_only(1,:) logical
    %}
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        phase_names(1,:) string
        alternative_formula(1,:) string
        moles(1,:) double
        saturation_indices(1,:) double
        force_equality(1,:) logical
        dissolve_only(1,:) logical
        precipitate_only(1,:) logical
    end
    
    methods
        function obj = Phase()
            %PHASE Construct an instance of this class
            %   
            obj.name="empty phase";
            obj.number=1;
            obj.phase_names = [];
            obj.alternative_formula = [];
            obj.moles = [];
            obj.saturation_indices = [];
            obj.force_equality = [];
            obj.dissolve_only = [];
            obj.precipitate_only = [];
        end
        
        function phase_string = phreeqc_string(obj)
            % phase_string = phreeqc_phase(obj) 
            % converts a phase object to a phreeqc string
            n_phase = length(obj.phase_names);
            if n_phase==0
                phase string = "\n";
            else
                phase_string = strjoin(["EQUILIBRIUM_PHASE " num2str(obj.number) " " obj.name "\n"]);
                for i = 1:n_phase
                    phase_string = strjoin([phase_string obj.phase_names(i)]); % phase name
                    phase_string = strjoin([phase_string "  " num2str(obj.saturation_indices(i))]); % saturation index
                    if ~isempty(obj.alternative_formula)
                        if  obj.alternative_formula(i)~=""
                            phase_string = strjoin([phase_string "  " obj.alternative_formula(i)]);
                        end
                    end
                    phase_string = strjoin([phase_string "  " num2str(obj.moles(i))]);
                    if ~isempty(obj.precipitate_only)
                        if obj.precipitate_only(i)
                            phase_string = strjoin([phase_string "  precipitate_only"]);
                        elseif ~isempty(obj.dissolve_only)
                            if obj.dissolve_only(i)
                                phase_string = strjoin([phase_string "  dissolve_only"]);
                            end
                        end
                    end
                    phase_string = strjoin([phase_string "\n"]);
                    if ~isempty(obj.force_equality) && obj.force_equality(i)
                        phase_string = strjoin([phase_string "-force_equality \n"]);
                    end
                end
            end
            phase_string = sprintf(char(phase_string));
        end
        
        function so_obj = selected_output_object(obj)
            % creates a selected output string with typical values for a 
            % phase object; this is a convenience function and similar
            % selected output strings can be defined in the code. This
            % particular selected output is used when equilibrating the
            % phase object with a specified solution
            % see also equilibrate_with
            % from Phreeqc manual:
            % Line 23: -equilibrium_phases phase list
            % -equilibrium_phases --Identifier allows definition of a list 
            % of pure phases for which (1) total amounts in the pure-phase 
            % assemblage and (2) moles transferred will be written to the 
            % selected-output file. Optionally, -e[quilibrium_phases ] or -p 
            % [ ure_phases ]. Note the hyphen is required to avoid a conflict 
            % with the keyword EQUILIBRIUM_PHASES and its synonyms.
            % 
            % phase list --List of phases for which data will be written to 
            % the selected-output file. The list may continue on the subsequent 
            % line(s). After each calculation, two values are written to 
            % the selected-output file: (1) the moles of each of the phases 
            % (defined by EQUILIBRIUM_PHASES), and (2) the moles transferred. 
            % Phases are defined by PHASES input. If the phase is not defined
            % or is not present in the pure-phase assemblage, the amounts will 
            % be printed as 0.
            % Line 24: -saturation_indices phase list
            % 
            % -saturation_indices --Identifier allows definition of a list 
            % of phases for which saturation indices [or log (base 10) fugacity 
            % for gases] will be written to the selected-output file. Optionally, 
            % saturation_indices , si , -s [ aturation_indices ], or -s [ i ].
            % 
            % phase list --List of phases for which saturation indices [or log (base 10) partial pressure for gases] will be written to the selected-output file. The list may continue on the subsequent line(s). After each calculation, the saturation index of each of the phases will be written to the selected-output file. Phases are defined by PHASES input. If the phase is not defined or if one or more of its constituent elements is not in solution, the saturation index will be printed as -999.999.
            so_obj = SelectedOutput();
            so_obj.name = "Phase";
            so_obj.number = obj.number;
            so_obj.content(1) = "-high_precision    true";
            so_obj.content(1) = "-reset    false";
            so_obj.content(1) = strjoin(["-equilibrium_phases   " obj.phase_names]);
            so_obj.content(1) = strjoin(["-saturation_indices   " obj.phase_names]);
        end

        function so_string = selected_output_string(obj)
            % creates a selected output string with typical values for a 
            % phase object; this is a convenience function and similar
            % selected output strings can be defined in the code. This
            % particular selected output is used when equilibrating the
            % phase object with a specified solution
            % see also equilibrate_with
            % from Phreeqc manual:
            % Line 23: -equilibrium_phases phase list
            % -equilibrium_phases --Identifier allows definition of a list 
            % of pure phases for which (1) total amounts in the pure-phase 
            % assemblage and (2) moles transferred will be written to the 
            % selected-output file. Optionally, -e[quilibrium_phases ] or -p 
            % [ ure_phases ]. Note the hyphen is required to avoid a conflict 
            % with the keyword EQUILIBRIUM_PHASES and its synonyms.
            % 
            % phase list --List of phases for which data will be written to 
            % the selected-output file. The list may continue on the subsequent 
            % line(s). After each calculation, two values are written to 
            % the selected-output file: (1) the moles of each of the phases 
            % (defined by EQUILIBRIUM_PHASES), and (2) the moles transferred. 
            % Phases are defined by PHASES input. If the phase is not defined
            % or is not present in the pure-phase assemblage, the amounts will 
            % be printed as 0.
            % Line 24: -saturation_indices phase list
            % 
            % -saturation_indices --Identifier allows definition of a list 
            % of phases for which saturation indices [or log (base 10) fugacity 
            % for gases] will be written to the selected-output file. Optionally, 
            % saturation_indices , si , -s [ aturation_indices ], or -s [ i ].
            % 
            % phase list --List of phases for which saturation indices 
            % [or log (base 10) partial pressure for gases] will be written 
            % to the selected-output file. The list may continue on the 
            % subsequent line(s). After each calculation, the saturation 
            % index of each of the phases will be written to the selected-output 
            % file. Phases are defined by PHASES input. If the phase is not 
            % defined or if one or more of its constituent elements is not 
            % in solution, the saturation index will be printed as -999.999.
            so_obj = selected_output_object(obj);
            so_string = so_obj.phreeqc_string();

%             so_string = strjoin(["SELECTED_OUTPUT" num2str(obj.number) "\n"]);
%             so_string = strjoin([so_string  "-high_precision	 true \n"]);
%             so_string = strjoin([so_string  "-reset    false \n"]);
%             so_string = strjoin([so_string  "-equilibrium_phases   " obj.phase_names "\n"]);
%             so_string = strjoin([so_string  "-saturation_indices   " obj.phase_names "\n"]);
%             so_string = strjoin([so_string  "END"]);

        end

        function run(obj)
            disp(['Phase' obj.name]);
            warning('It is not possible to run a phase without an aqueous solution. Pleas define a SingleCell and run it')
        end

        function out_string = equilibrate_in_phreeqc(obj, solution, varargin)
            % equilibrate_in_phreeqc(obj, solution, varargin)
            % equilibrates the phase with a solution by creating a phreeqc
            % string and running it in an IPhreeqc instance
            iph_string = obj.combine_phase_solution_string(solution);
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
                disp('An error occured running Phreeqc. Please check the solution and phase definition');
                iph.DestroyIPhreeqc();
            end
        end

        function equilibrate_with(obj, solution, varargin)
            % equilibrates the phase with a solution
            % TBD
            if nargin>1
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
            phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread
            phreeqc_rm = phreeqc_rm.RM_Create(); % create a PhreeqcRM instance
            iph_string = phreeqc_string(obj);
        end
        
        function out_string = combine_phase_solution_string(obj, solution)
            % combines the phreeqc string of a solution and a surface to be equilibrated with each other
            sol_string = solution.phreeqc_string();
            phase_string = obj.phreeqc_string();
            out_string = strjoin([phase_string, sol_string, "\nEND"]);
            out_string = sprintf(char(out_string));
        end

        function so_string = combine_selected_output(obj, solution, varargin)
            % so_string = combine_selected_output(obj, solution, varargin)
            % the last argument is an optional database file that must be
            % in the database folder
            % returns a selected output string that can be appended to the
            % current phreeqc string of the surface object to obtain most of
            % the physical and chemical properties calculated by phreeqc
            % for a phase in equilibrium with a solution
            % a solution must be specified since some of the selected output lines
            % are constructed after running a Phreeqc equilibration
            % step 1: run the equilibration
            phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread
            phreeqc_rm = phreeqc_rm.RM_Create(); % create a PhreeqcRM instance
            if nargin>2
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
            % run phreeqc string in phreeqcRM
            iph_string = obj.combine_phase_solution_string(solution);
            phreeqc_rm.RM_LoadDatabase(database_file(data_file));
            phreeqc_rm.RM_RunString(true, true, true, iph_string);
            phreeqc_rm.RM_FindComponents(); % always run it first
            phreeqc_rm.GetComponents();

            solution_so = solution.selected_output_string();
            % TBD
            
        end
    end
    
     methods(Static)
         function ch = chalk()
             % ch = Phase.chalk();
             % defines a chalk phase composed of pure calcite
             ch = Phase();
             ch.name = "Chalk";
             ch.number = 1;
             ch.phase_names = "Calcite";
             ch.moles = 0.0;
             ch.saturation_indices = 0.0;
         end
         
         function obj = read_json(phase_field)
            % creates a phase object from an input JSON
            obj = Phase();
             
            if isfield(phase_field, 'Name')
                obj.name = phase_field.Name;
            end

            if isfield(phase_field, 'Number')
                obj.number = phase_field.Number;
            end

            if isfield(phase_field, 'Composition')
                obj.components = fieldnames(phase_field.Composition); % get the list of phases
                obj.moles = cellfun(@(x)getfield(phase_field.Composition, {1}, x), obj.components); % get the moles
            end
            
            if isfield(phase_field, 'AlternativeFormula')
                obj.alternative_formula = phase_field.AlternativeFormula;
            end
            
            if isfield(phase_field, 'SaturationIndices')
                obj.saturation_indices = phase_field.SaturationIndices;
            end
            
            if isfield(phase_field, 'ForceEquality')
                obj.force_equality = phase_field.ForceEquality;
            end
            
            if isfield(phase_field, 'DissolveOnly')
                obj.dissolve_only = phase_field.DissolveOnly;
            end
            
            if isfield(phase_field, 'PrecipitateOnly')
                obj.precipitate_only = phase_field.PrecipitateOnly;
            end
            
         end
         
     end
end

