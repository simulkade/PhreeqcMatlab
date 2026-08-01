classdef PhaseResult
    % PhaseResult holds the parsed output of equilibrating a @Phase
    % (EQUILIBRIUM_PHASES assemblage) with a solution. The aqueous-phase
    % properties are returned separately as a @SolutionResult; this object
    % holds the per-phase quantities.
    %
    % See also Phase/equilibrate_with, SolutionResult.

    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        phase_names(1,:) string
        moles(1,:) double               % moles of each phase present after reaction
        moles_transferred(1,:) double   % moles dissolved (+) / precipitated (-)
        saturation_indices(1,:) double  % SI of each phase after reaction (~0 if present)
    end

    methods
        function obj = PhaseResult(phase)
            % creates an (empty) result object, optionally seeded from a Phase
            if nargin > 0
                obj.name = phase.name;
                obj.number = phase.number;
                obj.phase_names = phase.phase_names;
            end
        end
    end
end
