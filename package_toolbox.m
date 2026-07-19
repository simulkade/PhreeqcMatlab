function mltbx = package_toolbox(version)
%PACKAGE_TOOLBOX builds a PhreeqcMatlab.mltbx MATLAB Toolbox package.
%
%   package_toolbox            % uses the default version below
%   package_toolbox("0.2.0")   % override the version string
%
% The package bundles the source, databases, path setup, tests, examples and
% the C headers in libs/. The native .so/.dll binaries are intentionally NOT
% relied upon being present: startup.m fetches or copies them at first run.
%
% Requires R2023a+ (matlab.addons.toolbox.ToolboxOptions).

if nargin < 1
    version = "0.2.0";
end

root = fileparts(mfilename('fullpath'));

% Stable identifier for this toolbox (do not change across releases).
identifier = "b6f3c0e2-3a3f-4a1b-9d7e-2c9a1f5e7d10";

% Files/folders to ship (all must live under root).
% Ship the C headers (needed by loadlibrary) but NOT the platform-specific
% .so/.dll binaries — startup.m fetches/copies those at first run.
headers = fullfile(root, "libs", ["RM_interface_C.h" "IPhreeqc.h" "Var.h" ...
    "IrmResult.h" "PHRQ_exports.h" "PHRQ_base.h"])';
files = [ ...
    fullfile(root, "src"); ...
    fullfile(root, "database"); ...
    headers; ...
    fullfile(root, "tests"); ...
    fullfile(root, "examples"); ...
    fullfile(root, "startup.m"); ...
    fullfile(root, "run_matlab.sh"); ...
    fullfile(root, "README.md"); ...
    fullfile(root, "ROADMAP.md"); ...
    fullfile(root, "CHANGELOG.md")];
files = files(isfile(files) | isfolder(files));

opts = matlab.addons.toolbox.ToolboxOptions(root, identifier, "ToolboxFiles", files);
opts.ToolboxName        = "PhreeqcMatlab";
opts.ToolboxVersion     = char(version);
opts.Summary            = "MATLAB wrapper for the USGS PhreeqcRM and IPhreeqc geochemical engines.";
opts.Description        = "PhreeqcMatlab calls PhreeqcRM (reactive transport) and IPhreeqc " + ...
                           "through MATLAB's loadlibrary/calllib FFI, with orchestration " + ...
                           "helpers and a high-level object model for Phreeqc concepts.";
opts.AuthorName         = "Ali A. Eftekhari";
opts.MinimumMatlabRelease = "R2020a";
% Add every shipped source subfolder to the toolbox path.
srcDirs = strsplit(genpath(fullfile(root, "src")), pathsep);
srcDirs = srcDirs(~cellfun(@isempty, srcDirs));
opts.ToolboxMatlabPath = [string(srcDirs)'; fullfile(root, "database")];

opts.OutputFile = fullfile(root, "PhreeqcMatlab.mltbx");

matlab.addons.toolbox.packageToolbox(opts);
mltbx = opts.OutputFile;
fprintf('Packaged toolbox: %s\n', mltbx);
end
