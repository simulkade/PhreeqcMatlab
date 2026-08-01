classdef Reactant
    %REACTANT abstract base class for Phreeqc reactant definition classes.
    %
    % It unifies the three things every reactant shares — an identity
    % (name/number), the ability to serialize itself to Phreeqc input, and a
    % PhreeqcRM initial-condition slot — so callers can treat @Solution,
    % @Phase, @Surface, @Gas, @Exchange and @Kinetics polymorphically.
    %
    % Contract:
    %   * concrete subclasses implement phreeqc_string(), returning their
    %     Phreeqc keyword block(s);
    %   * input_string() returns a single char string ready to drop into a
    %     Phreeqc input file. The default calls phreeqc_string(); @Surface
    %     overrides it because it emits three coupled blocks
    %     (SURFACE_MASTER_SPECIES + SURFACE_SPECIES + SURFACE).
    %   * ic_slot() returns the RM_InitialPhreeqc2Module slot this reactant
    %     occupies (an InitialConditions.* constant), or [] for reactants that
    %     cannot be placed in a cell on their own. equilibrate_with() uses it.
    %
    % equilibrate_with(solution) is a template method built on input_string():
    % it assembles {solution + this reactant + the solution's selected output},
    % runs a single PhreeqcRM cell, and returns the post-reaction aqueous
    % SolutionResult. Subclasses that need a richer result (Surface, Phase)
    % override it, typically reusing the protected run_with_solution() helper.
    %
    % This is a value class, matching the PhreeqcMatlab reassign-or-lose idiom.
    %
    % See also PhreeqcBlock, InitialConditions, Solution, Phase, Surface, Gas.

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

        function slot = ic_slot(~)
            %IC_SLOT the RM_InitialPhreeqc2Module slot for this reactant.
            % Default []; concrete placeable subclasses override with an
            % InitialConditions.* constant (SOLUTION, EQUILIBRIUM_PHASES, ...).
            slot = [];
        end

        function [SR, phreeqc_rm] = equilibrate_with(obj, solution, varargin)
            %EQUILIBRATE_WITH equilibrate this reactant with a Solution in
            % PhreeqcRM and return the post-reaction aqueous SolutionResult.
            %   SR = reactant.equilibrate_with(solution)
            %   SR = reactant.equilibrate_with(solution, 'phreeqc.dat')
            % The second output is the (already destroyed) PhreeqcRM handle,
            % kept for signature symmetry with subclass overrides.
            if ~isempty(varargin)
                data_file = char(varargin{end});
            else
                data_file = 'phreeqc.dat';
            end
            phreeqc_rm = obj.run_with_solution(solution, ...
                solution.selected_output_string(), data_file);
            try
                SR = solution.results_from_phreeqcrm(phreeqc_rm);
            catch ME
                phreeqc_rm.RM_Destroy();
                rethrow(ME);
            end
            phreeqc_rm.RM_Destroy();
        end
    end

    methods (Access = protected)
        function phreeqc_rm = run_with_solution(obj, solution, so_string, data_file)
            %RUN_WITH_SOLUTION assemble {solution + this reactant + selected
            % output}, run one PhreeqcRM cell, and return the initialized
            % module (caller is responsible for RM_Destroy). Centralizes the
            % RM boilerplate shared by every reactant equilibration.
            slot = obj.ic_slot();
            if isempty(slot)
                error('PhreeqcMatlab:notPlaceable', ...
                    '%s cannot be equilibrated with a solution (no initial-condition slot).', ...
                    class(obj));
            end
            if nargin < 4 || isempty(data_file); data_file = 'phreeqc.dat'; end

            phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread (constructor calls RM_Create)
            definition = combine_phreeqc_strings(solution.phreeqc_string(), obj.input_string());
            if nargin >= 3 && ~PhreeqcBlock.isEmptyValue(so_string)
                definition = combine_phreeqc_strings(definition, so_string);
            end
            try
                phreeqc_rm.RM_LoadDatabase(database_file(data_file));
                phreeqc_rm.RM_RunString(true, true, true, definition);
                phreeqc_rm.RM_SetSelectedOutputOn(true);
                phreeqc_rm.RM_SetComponentH2O(true);
                phreeqc_rm.RM_SetUnitsSolution(2);
                phreeqc_rm.RM_SetSpeciesSaveOn(true);
                phreeqc_rm.RM_FindComponents();   % required before RunCells

                ic1 = -1 * ones(InitialConditions.N_REACTANTS, 1);
                ic2 = -1 * ones(InitialConditions.N_REACTANTS, 1);
                f1  = ones(InitialConditions.N_REACTANTS, 1);
                ic1(InitialConditions.SOLUTION) = solution.number;
                ic1(slot) = obj.number;
                phreeqc_rm.RM_InitialPhreeqc2Module(ic1, ic2, f1);
                phreeqc_rm.RM_RunCells();
            catch ME
                phreeqc_rm.RM_Destroy();
                rethrow(ME);
            end
        end
    end
end
