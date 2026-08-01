classdef Gas < Reactant
    % GAS defines a constant volume or constant pressure gas phase

    properties
        % name, number inherited from Reactant
        phase_names(1,:) string
        partial_pressure(1,:) double
        temperature(1,1) double
        fixed_pressure(1,1) logical
        pressure
        volume
    end
    
    methods
        function obj = Gas()
            %GAS Construct an instance of this class
            %   Detailed explanation goes here
            obj.name="empty gas phase";
            obj.number=1;
            obj.temperature = 25.0;
            obj.volume = 1.0;
            obj.fixed_pressure = true;
        end
        
        function slot = ic_slot(~)
            %IC_SLOT a Gas occupies the GAS_PHASE slot.
            slot = InitialConditions.GAS_PHASE;
        end

        function gas_string = phreeqc_string(obj)
            % phreeqc_string creates a Phreeqc GAS_PHASE block from the Gas
            % object, built with the shared PhreeqcBlock builder.
            b = PhreeqcBlock("GAS_PHASE", obj.number, obj.name);
            if obj.fixed_pressure
                b = b.flag("-fixed_pressure");
                b = b.kv("-pressure", obj.pressure);   % suppressed if unset
            else
                b = b.flag("-fixed_volume");
            end
            b = b.kv("-temperature", obj.temperature);
            b = b.kv("-volume", obj.volume);
            for i = 1:numel(obj.phase_names)
                b = b.kv(obj.phase_names(i), obj.partial_pressure(i));
            end
            gas_string = b.char();
        end

        function out_string = equilibrate_in_phreeqc(obj, solution, varargin)
            %EQUILIBRATE_IN_PHREEQC equilibrate this gas phase with a solution
            % in IPhreeqc and return the raw PHREEQC output string. The last
            % optional argument is a database file name.
            if nargin > 2
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
            iph_string = obj.combine_gas_solution_string(solution);
            iph = IPhreeqc();
            iph = iph.CreateIPhreeqc();
            try
                out_string = iph.RunPhreeqcString(iph_string, database_file(data_file));
                iph.DestroyIPhreeqc();
            catch ME
                out_string = 0;
                warning('PhreeqcMatlab:runFailed', ...
                    'Error running Phreeqc (check the solution and gas definition): %s', ME.message);
                iph.DestroyIPhreeqc();
            end
        end

        function out_string = combine_gas_solution_string(obj, solution)
            %COMBINE_GAS_SOLUTION_STRING GAS_PHASE + SOLUTION in one simulation
            % (the solution's trailing END terminates it).
            out_string = combine_phreeqc_strings(obj.phreeqc_string(), solution.phreeqc_string());
        end

        % equilibrate_with(solution) is inherited from Reactant: it places the
        % GAS_PHASE in a PhreeqcRM cell alongside the solution and returns the
        % post-equilibration aqueous SolutionResult.

        function so_string = selected_output_string(obj)
            % a SELECTED_OUTPUT block reporting this gas phase's partial
            % pressures (fugacities) and saturation indices.
            b = PhreeqcBlock("SELECTED_OUTPUT", obj.number);
            b = b.kv("-high_precision", "true");
            b = b.kv("-reset", "false");
            b = b.kv("-gases", obj.phase_names);
            b = b.kv("-saturation_indices", obj.phase_names);
            so_string = b.char();
        end


    end

    methods(Static)
        function CO2 = damp_CO2()
            % CO2 = Gas.damp_CO2(); water-saturated pure CO2 gas phase.
            CO2 = Gas.from_json("DampCO2");
        end

        function fg = flue_gas()
            % fg = Gas.flue_gas(); a simple CO2/N2 flue-gas mixture.
            fg = Gas.from_json("FlueGas");
        end

        function obj = read_json(entry)
            % read_json builds a Gas object from a decoded JSON entry. Phase
            % names/partial pressures are parallel arrays (not a Composition
            % map) so identifiers like "CO2(g)" survive jsondecode intact.
            obj = Gas();
            obj = assign_json_fields(obj, entry, [ ...
                "Name",          "name"; ...
                "Number",        "number"; ...
                "Temperature",   "temperature"; ...
                "Volume",        "volume"; ...
                "FixedPressure", "fixed_pressure"; ...
                "Pressure",      "pressure" ]);
            if isfield(entry, 'PhaseNames')
                obj.phase_names = string(entry.PhaseNames(:))';
            end
            if isfield(entry, 'PartialPressures')
                obj.partial_pressure = double(entry.PartialPressures(:))';
            end
        end

        function obj = from_json(name, varargin)
            % from_json builds a Gas object from a named entry in a JSON file.
            %   Gas.from_json("DampCO2")               % gases.json
            %   Gas.from_json("DampCO2", "gases.json")
            if nargin < 2; file = 'gases.json'; else; file = varargin{1}; end
            data = jsondecode(fileread(database_file(file)));
            key = char(name);
            if ~isfield(data, key)
                error('PhreeqcMatlab:jsonEntryNotFound', ...
                    'No entry "%s" in %s.', key, file);
            end
            obj = Gas.read_json(data.(key));
        end

    end
end

