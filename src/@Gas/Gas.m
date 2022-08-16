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
            % phreeqc_string creates a phreeqc string from the Gas object
            gas_string = strjoin(["GAS_PHASE " num2str(obj.number) " " obj.name "\n"]);
            n_gas = length(obj.phase_names);
            if obj.fixed_pressure
                gas_string = strjoin([gas_string "-fixed_pressure"]);
                gas_string = strjoin([gas_string "-pressure" num2str(obj.pressure)]);
            else
                gas_string = strjoin([gas_string "-fixed_volume"]);
            end
            gas_string = strjoin([gas_string "-temperature" num2str(obj.temperature)]);
            if ~isempty(obj.volume)
                gas_string = strjoin([gas_string "-volume" num2str(obj.volume)]);
            end
            for i=1:n_gas
                gas_string = strjoin([gas_string obj.phase_names(i) obj.partial_pressure(i) "\n"]);
            end
            gas_string = sprintf(char(gas_string));
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

