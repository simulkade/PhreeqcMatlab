function startup()
%{
startup

Start up the PhreeqcMatlab package. It adds the source folders to the path
and makes sure the native PhreeqcRM and IPhreeqc shared libraries are
available in the libs/ folder.

Resolution order for each library (first hit wins):
  1. A matching, correctly versioned file already in libs/ (per libs/.phreeqc_version).
  2. A locally installed/compiled copy, found via:
       - the PHREEQCMATLAB_LIB_PATH environment variable (a directory), or
       - the system install prefix /usr/local/lib.
     The file is copied into libs/ so MATLAB's loadlibrary can find it.
  3. Download from the simulkade/PhreeqcRM GitHub releases.

macOS is not supported (no prebuilt binary); compile PhreeqcRM yourself and
place the resulting .dylib in libs/ or point PHREEQCMATLAB_LIB_PATH at it.
%}

% -------- pinned versions ------------------------------------------------
PHREEQCRM_VERSION = '3.8.6';
IPHREEQC_VERSION  = '3.8.6';
RELEASE_BASE      = 'https://github.com/simulkade/PhreeqcRM/releases/download';
time_out          = 1000; % [s] download timeout

% -------- add source folders to the path ---------------------------------
try
    p = mfilename('fullpath');
    file_name = mfilename;
    current_path = p(1:end-1-length(file_name));
    addpath([current_path '/libs']);
    addpath([current_path '/src']);
    addpath([current_path '/src/Advection1D']);
    addpath([current_path '/src/Transport1D']);
    addpath([current_path '/src/Bulk']);
    addpath([current_path '/src/Tools']);
    addpath([current_path '/database']);
    addpath([current_path '/src/FVTool']);
    disp('PhreeqcMatlab is starting. Checking for the PhreeqcRM library ...');
catch
    error('Something went wrong with the PhreeqcMatlab start up. Please download the package again, extract it, and run the startup.m file.');
end

libs_dir = [current_path '/libs'];

% -------- per-OS shared-library file names -------------------------------
if ispc
    rm_file  = 'libphreeqcrm.dll';
    iph_file = 'libiphreeqc.dll';
elseif ismac
    rm_file  = 'libphreeqcrm.dylib';
    iph_file = 'libiphreeqc.dylib';
    warning('PhreeqcMatlab: macOS is not officially supported. You must supply the compiled libraries yourself (see PHREEQCMATLAB_LIB_PATH).');
else % unix / linux
    rm_file  = 'libphreeqcrm.so';
    iph_file = 'libiphreeqc.so';
end

% Candidate local install locations (searched in order).
env_lib_path = getenv('PHREEQCMATLAB_LIB_PATH');
local_dirs = {};
if ~isempty(env_lib_path)
    local_dirs{end+1} = env_lib_path;
end
if isunix
    local_dirs{end+1} = '/usr/local/lib';
end

% -------- ensure each library is present at the right version ------------
% PhreeqcRM: on Windows an import .lib is also required alongside the .dll.
ensure_library(libs_dir, rm_file, PHREEQCRM_VERSION, local_dirs, ...
    [RELEASE_BASE '/' PHREEQCRM_VERSION], time_out);
ensure_library(libs_dir, iph_file, IPHREEQC_VERSION, local_dirs, ...
    [RELEASE_BASE '/' IPHREEQC_VERSION], time_out);
if ispc
    ensure_library(libs_dir, 'libphreeqcrm.lib', PHREEQCRM_VERSION, local_dirs, ...
        [RELEASE_BASE '/' PHREEQCRM_VERSION], time_out);
    ensure_library(libs_dir, 'libiphreeqc.lib', IPHREEQC_VERSION, local_dirs, ...
        [RELEASE_BASE '/' IPHREEQC_VERSION], time_out);
end

warn_if_libstdcpp_too_old();

% Optional: the FVTool finite-volume package for multi-dimensional transport.
ensure_fvtool(current_path);

end

% =========================================================================
function ensure_fvtool(root_path)
%ENSURE_FVTOOL make the optional FVTool package available on the path.
% Used only for multi-dimensional reactive transport (see PhreeqcFVToolTransport).
% If FVTool is not already on the path, a local copy under external/FVTool is
% added and initialized (FVToolStartUp), cloning it from GitHub on first use.
% FVTool is optional, so any failure here is non-fatal (a warning only).
if ~isempty(which('FVToolStartUp')) || ~isempty(which('createMesh2D'))
    return; % already available
end
fvtool_dir   = fullfile(root_path, 'external', 'FVTool');
startup_file = fullfile(fvtool_dir, 'FVToolStartUp.m');
url          = 'https://github.com/FiniteVolumeTransportPhenomena/FVTool';
if ~isfile(startup_file)
    ext_dir = fullfile(root_path, 'external');
    if ~isfolder(ext_dir); mkdir(ext_dir); end
    fprintf('FVTool not found; fetching it into external/FVTool ...\n');
    [st, out] = system(sprintf('git clone --depth 1 %s "%s"', url, fvtool_dir));
    if st ~= 0 || ~isfile(startup_file)
        warning(['PhreeqcMatlab: could not fetch FVTool automatically (needed only ' ...
            'for multi-dimensional reactive transport). Clone %s into external/FVTool ' ...
            'manually. Details: %s'], url, strtrim(out));
        return;
    end
end
addpath(fvtool_dir);
% FVToolStartUp cd's into its own folders and leaves the cwd there, so save
% and restore the caller's current directory around it.
original_dir = pwd;
restore_dir = onCleanup(@() cd(original_dir));
try
    FVToolStartUp();
    fprintf('FVTool is available (external/FVTool).\n');
catch ME
    warning('PhreeqcMatlab: FVTool found but FVToolStartUp failed: %s', ME.message);
end
end

% =========================================================================
function warn_if_libstdcpp_too_old()
%WARN_IF_LIBSTDCPP_TOO_OLD warns when MATLAB's bundled libstdc++ is likely too
% old for a modern-GCC build of PhreeqcRM (the "GLIBCXX_... not found" failure).
% LD_PRELOAD must be set before MATLAB starts, so we can only advise here.
if ~isunix || ismac
    return;
end
if ~isempty(getenv('LD_PRELOAD'))
    return; % user has almost certainly already applied the workaround
end
bundled = fullfile(matlabroot, 'sys', 'os', 'glnxa64', 'libstdc++.so.6');
if ~isfile(bundled)
    return;
end
warning(['PhreeqcMatlab: if loadlibrary fails with a "GLIBCXX_... not found" error, ' ...
    'launch MATLAB via ./run_matlab.sh (or set LD_PRELOAD to your system ' ...
    'libstdc++.so.6) so the modern-GCC PhreeqcRM 3.8.6 build can load.']);
end

% =========================================================================
function ensure_library(libs_dir, file_name, version, local_dirs, url_base, timeout)
%ENSURE_LIBRARY makes sure libs_dir/file_name exists at the requested version.
% A stamp file (libs/.phreeqc_version) records the installed version per file
% so that a version bump triggers a refresh instead of silently keeping an
% old binary.
dest  = fullfile(libs_dir, file_name);
stamp = fullfile(libs_dir, '.phreeqc_version');

if isfile(dest) && strcmp(read_stamp(stamp, file_name), version)
    fprintf('%s (v%s) is present.\n', file_name, version);
    return;
end

% 1) Try to copy from a local install.
for i = 1:numel(local_dirs)
    src = find_local_lib(local_dirs{i}, file_name, version);
    if ~isempty(src)
        try
            copyfile(src, dest, 'f');
            write_stamp(stamp, file_name, version);
            fprintf('%s copied from local install (%s).\n', file_name, src);
            return;
        catch
            warning('PhreeqcMatlab: found %s but could not copy it to libs/.', src);
        end
    end
end

% 2) Fall back to downloading a versioned release asset.
url = choose_download_url(url_base, file_name, version);
if isempty(url)
    warning('PhreeqcMatlab: no download URL known for %s. Please place it in libs/ manually.', file_name);
    return;
end
fprintf('Downloading %s from %s ...\n', file_name, url);
try
    options = weboptions('Timeout', timeout);
    websave(dest, url, options);
    write_stamp(stamp, file_name, version);
    fprintf('%s downloaded successfully.\n', file_name);
catch
    warning('PhreeqcMatlab: could not download %s. Please download it manually from %s and copy it to the libs folder.', file_name, url);
end
end

% -------------------------------------------------------------------------
function src = find_local_lib(dir_path, file_name, version)
%FIND_LOCAL_LIB looks for file_name (or a versioned variant) in dir_path.
src = '';
if isempty(dir_path) || ~isfolder(dir_path)
    return;
end
[~, base, ext] = fileparts(file_name); % e.g. libphreeqcrm , .so
candidates = { ...
    fullfile(dir_path, file_name), ...                          % libphreeqcrm.so
    fullfile(dir_path, [base '-' version ext]), ...             % libphreeqcrm-3.8.6.so
    };
for i = 1:numel(candidates)
    if isfile(candidates{i})
        src = candidates{i};
        return;
    end
end
end

% -------------------------------------------------------------------------
function url = choose_download_url(url_base, file_name, version)
%CHOOSE_DOWNLOAD_URL maps a local library file name to its release asset URL.
% Asset names on the simulkade/PhreeqcRM releases use the versioned form.
url = '';
switch file_name
    case 'libphreeqcrm.so'
        url = [url_base '/libphreeqcrm-' version '.so'];
    case 'libiphreeqc.so'
        url = [url_base '/libiphreeqc-' version '.so'];
    case 'libphreeqcrm.dll'
        url = [url_base '/PhreeqcRM.dll'];
    case 'libphreeqcrm.lib'
        url = [url_base '/PhreeqcRM.lib'];
    case 'libiphreeqc.dll'
        url = [url_base '/IPhreeqcd.dll'];
    case 'libiphreeqc.lib'
        url = [url_base '/IPhreeqcd.lib'];
end
end

% -------------------------------------------------------------------------
function v = read_stamp(stamp_file, key)
%READ_STAMP returns the recorded version for key, or '' if unknown.
v = '';
if ~isfile(stamp_file)
    return;
end
lines = strsplit(fileread(stamp_file), newline);
for i = 1:numel(lines)
    parts = strsplit(strtrim(lines{i}), '=');
    if numel(parts) == 2 && strcmp(strtrim(parts{1}), key)
        v = strtrim(parts{2});
        return;
    end
end
end

% -------------------------------------------------------------------------
function write_stamp(stamp_file, key, version)
%WRITE_STAMP records key=version in the stamp file, replacing any prior entry.
entries = containers.Map('KeyType', 'char', 'ValueType', 'char');
if isfile(stamp_file)
    lines = strsplit(fileread(stamp_file), newline);
    for i = 1:numel(lines)
        parts = strsplit(strtrim(lines{i}), '=');
        if numel(parts) == 2
            entries(strtrim(parts{1})) = strtrim(parts{2});
        end
    end
end
entries(key) = version;
ks = keys(entries);
fid = fopen(stamp_file, 'w');
if fid == -1
    return;
end
cleaner = onCleanup(@() fclose(fid));
for i = 1:numel(ks)
    fprintf(fid, '%s = %s\n', ks{i}, entries(ks{i}));
end
end
