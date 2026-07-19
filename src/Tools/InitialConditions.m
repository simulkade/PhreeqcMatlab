classdef InitialConditions
    %INITIALCONDITIONS builds the reactant initial-condition arrays that
    % RM_InitialPhreeqc2Module expects, and centralizes the reactant-block
    % slot mapping that was previously duplicated (as bare magic indices and a
    % copy-pasted keyword scan) across PhreeqcSingleCell, InitializePhreeqc-
    % Advection and InitializePhreeqcFVTool.
    %
    % The seven reactant slots, in PhreeqcRM order:
    %   1 SOLUTION  2 EQUILIBRIUM_PHASES  3 EXCHANGE  4 SURFACE
    %   5 GAS_PHASE 6 SOLID_SOLUTIONS     7 KINETICS
    %
    % Typical use (scan a cleaned input file, one block per reactant per cell):
    %   C = ReadPhreeqcFile(input_file);
    %   [ic1, ic2, f1] = InitialConditions.from_input(C, nxyz);
    %   phreeqc_rm.RM_InitialPhreeqc2Module(ic1, ic2, f1);

    properties (Constant)
        SOLUTION           = 1
        EQUILIBRIUM_PHASES = 2
        EXCHANGE           = 3
        SURFACE            = 4
        GAS_PHASE          = 5
        SOLID_SOLUTIONS    = 6
        KINETICS           = 7
        N_REACTANTS        = 7
    end

    methods (Static)
        function present = detect(C)
            %DETECT which reactant blocks appear in cleaned input lines C.
            % Returns a 1x7 logical indexed by the slot constants above.
            % The keyword synonyms match the PhreeqcRM manual (and preserve the
            % exact scan the callers used before centralization).
            has = @(kw) any(contains(C, kw));
            present = false(1, InitialConditions.N_REACTANTS);
            present(InitialConditions.SOLUTION)           = has('SOLUTION');
            present(InitialConditions.EQUILIBRIUM_PHASES) = has('EQUILIBRIUM_PHASES') || ...
                has('EQUILIBRIUM') || has(' EQUILIBRIA') || has(' PURE_PHASES') || has(' PURE');
            present(InitialConditions.EXCHANGE)           = has('EXCHANGE');
            present(InitialConditions.SURFACE)            = has('SURFACE');
            present(InitialConditions.GAS_PHASE)          = has('GAS_PHASE');
            present(InitialConditions.SOLID_SOLUTIONS)    = has('SOLID_SOLUTION');
            present(InitialConditions.KINETICS)           = has('KINETICS');
        end

        function [ic1, ic2, f1] = vectors(present, nxyz)
            %VECTORS assemble ic1/ic2/f1 for nxyz cells from a 1x7 presence mask.
            % Present blocks map reaction cell i -> block number i (1..nxyz);
            % absent blocks are -1 (skipped). ic2 = -1 (no second solution to
            % mix), f1 = 1 (full mixing fraction). Shape is nxyz-by-7, i.e. the
            % Fortran (nxyz, ncomps) storage RM_InitialPhreeqc2Module expects;
            % for a single cell this is 1-by-7.
            if nargin < 2 || isempty(nxyz); nxyz = 1; end
            n = InitialConditions.N_REACTANTS;
            ic1 = -1 * ones(nxyz, n);
            ic2 = -1 * ones(nxyz, n);
            f1  = ones(nxyz, n);
            cellnums = (1:nxyz)';
            for k = 1:n
                if present(k)
                    ic1(:, k) = cellnums;
                end
            end
        end

        function [ic1, ic2, f1] = from_input(C, nxyz)
            %FROM_INPUT convenience: detect() then vectors().
            if nargin < 2 || isempty(nxyz); nxyz = 1; end
            [ic1, ic2, f1] = InitialConditions.vectors(InitialConditions.detect(C), nxyz);
        end
    end
end
