%% CD-MUSIC surface-complexation models of calcite (chalk)
%
% Runs two published charge-distribution multi-site complexation (CD-MUSIC)
% models of the calcite surface through IPhreeqc and reports the resulting
% surface composition (per-plane surface charge and potential):
%
%   wolthers_cd_music.phr   Wolthers, Charlet & Van Cappellen (2008)  — 5 planes
%   heberling_cd_music.phr  Heberling et al. (2011)                   — 3 planes
%
% Both run with the bundled phreeqc.dat. PHREEQC prints a full "Surface
% composition" section for a CD-MUSIC surface; this script saves the complete
% output next to each input file and prints the surface-charge summary.
%
% Run after startup:
%   run('examples/phreeqc/chalk_cd_music/chalk_cd_music.m')

% Initialize the package if it is not already on the path (locate startup.m by
% walking up from this file, so it works regardless of the current folder).
here = fileparts(mfilename('fullpath'));
if isempty(which('IPhreeqc'))
    d = here;
    while ~isfile(fullfile(d, 'startup.m'))
        parent = fileparts(d);
        if strcmp(parent, d); break; end
        d = parent;
    end
    run(fullfile(d, 'startup.m'));
end
models = { 'Wolthers 2008 (5-plane)', 'wolthers_cd_music.phr'; ...
           'Heberling 2011 (3-plane)', 'heberling_cd_music.phr' };

for k = 1:size(models, 1)
    label = models{k, 1};
    infile = fullfile(here, models{k, 2});

    iph = IPhreeqc();
    iph = iph.CreateIPhreeqc();
    out = iph.RunPhreeqcString(fileread(infile), database_file('phreeqc.dat'));
    iph.DestroyIPhreeqc();

    if isnumeric(out)
        warning('Model "%s" failed to run.', label);
        continue;
    end
    outstr = string(out);

    % Save the full PHREEQC output alongside the input.
    [~, base] = fileparts(infile);
    outfile = fullfile(here, [base '_output.txt']);
    fid = fopen(outfile, 'w');
    fwrite(fid, char(outstr), 'char');
    fclose(fid);

    % Report + sanity check.
    lines = splitlines(outstr);
    fprintf('\n===== %s =====\n', label);
    fprintf('  full output written to %s\n', outfile);
    if any(contains(lines, "ERROR:"))
        warning('  PHREEQC reported an error — see the output file.');
    end

    % Print the per-plane surface charge (the CD-MUSIC signature output).
    charge_lines = lines(contains(lines, "Surface charge") | contains(lines, "surface charge"));
    fprintf('  Surface charge:\n');
    for j = 1:numel(charge_lines)
        fprintf('    %s\n', strtrim(charge_lines(j)));
    end
end

fprintf('\nDone. See the *_output.txt files for the full surface composition.\n');
