function db_path = DATABASE_PATH()
%DATABASE_PATH returns path to the database folder
p = mfilename('fullpath');
file_name = mfilename;
current_path = p(1:end-1-length(file_name));
db_path = fullfile(current_path, '..', '/database');
end

