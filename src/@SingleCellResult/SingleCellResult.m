classdef SingleCellResult
    % SingleCellResult holds the parsed output of running a @SingleCell in
    % PhreeqcRM. This is a minimal placeholder that loads and can be populated
    % by assignment; the full parsed field set is added in the Milestone 3
    % object-model work (see ROADMAP.md).
    %
    % NOTE: the classdef name must match the @SingleCellResult folder, or
    % MATLAB cannot load the class.

    properties
        name(1,1) string
        temperature(1,1) double
        pressure(1,1) double
    end

    methods
        function obj = SingleCellResult(cell)
            % creates an (empty) result object, optionally seeded from a SingleCell
            if nargin > 0
                obj.name = cell.name;
                obj.temperature = cell.temperature;
                obj.pressure = cell.pressure;
            end
        end
    end
end
