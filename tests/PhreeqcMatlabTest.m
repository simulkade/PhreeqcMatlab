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

        function mapValueSafeLookup(tc)
            % map_value degrades to a fallback instead of throwing on a
            % missing SELECTED_OUTPUT column key.
            m = containers.Map({'a','b'}, {1, 2});
            tc.verifyEqual(map_value(m, 'a'), 1);
            tc.verifyTrue(isnan(map_value(m, 'missing')));
            tc.verifyEqual(map_value(m, 'missing', 0), 0);
        end

        function solutionRunResults(tc)
            % Solution.run() -> SolutionResult via results_from_phreeqcrm
            % (header-keyed parsing). Verifies the PhreeqcRM object path and
            % that fields are populated with physically sensible values.
            sol = Solution(); sol.unit = "mol/kgw";
            sol.components = ["Na" "Cl"]; sol.concentrations = [1 1];
            sol.pH = 7; sol.ph_charge_balance = true;
            SR = sol.run('phreeqc.dat');
            tc.verifyClass(SR, 'SolutionResult');   % not the failure sentinel 0
            tc.verifyEqual(SR.temperature, 25, 'AbsTol', 1);
            tc.verifyGreaterThan(SR.ionic_strength, 0);
            tc.verifyGreaterThan(SR.water_mass, 0);
            tc.verifyLessThan(abs(SR.percent_error), 5);
            tc.verifyTrue(ismember("Na", SR.components));
        end

        function initialConditionsHelper(tc)
            % InitialConditions centralizes the reactant-slot mapping + input
            % scan that PhreeqcSingleCell / InitializePhreeqc* used to duplicate.
            C = ["SOLUTION 1"; "EQUILIBRIUM_PHASES 1"; "Calcite 0 1"; ...
                 "SURFACE 1"; "GAS_PHASE 1"];
            p = InitialConditions.detect(C);
            tc.verifyTrue(p(InitialConditions.SOLUTION));
            tc.verifyTrue(p(InitialConditions.EQUILIBRIUM_PHASES));
            tc.verifyTrue(p(InitialConditions.SURFACE));
            tc.verifyTrue(p(InitialConditions.GAS_PHASE));
            tc.verifyFalse(p(InitialConditions.EXCHANGE));
            tc.verifyFalse(p(InitialConditions.KINETICS));
            tc.verifyFalse(p(InitialConditions.SOLID_SOLUTIONS));

            % Single cell: present -> block 1, absent -> -1 (old behavior).
            [ic1, ic2, f1] = InitialConditions.vectors(p, 1);
            tc.verifySize(ic1, [1 7]);
            tc.verifyEqual(ic1(InitialConditions.SOLUTION), 1);
            tc.verifyEqual(ic1(InitialConditions.EXCHANGE), -1);
            tc.verifyEqual(ic2, -1*ones(1,7));
            tc.verifyEqual(f1, ones(1,7));

            % Multi cell: present column -> 1:nxyz, absent -> -1 (old behavior).
            [ic1m, ~, ~] = InitialConditions.vectors(p, 5);
            tc.verifySize(ic1m, [5 7]);
            tc.verifyEqual(ic1m(:, InitialConditions.SOLUTION), (1:5)');
            tc.verifyEqual(ic1m(:, InitialConditions.EXCHANGE), -1*ones(5,1));
        end

        function reactantPolymorphism(tc)
            % All definition classes share the Reactant identity/contract and
            % can be serialized uniformly through input_string().
            classes = {@Solution, @Phase, @Surface, @Gas, @Exchange, @Kinetics};
            for f = classes
                o = f{1}();
                tc.verifyTrue(isa(o, 'Reactant'));
                tc.verifyGreaterThan(strlength(o.name), 0);
            end
            % Concrete reactants produce a usable single input string...
            for f = {@Solution, @() Phase.chalk(), @() Gas.damp_CO2(), @() Surface.calcite_surface()}
                s = f{1}().input_string();
                tc.verifyClass(s, 'char');
                tc.verifyNotEmpty(s);
            end
            % ...and Surface assembles its three coupled blocks in order.
            si = Surface.calcite_surface().input_string();
            tc.verifySubstring(si, 'SURFACE_MASTER_SPECIES');
            tc.verifySubstring(si, 'SURFACE_SPECIES');
            % Not-yet-implemented reactants fail loudly, not silently.
            tc.verifyError(@() Exchange().phreeqc_string(), 'PhreeqcMatlab:notImplemented');
            tc.verifyError(@() Kinetics().phreeqc_string(), 'PhreeqcMatlab:notImplemented');
        end

        function stringBuilder(tc)
            % PhreeqcBlock: header, empty-field suppression, vector + optional
            % value formatting (no native call).
            b = PhreeqcBlock("SOLUTION", 1, "sw");
            b = b.kv("units", "mol/kgw");
            b = b.kv("pH", 8.1, "charge");
            b = b.kv("pe", []);              % empty -> suppressed
            b = b.kv("Na", 0.48);
            b = b.kvopt("-diffuse_layer", []);   % flag alone when empty
            b = b.kv("-capacitances", [1.3 4.5]);
            s = b.char();
            tc.verifyClass(s, 'char');
            tc.verifySubstring(s, sprintf('SOLUTION 1 sw'));
            tc.verifySubstring(s, sprintf('pH    8.1    charge'));
            tc.verifyEmpty(regexp(s, '^\s*pe\b', 'once', 'lineanchors'), ...
                'empty pe must be suppressed');
            tc.verifySubstring(s, sprintf('-capacitances    1.3 4.5'));
            tc.verifyTrue(any(strcmp(strsplit(s, newline), '-diffuse_layer')), ...
                'kvopt with empty value should emit the flag alone');
        end

        function surfaceStringRoundTrip(tc)
            % The refactored Surface.phreeqc_string must produce blocks PHREEQC
            % parses without error (guards the fragile cd_music/capacitances
            % vector formatting). Exercises both EDL variants.
            for f = {@Surface.calcite_surface, @Surface.calcite_surface_cd_music}
                surf = f{1}();
                [ss, sms, sps] = surf.phreeqc_string();
                iph = IPhreeqc(); iph = iph.CreateIPhreeqc();
                closer = onCleanup(@() iph.DestroyIPhreeqc()); %#ok<NASGU>
                sol = ['SOLUTION 1' newline ' units mol/kgw' newline ' pH 8 charge' ...
                       newline ' Ca 0.01' newline ' C 0.01' newline ' Na 0.1' newline ' Cl 0.1'];
                full = sprintf('%s\n%s\n%s\n%s\nEND\n', sms, sps, sol, ss);
                out = iph.RunPhreeqcString(full, database_file(tc.DB));
                tc.verifyFalse(contains(string(out), "ERROR:"), ...
                    'Surface block should parse without a PHREEQC error');
                clear closer;
            end
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
