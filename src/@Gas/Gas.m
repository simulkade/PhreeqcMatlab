classdef Gas
    % GAS defines a constant volume or constant pressure gas phase
    
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
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

        function equilibrate_in_phreeqc(obj, solution, varargin)
            % run the Gas object with a solution in IPhreeqc
            if nargin>2
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
            

        end
        
        function equilibrate_with(obj, solution, varargin)
            % equilibrate a Gas object with a solution object
            if nargin>2
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
        end

        function so_string = selected_output_string(obj)
            % a selected_output block for the gas object
            so_string = strjoin(["SELECTED_OUTPUT" num2str(obj.number) "\n"]);
            so_string = strjoin([so_string  "-high_precision	 true \n"]);
            so_string = strjoin([so_string  "-reset    false \n"]);
            so_string = strjoin([so_string  "-gases   " obj.phase_names "\n"]);
            so_string = strjoin([so_string  "-saturation_indices   " obj.phase_names "\n"]);
            so_string = strjoin([so_string  "END"]);

        end


    end

    methods(Static)
        function CO2 = damp_CO2()
            CO2 = Gas();
            CO2.phase_names = ["CO2(g)", "H2O(g)"];
            CO2.partial_pressure = [1.0, 0.0];
            CO2.fixed_pressure = false;
        end

        function fg = flue_gas()
            fg = Gas();
            fg.phase_names = ["CO2(g)", "N2(g)", "H2O(g)"];
            fg.partial_pressure = [0.15, 0.85, 0.0];
            fg.fixed_pressure = false;
        end

    end
end

