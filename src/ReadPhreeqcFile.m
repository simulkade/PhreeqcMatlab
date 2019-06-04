function C = ReadPhreeqcFile(input_file)
%READPHREEQCFILE Reads a phreeqc input file, converts it to a matlab
%string, and clean up the comments
%returns a cell array of strings
fid = fopen(input_file, 'r');
C = textscan(fid, '%s','Delimiter',''); % read the input file into a cell array
fclose(fid);
C = C{:}; % get rid of cells in cell C

% clean the comments:
ind_comment = cellfun(@(x)(x(1)=='#'), C);
C(ind_comment) = {' '};

end

