function h = sha256_file(file_path)
%SHA256_FILE lowercase hex SHA-256 digest of a file.
%
%   h = SHA256_FILE(file_path) returns the 64-character hex digest, or '' when
%   the file cannot be read or no digest backend is available.
%
% Returning '' rather than erroring lets callers treat "cannot hash" as
% "cannot verify" and degrade gracefully (see startup.m, which then installs a
% download unverified with a warning instead of refusing to start).
%
% Two backends are tried in order:
%   1. the JVM's java.security.MessageDigest (present in a normal session),
%   2. a system tool (sha256sum, or certutil on Windows) for -nojvm sessions.

h = '';
if ~isfile(file_path)
    return;
end

% --- 1) JVM MessageDigest -------------------------------------------------
if usejava('jvm')
    try
        fid = fopen(file_path, 'r');
        if fid ~= -1
            closer = onCleanup(@() fclose(fid)); %#ok<NASGU>
            bytes = fread(fid, inf, '*uint8');
            md = java.security.MessageDigest.getInstance('SHA-256');
            % Java bytes are signed, so reinterpret rather than convert.
            md.update(typecast(bytes, 'int8'));
            h = lower(sprintf('%02x', typecast(md.digest(), 'uint8')));
            return;
        end
    catch
        h = ''; % fall through to the system tool
    end
end

% --- 2) system checksum tool ---------------------------------------------
if ispc
    cmd = sprintf('certutil -hashfile "%s" SHA256', file_path);
else
    cmd = sprintf('sha256sum "%s"', file_path);
end
[status, out] = system(cmd);
if status ~= 0
    return;
end
% sha256sum prints "<hash>  <name>"; certutil prints the hash on its own line,
% in older versions spaced out byte by byte. Strip whitespace per line and take
% the first line that *starts* with 64 hex characters.
lines = strsplit(lower(out), newline);
for i = 1:numel(lines)
    ln = regexprep(strtrim(lines{i}), '\s', '');
    tok = regexp(ln, '^[0-9a-f]{64}', 'match', 'once');
    if ~isempty(tok)
        h = tok;
        return;
    end
end
end
