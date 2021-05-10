classdef solution
    %SOLUTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        number
        unit
        components
        concentrations
        charge_balance_component
        ph_charge_balance
        density
        pH
        pe
        alkalinity
        alkalinity_component
        pressure
        temperature
    end
    
    methods
        function obj = solution()
            %SOLUTION Construct an instance of this class
            % currently, it constructs an empty class (pure water)
            % the preferred method of initializing its fields is manually or 
            % from an input file or from one of the predefined solutions
            obj.name = "Pure Water";
            obj.number = 1;
            obj.temperature = 25.0; % degree Celcius
            obj.pressure = 1.0;     % atmosphere
        end
        
        function obj = seawater(obj)
            % defiene a seawater solution
            % Note: convert it to static method
            % currently:
            % sw = solution();
            % sw = sw.seawater(); % this is more elegant with static method
            obj.name = "Seawater";
            obj.number = 1;
            obj.unit = "ppm";
            obj.components = ["Ca", "Mg", "Na", "K", "Si", "Cl", "S(6)"];
            obj.concentrations = [412.3, 1291.8, 10768.0, 399.1, 4.28, 19353.0, 2712.0];
            obj.charge_balance_component = [];
            obj.ph_charge_balance = false;
            obj.density = 1.0253; % kg/l
            obj.pH = 8.22;
            obj.pe = 8.451;
            obj.alkalinity = 141.682;
            obj.alkalinity_component = "HCO3";
%                 units   ppm
%                 pH      8.22
%                 pe      8.451
%                 density 1.023
%                 temp    25.0
%                 Ca              412.3
%                 Mg              1291.8
%                 Na              10768.0
%                 K               399.1
%                 Si              4.28
%                 Cl              19353.0
%                 Alkalinity      141.682 as HCO3
%                 S(6)            2712.0
        end
        
        function solution_string = phreeqc_solution(obj)
            %phreeqc_solution returns a string of phreeqc format for the
            %defined PhreeqcMatlab solution
            % NOTE: at this stage, a phreeqc string can contain more
            % details than that the equivalent PhreeqcMatlab solution
            % object
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
                if ~isempty(obj.alkalinity_component)
                    solution_string = strjoin([solution_string 'Alkalinity' num2str(obj.alkalinity) "  as  " obj.alkalinity_component "\n"]);
                else
                    solution_string = strjoin([solution_string 'Alkalinity' num2str(obj.alkalinity) "\n"]);
            
                end
            end
                
            
        end
    end
end

