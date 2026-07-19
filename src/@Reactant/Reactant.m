classdef Reactant
    %REACTANT abstract base class for Phreeqc reactant definition classes.
    %
    % It unifies the two things every reactant shares — an identity
    % (name/number) and the ability to serialize itself to Phreeqc input —
    % so callers can treat @Solution, @Phase, @Surface, @Gas, @Exchange and
    % @Kinetics polymorphically.
    %
    % Contract:
    %   * concrete subclasses implement phreeqc_string(), returning their
    %     Phreeqc keyword block(s);
    %   * input_string() returns a single char string ready to drop into a
    %     Phreeqc input file. The default calls phreeqc_string(); @Surface
    %     overrides it because it emits three coupled blocks
    %     (SURFACE_MASTER_SPECIES + SURFACE_SPECIES + SURFACE).
    %
    % This is a value class, matching the PhreeqcMatlab reassign-or-lose idiom.
    %
    % See also PhreeqcBlock, Solution, Phase, Surface, Gas.

    properties
        name(1,1) string = "reactant"
        number(1,1) double {mustBeNonnegative, mustBeInteger} = 1
    end

    methods (Abstract)
        % Return the Phreeqc keyword block(s) for this reactant. Output shape
        % is left to the subclass (Surface returns three blocks); use
        % input_string() when a single assembled string is needed.
        phreeqc_string(obj)
    end

    methods
        function str = input_string(obj)
            %INPUT_STRING single-string Phreeqc input for this reactant.
            str = char(string(phreeqc_string(obj)));
        end
    end
end
