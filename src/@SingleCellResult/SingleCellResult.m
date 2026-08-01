classdef SingleCellResult
    % SingleCellResult holds the parsed output of running a @SingleCell in
    % PhreeqcRM. It always carries the post-reaction aqueous SolutionResult,
    % and — when the cell contained them — the per-phase PhaseResult and the
    % SurfaceResult.
    %
    % NOTE: the classdef name must match the @SingleCellResult folder, or
    % MATLAB cannot load the class.
    %
    % See also SingleCell/run, SolutionResult, PhaseResult, SurfaceResult.

    properties
        name(1,1) string
        temperature(1,1) double
        pressure(1,1) double
        solution                % SolutionResult (aqueous phase after reaction)
        phase                   % PhaseResult, or [] if the cell had no phases
        surface                 % SurfaceResult, or [] if the cell had no surface
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
