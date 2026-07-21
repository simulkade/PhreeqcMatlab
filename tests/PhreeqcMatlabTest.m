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

        function pqmParser1D(tc)
            % ParsePqmConfig reads a 1D advection .pqm (cells/shifts form).
            cfg = ParsePqmConfig('../examples/transport/ex11_simple_phreeqc_matlab.pqm');
            tc.verifyEqual(cfg.transport.cells, 40);
            tc.verifyEqual(cfg.transport.shifts, 10);
            tc.verifyEqual(cfg.transport.ncells, 40);
            tc.verifyEqual(cfg.transport.time_step, 1.0, 'AbsTol', 1e-12);
            tc.verifyEqual(cfg.rm.threads, 2);
            tc.verifyEqual(cfg.rm.units_solution, 2);
            tc.verifyEqual(string(cfg.rm.data_base), "phreeqc.dat");
        end

        function pqmParser2D(tc)
            % ParsePqmConfig reads a multi-D grid .pqm (Nx/Ny/Lx/Ly form) and
            % derives the total cell count.
            cfg = ParsePqmConfig('../src/FVTool/sample_initialize_fvtool.pqm');
            tc.verifyEqual(cfg.transport.dimension, 2);
            tc.verifyEqual(cfg.transport.nx, 20);
            tc.verifyEqual(cfg.transport.ny, 15);
            tc.verifyEqual(cfg.transport.lx, 1.0, 'AbsTol', 1e-12);
            tc.verifyEqual(cfg.transport.ly, 2.0, 'AbsTol', 1e-12);
            tc.verifyEqual(cfg.transport.ncells, 300);   % 20 * 15
            tc.verifyEqual(cfg.transport.initial_porosity, 0.4, 'AbsTol', 1e-12);
            tc.verifyEqual(cfg.rm.threads, 4);
            tc.verifyEqual(string(cfg.rm.data_base), "phreeqc.dat");
        end

        function fvtoolGuard(tc)
            % The multi-D driver fails with a clear, actionable error when the
            % optional FVTool package is not installed.
            if fvtool_available()
                tc.assumeFail('FVTool is installed; guard path not exercised.');
            end
            tc.verifyError(@() PhreeqcFVToolTransport('x.pqc', 'y.pqm'), ...
                'PhreeqcMatlab:fvtoolMissing');
        end

        function reactiveTransport2D(tc)
            % End-to-end 2D reactive transport (FVTool + PhreeqcRM), a 2D
            % version of PHREEQC example 11: a CaCl2 solution flushes a column
            % initially in Na/K exchange equilibrium. Runs only when FVTool is
            % available (startup provisions it into external/FVTool).
            if ~fvtool_available()
                tc.assumeFail('FVTool not available; skipping 2D transport test.');
            end
            pqc = '../examples/transport/reactive_transport_2d_input.pqc';
            pqm = '../examples/transport/reactive_transport_2d.pqm';
            [rm, c_hist] = PhreeqcFVToolTransport(pqc, pqm);
            closer = onCleanup(@() rm.RM_Destroy()); %#ok<NASGU>
            comps = string(rm.GetComponents());
            tc.verifySize(c_hist, [20 numel(comps) 13]);   % 20 cells, shifts+1
            tc.verifyTrue(all(isfinite(c_hist(:))), 'concentrations must be finite');
            na = find(comps == "Na", 1);
            ca = find(comps == "Ca", 1);
            cl = find(comps == "Cl", 1);
            % CaCl2 inflow displaces Na from the exchanger and brings in Ca.
            tc.verifyLessThan(mean(c_hist(:, na, end)), mean(c_hist(:, na, 1)), ...
                'Na should be flushed/displaced out of solution');
            tc.verifyGreaterThan(mean(c_hist(:, ca, end)), mean(c_hist(:, ca, 1)), ...
                'Ca should break through from the CaCl2 inflow');
            tc.verifyGreaterThan(mean(c_hist(:, cl, end)), 0, 'Cl present after flushing');
        end

        function newApi386Getters(tc)
            % The PhreeqcRM 3.8.6 non-BMI getters (unlocked by shipping the
            % 3.8.6 header) return physically-correct values for water at 25 C.
            phrm = PhreeqcSingleCell(tc.FIXTURE, tc.DB);
            closer = onCleanup(@() phrm.RM_Destroy()); %#ok<NASGU>
            T   = phrm.GetTemperature();
            por = phrm.GetPorosity();
            rho = phrm.GetDensityCalculated();
            p   = phrm.GetPressure();
            mu  = phrm.GetViscosity();
            tc.verifySize(T, [1 1]);                         % nxyz = 1
            tc.verifyEqual(T(1),   25.0,   'AbsTol', 1.0,  'temperature ~25 C');
            tc.verifyEqual(p(1),   1.0,    'AbsTol', 0.1,  'pressure ~1 atm');
            tc.verifyGreaterThan(por(1), 0,               'porosity must be positive');
            tc.verifyEqual(rho(1), 0.9970, 'AbsTol', 0.01, 'water density ~0.997 kg/L');
            tc.verifyEqual(mu(1),  0.8999, 'AbsTol', 0.02, 'water viscosity ~0.90 mPa s');
            tc.verifyEqual(phrm.RM_GetCurrentSelectedOutputUserNumber(), 1);
        end

        function jsonRoundTrip(tc)
            % Solution JSON read (assign_json_fields) + write (to_struct) round-trip.
            sol = Solution.from_json("NorthSeawater");
            tc.verifyEqual(sol.name, "Seawater");
            tc.verifyEqual(sol.number, 1);
            tc.verifyEqual(sol.unit, "mol/L");
            tc.verifyEqual(sol.pH, 8.4, 'AbsTol', 1e-9);
            tc.verifyEqual(numel(sol.components), 6);
            tc.verifyTrue(ismember("Na", sol.components));

            tmp = [tempname '.json'];
            sol.write_json(tmp);
            closer = onCleanup(@() delete(tmp)); %#ok<NASGU>
            sol2 = Solution.read_json(jsondecode(fileread(tmp)));
            tc.verifyEqual(sol2.name, sol.name);
            tc.verifyEqual(sol2.pH, sol.pH, 'AbsTol', 1e-9);
            tc.verifyEqual(numel(sol2.components), numel(sol.components));
            tc.verifyEqual(sort(sol2.components), sort(sol.components));
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
            for f = {@Solution, @() Phase.chalk(), @() Gas.damp_CO2(), ...
                     @() Surface.calcite_surface(), @() Exchange.sodium_exchanger(), ...
                     @() Kinetics.calcite()}
                s = f{1}().input_string();
                tc.verifyClass(s, 'char');
                tc.verifyNotEmpty(s);
            end
            % ...and Surface assembles its three coupled blocks in order.
            si = Surface.calcite_surface().input_string();
            tc.verifySubstring(si, 'SURFACE_MASTER_SPECIES');
            tc.verifySubstring(si, 'SURFACE_SPECIES');
            % Each reactant reports the initial-condition slot it occupies.
            tc.verifyEqual(Solution().ic_slot(), InitialConditions.SOLUTION);
            tc.verifyEqual(Phase().ic_slot(), InitialConditions.EQUILIBRIUM_PHASES);
            tc.verifyEqual(Exchange().ic_slot(), InitialConditions.EXCHANGE);
            tc.verifyEqual(Surface().ic_slot(), InitialConditions.SURFACE);
            tc.verifyEqual(Gas().ic_slot(), InitialConditions.GAS_PHASE);
            tc.verifyEqual(Kinetics().ic_slot(), InitialConditions.KINETICS);
            % Empty definition classes serialize to '' (skippable in a SingleCell).
            tc.verifyEmpty(Exchange().phreeqc_string());
            tc.verifyEmpty(Kinetics().phreeqc_string());
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

        function cdMusicChalkSurface(tc)
            % CD-MUSIC reference case: the Wolthers (2008) 5-plane calcite
            % surface model runs in IPhreeqc and reproduces the published
            % per-plane surface charges. Guards the CD-MUSIC -cd_music handling
            % (charge distribution over electrostatic planes + capacitances).
            infile = '../examples/phreeqc/chalk_cd_music/wolthers_cd_music.phr';
            iph = IPhreeqc(); iph = iph.CreateIPhreeqc();
            closer = onCleanup(@() iph.DestroyIPhreeqc()); %#ok<NASGU>
            out = iph.RunPhreeqcString(fileread(infile), database_file(tc.DB));
            tc.verifyClass(out, 'char');
            lines = splitlines(string(out));
            tc.verifyFalse(any(contains(lines, "ERROR:")), 'CD-MUSIC model should run cleanly');

            plane0 = surface_charge_value(lines, "plane 0");
            plane1 = surface_charge_value(lines, "plane 1");
            plane2 = surface_charge_value(lines, "plane 2");
            total  = surface_charge_value(lines, "all planes");
            tc.verifyEqual(plane0, -1.232e-6, 'RelTol', 0.02, 'plane-0 surface charge');
            tc.verifyEqual(plane1,  2.890e-6, 'RelTol', 0.02, 'plane-1 surface charge');
            tc.verifyEqual(plane2,  0.0,      'AbsTol', 1e-12, 'plane-2 surface charge');
            tc.verifyEqual(total,   1.657e-6, 'RelTol', 0.02, 'summed surface charge');
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

        function phaseEquilibrateWith(tc)
            % @Phase.equilibrate_with: pure water + gypsum/anhydrite ->
            % PhaseResult (gypsum SI 0, anhydrite SI -0.30) + SolutionResult.
            ph = Phase();
            ph.name = "gyp"; ph.number = 1;
            ph.phase_names = ["Gypsum" "Anhydrite"];
            ph.saturation_indices = [0 0];
            ph.moles = [1 1];
            [PR, SR] = ph.equilibrate_with(Solution(), tc.DB);
            tc.verifyClass(PR, 'PhaseResult');
            tc.verifyClass(SR, 'SolutionResult');
            gi = PR.phase_names == "Gypsum";
            ai = PR.phase_names == "Anhydrite";
            tc.verifyEqual(PR.saturation_indices(gi), 0.0, 'AbsTol', 0.01, 'gypsum at equilibrium');
            tc.verifyEqual(PR.saturation_indices(ai), -0.3045, 'AbsTol', 0.02, 'anhydrite undersaturated');
            tc.verifyLessThan(abs(SR.percent_error), 5);
        end

        function exchangeEquilibrateWith(tc)
            % @Exchange (default phreeqc.dat "X"): equilibrating an exchanger
            % with seawater (the standard PHREEQC exchange example) returns a
            % valid SolutionResult.
            ex = Exchange.sodium_exchanger(0.001);
            SR = ex.equilibrate_with(Solution.seawater(), tc.DB);
            tc.verifyClass(SR, 'SolutionResult');
            tc.verifyTrue(ismember("Na", SR.components));
            tc.verifyLessThan(abs(SR.percent_error), 5);
            % A custom exchanger definition must serialize its three blocks.
            s = Exchange.from_json("GaineHomogeneous").input_string();
            tc.verifySubstring(s, 'EXCHANGE_MASTER_SPECIES');
            tc.verifySubstring(s, 'EXCHANGE_SPECIES');
            tc.verifySubstring(s, 'EXCHANGE');
        end

        function kineticsRunInPhreeqc(tc)
            % @Kinetics.calcite: the RATES + KINETICS blocks integrate in
            % IPhreeqc over -steps without a PHREEQC parse/run error.
            k = Kinetics.calcite();
            in = k.input_string();
            tc.verifySubstring(in, 'RATES');
            tc.verifySubstring(in, 'KINETICS');
            tc.verifySubstring(in, '-steps');
            out = k.equilibrate_in_phreeqc(Solution.seawater(), tc.DB);
            tc.verifyClass(out, 'char');       % not the failure sentinel 0
            tc.verifyFalse(contains(string(out), "ERROR:"), ...
                'kinetics block should run without a PHREEQC error');
        end

        function gasEquilibrate(tc)
            % @Gas: JSON round-trip + equilibration of damp CO2 with seawater.
            g = Gas.damp_CO2();
            tc.verifyEqual(numel(g.phase_names), 2);
            tc.verifyTrue(ismember("CO2(g)", g.phase_names));
            out = g.equilibrate_in_phreeqc(Solution.seawater(), tc.DB);
            tc.verifyClass(out, 'char');
            tc.verifyFalse(contains(string(out), "ERROR:"), ...
                'gas block should run without a PHREEQC error');
        end

        function singleCellRun(tc)
            % @SingleCell.run (capstone): solution + equilibrium phases in one
            % PhreeqcRM cell -> SingleCellResult with aqueous + phase results.
            ph = Phase();
            ph.name = "gyp"; ph.number = 1;
            ph.phase_names = ["Gypsum" "Anhydrite"];
            ph.saturation_indices = [0 0];
            ph.moles = [1 1];
            sc = SingleCell(Solution(), 'equilibrium_phase', ph, 'data_base', tc.DB);
            R = sc.run();
            tc.verifyClass(R, 'SingleCellResult');   % not the failure sentinel 0
            tc.verifyClass(R.solution, 'SolutionResult');
            tc.verifyClass(R.phase, 'PhaseResult');
            gi = R.phase.phase_names == "Gypsum";
            tc.verifyEqual(R.phase.saturation_indices(gi), 0.0, 'AbsTol', 0.01);
            tc.verifyGreaterThan(R.solution.water_mass, 0);
        end

        function reactantJsonFactories(tc)
            % from_json factories build the expected objects for the new classes.
            ex = Exchange.from_json("SodiumExchanger");
            tc.verifyEqual(ex.exchange_species, "X");
            tc.verifyEqual(ex.moles, 1.0, 'AbsTol', 1e-12);

            k = Kinetics.from_json("CalciteKinetics");
            tc.verifyEqual(k.reaction_names, "Calcite");
            tc.verifyEqual(k.step_count, 10);
            tc.verifyGreaterThan(strlength(k.rates_definition), 0);

            g = Gas.from_json("FlueGas");
            tc.verifyEqual(numel(g.phase_names), 3);
            tc.verifyFalse(g.fixed_pressure);
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

% -------------------------------------------------------------------------
function v = surface_charge_value(lines, tag)
%SURFACE_CHARGE_VALUE first "<value>  ...charge, <tag>, eq" from PHREEQC output.
% Case-insensitive on "charge" so it matches both "Surface charge, plane N" and
% "Sum of surface charge, all planes".
row = lines(contains(lines, "charge", 'IgnoreCase', true) & contains(lines, tag));
tok = sscanf(strtrim(row(1)), '%g');
v = tok(1);
end
