classdef SingleCell
    %SINGLECELL is a batch reactor: an aqueous solution optionally mixed with
    % an equilibrium-phase assemblage, a surface, an ion exchanger, a gas phase
    % and/or kinetic reactions, all defined as PhreeqcMatlab objects.
    %
    % Construct with the solution first, then name-value pairs for the other
    % reactants:
    %   sc = SingleCell(Solution.seawater(), ...
    %                   'equilibrium_phase', Phase.chalk(), ...
    %                   'gas_phase', Gas.damp_CO2(), ...
    %                   'data_base', 'phreeqc.dat');
    %   R  = sc.run();          % -> SingleCellResult
    %   R.solution.pH           % aqueous result
    %   R.phase.saturation_indices
    %
    % Running a cell does not mutate it; the parsed state is returned as a
    % SingleCellResult. This is a value class (reassign-or-lose).
    %
    % See also Solution, Phase, Surface, Exchange, Gas, Kinetics, SingleCellResult.

    properties
        name(1,1) string
        temperature(1,1) double
        pressure(1,1) double
        aqueous_solution(1,1) Solution
        equilibrium_phase(1,1) Phase
        surface_specie(1,1) Surface
        exchanger(1,1) Exchange
        kinetics(1,1) Kinetics
        gas_phase(1,1) Gas
        data_base(1,1) string
    end

    methods
        function obj = SingleCell(aq_solution, varargin)
            %SINGLECELL construct a single cell around an aqueous solution.
            % Extra reactants are given as name-value pairs:
            %   'equilibrium_phase'|'phase', 'surface'|'surface_specie',
            %   'exchanger'|'exchange', 'kinetics', 'gas_phase'|'gas',
            %   'data_base'|'database', 'temperature', 'pressure'.
            obj.name = aq_solution.name;
            obj.temperature = aq_solution.temperature;
            obj.pressure = aq_solution.pressure;
            obj.aqueous_solution = aq_solution;
            obj.data_base = "phreeqc.dat";
            for k = 1:2:numel(varargin)
                key = char(varargin{k});
                val = varargin{k+1};
                switch lower(key)
                    case {'equilibrium_phase', 'phase'};   obj.equilibrium_phase = val;
                    case {'surface', 'surface_specie'};    obj.surface_specie = val;
                    case {'exchanger', 'exchange'};        obj.exchanger = val;
                    case {'kinetics'};                     obj.kinetics = val;
                    case {'gas_phase', 'gas'};             obj.gas_phase = val;
                    case {'data_base', 'database'};        obj.data_base = string(val);
                    case {'temperature'};                  obj.temperature = val;
                    case {'pressure'};                     obj.pressure = val;
                    otherwise
                        error('PhreeqcMatlab:unknownSingleCellArg', ...
                            'Unknown SingleCell argument "%s".', key);
                end
            end
        end

        function tf = has_phase(obj);    tf = ~isempty(obj.equilibrium_phase.phase_names);      end
        function tf = has_surface(obj);  tf = ~isempty(obj.surface_specie.surface_master_species); end
        function tf = has_exchange(obj); tf = ~isempty(obj.exchanger.exchange_species);         end
        function tf = has_gas(obj);      tf = ~isempty(obj.gas_phase.phase_names);              end
        function tf = has_kinetics(obj); tf = ~isempty(obj.kinetics.reaction_names);            end

        function definition = phreeqc_string(obj)
            %PHREEQC_STRING the combined definition of every reactant in this
            % cell (no SELECTED_OUTPUT), in PHREEQC-friendly order.
            definition = obj.aqueous_solution.phreeqc_string();
            if obj.has_phase();    definition = combine_phreeqc_strings(definition, obj.equilibrium_phase.input_string()); end
            if obj.has_surface();  definition = combine_phreeqc_strings(definition, obj.surface_specie.input_string());    end
            if obj.has_exchange(); definition = combine_phreeqc_strings(definition, obj.exchanger.input_string());         end
            if obj.has_gas();      definition = combine_phreeqc_strings(definition, obj.gas_phase.input_string());         end
            if obj.has_kinetics(); definition = combine_phreeqc_strings(definition, obj.kinetics.input_string());          end
        end

        function so_string = selected_output_string(obj)
            %SELECTED_OUTPUT_STRING one block (numbered after the solution)
            % carrying the aqueous properties plus phase/gas columns present.
            so_obj = obj.aqueous_solution.selected_output_object();
            so_obj.number = obj.aqueous_solution.number;
            if obj.has_phase()
                so_obj.content(end+1) = strjoin(["-equilibrium_phases" obj.equilibrium_phase.phase_names]);
                so_obj.content(end+1) = strjoin(["-saturation_indices" obj.equilibrium_phase.phase_names]);
            end
            if obj.has_gas()
                so_obj.content(end+1) = strjoin(["-gases" obj.gas_phase.phase_names]);
            end
            so_string = so_obj.phreeqc_string();
        end

        function cell_result = run(obj, varargin)
            % cell_result = run(obj, [database])
            % Builds the combined Phreeqc input from every reactant in the
            % cell, registers the initial conditions, runs one PhreeqcRM cell
            % and returns a populated SingleCellResult.
            if ~isempty(varargin)
                data_file = char(varargin{end});
            elseif strlength(obj.data_base) > 0
                data_file = char(obj.data_base);
            else
                data_file = 'phreeqc.dat';
            end

            sol = obj.aqueous_solution;
            phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread (constructor calls RM_Create)
            definition = combine_phreeqc_strings(obj.phreeqc_string(), obj.selected_output_string());
            try
                phreeqc_rm.RM_SetComponentH2O(true);
                phreeqc_rm.RM_SetUnitsSolution(2);        % 1 mg/L; 2 mol/L; 3 kg/kgs
                phreeqc_rm.RM_SetUnitsPPassemblage(1);    % 0 mol/L cell; 1 mol/L water; 2 mol/L rock
                phreeqc_rm.RM_SetUnitsExchange(1);
                phreeqc_rm.RM_SetUnitsSurface(1);
                phreeqc_rm.RM_SetUnitsGasPhase(1);
                phreeqc_rm.RM_SetUnitsSSassemblage(1);
                phreeqc_rm.RM_SetUnitsKinetics(1);
                phreeqc_rm.RM_UseSolutionDensityVolume(true);
                phreeqc_rm.RM_SetSpeciesSaveOn(true);

                phreeqc_rm.RM_LoadDatabase(database_file(data_file));
                phreeqc_rm.RM_RunString(true, true, true, definition);
                phreeqc_rm.RM_SetSelectedOutputOn(true);
                phreeqc_rm.RM_FindComponents();           % required before RunCells

                % Initial conditions: the solution plus every present reactant,
                % each in its own slot pointing at its block number.
                ic1 = -1 * ones(InitialConditions.N_REACTANTS, 1);
                ic2 = -1 * ones(InitialConditions.N_REACTANTS, 1);
                f1  = ones(InitialConditions.N_REACTANTS, 1);
                ic1(InitialConditions.SOLUTION) = sol.number;
                if obj.has_phase();    ic1(InitialConditions.EQUILIBRIUM_PHASES) = obj.equilibrium_phase.number; end
                if obj.has_surface();  ic1(InitialConditions.SURFACE)            = obj.surface_specie.number;    end
                if obj.has_exchange(); ic1(InitialConditions.EXCHANGE)           = obj.exchanger.number;         end
                if obj.has_gas();      ic1(InitialConditions.GAS_PHASE)          = obj.gas_phase.number;         end
                if obj.has_kinetics(); ic1(InitialConditions.KINETICS)           = obj.kinetics.number;          end
                phreeqc_rm.RM_InitialPhreeqc2Module(ic1, ic2, f1);
                phreeqc_rm.RM_RunCells();

                cell_result = obj.results_from_phreeqcrm(phreeqc_rm);
                phreeqc_rm.RM_Destroy();
            catch ME
                cell_result = 0;
                warning('PhreeqcMatlab:runFailed', ...
                    'Error running PhreeqcRM (check the cell definition): %s', ME.message);
                phreeqc_rm.RM_Destroy();
            end
        end

        function cell_result = results_from_phreeqcrm(obj, phreeqc_rm)
            % Parse a run into a SingleCellResult: always the aqueous
            % SolutionResult, plus a PhaseResult when the cell held phases.
            sol = obj.aqueous_solution;
            cell_result = SingleCellResult(obj);
            cell_result.solution = sol.results_from_phreeqcrm(phreeqc_rm);
            cell_result.phase = [];
            cell_result.surface = [];
            if obj.has_phase()
                t_out = phreeqc_rm.GetSelectedOutputTable(sol.number);
                ph_obj = obj.equilibrium_phase;
                PR = PhaseResult(ph_obj);
                PR.phase_names = ph_obj.phase_names;
                n = numel(ph_obj.phase_names);
                PR.moles = nan(1, n);
                PR.moles_transferred = nan(1, n);
                PR.saturation_indices = nan(1, n);
                for i = 1:n
                    ph = char(ph_obj.phase_names(i));
                    PR.moles(i)              = map_value(t_out, ph);
                    PR.moles_transferred(i)  = map_value(t_out, ['d_' ph]);
                    PR.saturation_indices(i) = map_value(t_out, ['si_' ph]);
                end
                cell_result.phase = PR;
            end
        end
    end
end
