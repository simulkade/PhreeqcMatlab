classdef Solution
    %SOLUTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        unit(1,1) string
        components(1,:) string
        concentrations(1,:) double
        charge_balance_component(1,1) string
        ph_charge_balance(1,1) {mustBeNumericOrLogical}
        density(1,1) double
        density_calculation(1,1) {mustBeNumericOrLogical}
        pH {mustBeScalarOrEmpty} = []
        pe {mustBeScalarOrEmpty} = []
        alkalinity {mustBeScalarOrEmpty} = []
        alkalinity_component(1,1) string
        pressure {mustBeScalarOrEmpty}
        temperature {mustBeScalarOrEmpty}
    end
    
    methods
        function obj = Solution()
            %SOLUTION Construct an instance of this class
            % currently, it constructs an empty class (pure water)
            % the preferred method of initializing its fields is manually or 
            % from an input file or from one of the predefined solutions
            obj.name = "Pure Water";
            obj.number = 1;
            obj.temperature = 25.0; % degree Celcius
            obj.pressure = 1.0;     % atmosphere
        end
                
        function solution_string = phreeqc_string(obj)
            % phreeqc_solution returns a string of phreeqc format for the
            % defined PhreeqcMatlab solution
            % NOTE: at this stage, a phreeqc string can contain more
            % details than the equivalent PhreeqcMatlab solution
            % object
            % Note: still not smart enough to filter out the nonspecified
            % fields; requires some if then else.
            n_comp = length(obj.components);
            % solution_cell = cell(n_comp, 1);
            % solution_cell{1} = ['SOLUTION ' obj.name];
            solution_string = strjoin(["SOLUTION " num2str(obj.number) obj.name "\n"]);
            solution_string = strjoin([solution_string 'unit' obj.unit "\n"]);
            solution_string = strjoin([solution_string 'pressure' num2str(obj.pressure) "\n"]);
            solution_string = strjoin([solution_string 'temp' num2str(obj.temperature) "\n"]);
            if obj.ph_charge_balance
                solution_string = strjoin([solution_string 'pH' num2str(obj.pH) "  charge" "\n"]);
            else
                solution_string = strjoin([solution_string 'pH' num2str(obj.pH) "\n"]);
            end
            solution_string = strjoin([solution_string 'pe' num2str(obj.pe) "\n"]);
            solution_string = strjoin([solution_string 'density' num2str(obj.density) "\n"]);
            for i=1:n_comp
                % pH charge balance has priority over component charge
                % balance
                if strcmpi(obj.charge_balance_component, obj.components(i)) && ~obj.ph_charge_balance
                    solution_string = strjoin([solution_string obj.components(i) "  " num2str(obj.concentrations(i)) "  charge" "\n"]);
                else
                    solution_string = strjoin([solution_string obj.components(i) "  " num2str(obj.concentrations(i)) "\n"]);
                end
            end
            if ~isempty(obj.alkalinity)
                if obj.alkalinity_component~=""
                    solution_string = strjoin([solution_string 'Alkalinity' num2str(obj.alkalinity) "  as  " obj.alkalinity_component "\n"]);
                else
                    solution_string = strjoin([solution_string 'Alkalinity' num2str(obj.alkalinity) "\n"]);
                end
            end
            solution_string = char(solution_string);
        end
        
        function out_string = run_in_phreeqc(obj, varargin)
            % runs the function in a IPhreeqc instance, display the results
            %, and kills the IPhreeqc instance
            iph = IPhreeqc(); % load the library
            iph = iph.CreateIPhreeqc(); % create an IPhreeqc instance
            iph_string = phreeqc_string(obj);
            if nargin>1
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
            try
                out_string = iph.RunPhreeqcString(iph_string, database_file(data_file));
                iph.DestroyIPhreeqc();
            catch
                out_string = 0;
                disp('An error occured running Phreeqc. Please check the solution definition');
                iph.DestroyIPhreeqc();
            end
        end
        
        function out_string = run(obj, varargin)
            % runs the function in a PhreeqcRM instance, and store the
            % results in a SolutionResult object
            iph = IPhreeqc(); % load the library
            iph = iph.CreateIPhreeqc(); % create an IPhreeqc instance
            iph_string = phreeqc_string(obj);
            % add a selected output block to the string before running
            iph_string = strjoin([iph_string "SELECTED_OUTPUT" num2str(obj.number) "\n"]);
            iph_string = strjoin([iph_string  "-reset    false \n"]);
            iph_string = strjoin([iph_string  "-pH    true \n"]);
            iph_string = strjoin([iph_string  "-pe    true \n"]);
            iph_string = strjoin([iph_string  "-temperature    true \n"]);
            iph_string = strjoin([iph_string  "-alkalinity    true \n"]);
            iph_string = strjoin([iph_string  "-ionic_strength    ture \n"]);
            iph_string = strjoin([iph_string  "-water    true \n"]);
            iph_string = strjoin([iph_string  "-charge_balance    true \n"]);
            iph_string = strjoin([iph_string  "-percent_error    true \n"]);
            iph_string = strjoin([iph_string  "\n"]);
            iph_string = strjoin([iph_string  "\n"]);
            iph_string = strjoin([iph_string  "\n"]);
            iph_string = strjoin([iph_string  "\n"]);
            if nargin>1
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
            try
                out_string = iph.RunPhreeqcString(iph_string, database_file(data_file));
                iph.DestroyIPhreeqc();
            catch
                out_string = 0;
                disp('An error occured running Phreeqc. Please check the solution definition');
                iph.DestroyIPhreeqc();
            end
        end
    end
    
    methods(Static)
        function sw = seawater()
            % sw = Solution.seawater();
            % returns a simple solution object that contains 
            % a seawater composition
            sw=Solution();
            sw.name = "Seawater";
            sw.number = 1;
            sw.unit = "ppm";
            sw.components = ["Ca", "Mg", "Na", "K", "Si", "Cl", "S(6)"];
            sw.concentrations = [412.3, 1291.8, 10768.0, 399.1, 4.28, 19353.0, 2712.0];
            sw.charge_balance_component = "";
            sw.ph_charge_balance = false;
            sw.density = 1.0253; % kg/l
            sw.pH = 8.22;
            sw.pe = 8.451;
            sw.alkalinity = 141.682;
            sw.alkalinity_component = "HCO3";
        end
        
        function obj = read_json(sol)
            % read_json creates a Solution object from a decoded JSON
            % string
            % input:
            %       sol: decoded JSON string to a Matlab structure
            obj = Solution();

            if isfield(sol, 'Name')
                obj.name = sol.Name;
            end

            if isfield(sol, 'Number')
                obj.number = sol.Number;
            end

            if isfield(sol, 'Unit')
                obj.unit = sol.Unit;
            end

            if isfield(sol, 'Composition')
                obj.components = fieldnames(sol.Composition); % get the list of components
                obj.concentrations = cellfun(@(x)getfield(sol.Composition, {1}, x), obj.components); % get the compositions
            end

            if isfield(sol, 'Charge')
                obj.ph_charge_balance = sol.Charge;
            end

            if isfield(sol, 'ChargeComponent')
                obj.charge_balance_component = sol.ChargeComponent;
            end

            if isfield(sol, 'Density')
                obj.density = sol.Density;
            end

            if isfield(sol, 'DensityCalculation')
                obj.density_calculation = sol.DensityCalculation;
            end

            if isfield(sol, 'Alkalinity')
                obj.alkalinity = sol.Alkalinity;
            end

            if isfield(sol, 'AlkalinityComponent')
                obj.alkalinity_component = sol.AlkalinityComponent;
            end

            if isfield(sol, 'pe')
                obj.pe = sol.pe;
            end

            if isfield(sol, 'Pressure')
                obj.pressure = sol.Pressure;
            end

            if isfield(sol, 'Temperature')
                obj.temperature = sol.Temperature;
            end

            if isfield(sol, 'pH')
                obj.pH = sol.pH;
            end
        end
    end
end

