% This is an example of how to read a json file in matlab
% It is not meant to be called from here. Each PhreeqcMatlab object has it
% own read_json method.
% read the file as a text file
s = fileread('..\..\examples\data\json_sample.json');
% decode to json structure
b = jsondecode(s);
% Then we can use fieldnames, getfield and isfield to extract the required information
comp = fieldnames(b.Solution.Seawater.Composition); % get the list of components
x = cellfun(@(x)getfield(b.Solution.Seawater.Composition, {1}, x), comp); % get the compositions

% it is safer to check for the existence of a field before using it
if isfield(b, 'Solution') % is solutions are defined
    sol = b.Solution.Seawater; % assign all solutions to variable sol
end

% Example: create a solution object from a JSON entry:
% Here are the properties of a solution object
%  properties
%     name(1,1) string
%     number(1,1) double {mustBeNonnegative, mustBeInteger}
%     unit(1,1) string
%     components(1,:) string
%     concentrations(1,:) double
%     charge_balance_component(1,1) string
%     ph_charge_balance(1,1) {mustBeNumericOrLogical}
%     density(1,1) double
%     density_calculation(1,1) {mustBeNumericOrLogical}
%     pH {mustBeScalarOrEmpty} = []
%     pe {mustBeScalarOrEmpty} = []
%     alkalinity {mustBeScalarOrEmpty} = []
%     alkalinity_component(1,1) string
%     pressure {mustBeScalarOrEmpty}
%     temperature {mustBeScalarOrEmpty}
% end

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