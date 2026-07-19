classdef PhreeqcMatlabTest < matlab.unittest.TestCase
    % PHREEQCMATLABTEST assertion-based regression tests for PhreeqcMatlab
    % against PhreeqcRM / IPhreeqc 3.8.6.
    %
    % The golden values are physically grounded, not arbitrary snapshots:
    %   * pure water has pH 7 and ionic strength ~1e-7,
    %   * gypsum is the stable Ca-sulfate at 25 C (SI = 0) while anhydrite is
    %     undersaturated (SI ~ -0.30),
    %   * gypsum solubility is ~15 mmol/L.
    % These double as a signature-drift gate for future PhreeqcRM version bumps.
    %
    % Run (launch MATLAB via ./run_matlab.sh so the 3.8.6 libraries load):
    %   runtests('tests')            % discovers this class
    %   run_all_tests                % wrapper that errors on any failure (for CI)

    properties (Constant)
        DB      = 'phreeqc.dat';
        FIXTURE = 'fixtures/gypsum_anhydrite.pqc';
    end

    methods (TestClassSetup)
        function setupEnv(tc)
            here = fileparts(mfilename('fullpath'));   % .../tests
            root = fileparts(here);
            run(fullfile(root, 'startup.m'));          % path + libraries
            set(0, 'DefaultFigureVisible', 'off');
            % Resolve the fixture to an absolute path so tests are cwd-independent.
            tc.applyFixture(matlab.unittest.fixtures.CurrentFolderFixture(here));
        end
    end

    methods (Test)

        function pureWaterChemistry(tc)
            % IPhreeqc: pure water at 25 C -> pH 7, very low ionic strength.
            iph = IPhreeqc(); iph = iph.CreateIPhreeqc();
            closer = onCleanup(@() iph.DestroyIPhreeqc()); %#ok<NASGU>
            in = sprintf(['SOLUTION 1 Pure water\n pH 7\n temp 25\n' ...
                'SELECTED_OUTPUT 1\n -reset false\n -pH true\n -ionic_strength true\n END']);
            iph.RunPhreeqcString(in, database_file(tc.DB));
            [h, v] = iph.GetSelectedOutputTable(1);
            pH = v(end, h == "pH");
            mu = v(end, h == "mu");
            tc.verifyEqual(pH, 7.0, 'AbsTol', 0.05, 'pure water pH should be ~7');
            tc.verifyLessThan(mu, 1e-6, 'pure water ionic strength should be ~1e-7');
        end

        function gypsumAnhydriteSI_IPhreeqc(tc)
            % IPhreeqc: equilibrating pure water with gypsum + anhydrite.
            iph = IPhreeqc(); iph = iph.CreateIPhreeqc();
            closer = onCleanup(@() iph.DestroyIPhreeqc()); %#ok<NASGU>
            in = sprintf(['SOLUTION 1 Pure water\n pH 7\n temp 25\n' ...
                'EQUILIBRIUM_PHASES 1\n Gypsum 0.0 1.0\n Anhydrite 0.0 1.0\n' ...
                'SELECTED_OUTPUT 1\n -reset false\n -si Anhydrite Gypsum\n END']);
            iph.RunPhreeqcString(in, database_file(tc.DB));
            [h, v] = iph.GetSelectedOutputTable(1);
            siGypsum    = v(end, h == "si_Gypsum");
            siAnhydrite = v(end, h == "si_Anhydrite");
            tc.verifyEqual(siGypsum, 0.0, 'AbsTol', 0.01, 'gypsum should be at equilibrium (SI=0)');
            tc.verifyEqual(siAnhydrite, -0.3045, 'AbsTol', 0.02, 'anhydrite should be undersaturated');
        end

        function singleCellComponentsAndSolubility(tc)
            % PhreeqcSingleCell (Layer-2 entry point): components, selected
            % output, and concentrations for the same gypsum/anhydrite system.
            phrm = PhreeqcSingleCell(tc.FIXTURE, tc.DB);
            closer = onCleanup(@() phrm.RM_Destroy()); %#ok<NASGU>

            cc0   = string(phrm.GetComponents());
            comps = sort(cc0(:));                             % column, order-independent
            tc.verifyEqual(comps, sort(["H";"O";"Charge";"Ca";"S"]), ...
                'unexpected component set');

            h  = string(phrm.GetSelectedOutputHeadings(1));
            v  = phrm.GetSelectedOutput(1);
            tc.verifyEqual(v(h == "si_Gypsum"), 0.0, 'AbsTol', 0.01);
            tc.verifyEqual(v(h == "si_Anhydrite"), -0.3045, 'AbsTol', 0.02);

            % Gypsum solubility: Ca and S both ~15 mmol/L (mol/L units).
            conc = phrm.GetConcentrations();
            tc.verifySize(conc, [1 numel(comps)]);
            tc.verifyTrue(all(isfinite(conc)), 'concentrations must be finite');
            ca = conc(string(phrm.GetComponents()) == "Ca");
            s  = conc(string(phrm.GetComponents()) == "S");
            tc.verifyEqual(ca, 0.0150, 'AbsTol', 0.001, 'Ca ~ gypsum solubility');
            tc.verifyEqual(s,  0.0150, 'AbsTol', 0.001, 'S ~ gypsum solubility');
            tc.verifyEqual(ca, s, 'AbsTol', 1e-4, 'Ca and SO4 released 1:1 by gypsum');
        end

        function solutionObjectStringWellFormed(tc)
            % Layer-3 object model: phreeqc_string() must be deterministic and
            % well-formed (no native call). Guards the string-builder fixes.
            s = Solution();
            s.unit = "mol/kgw";
            s.components = ["Na" "Cl"];
            s.concentrations = [1.0 1.0];
            s.pH = 7.0; s.pe = 4.0; s.density = 1.0;
            str = s.phreeqc_string();
            tc.verifyClass(str, 'char');
            tc.verifySubstring(str, 'SOLUTION');
            tc.verifySubstring(str, 'Na');
            tc.verifySubstring(str, 'Cl');
            tc.verifySubstring(str, 'END');
        end

    end
end
