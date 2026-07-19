classdef PhaseResult
    % PhaseResult holds the parsed output of equilibrating a @Phase object
    % with a solution. This is a minimal placeholder that loads and can be
    % populated by assignment; the full parsed field set is added in the
    % Milestone 3 object-model work (see ROADMAP.md).

    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
    end

    methods
        function obj = PhaseResult(phase)
            % creates an (empty) result object, optionally seeded from a Phase
            if nargin > 0
                obj.name = phase.name;
                obj.number = phase.number;
            end
        end
    end
end
