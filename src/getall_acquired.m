function list_acq = getall_acquired(list_files)
list_acq(length(list_files)) = SnirfClass; % initialise array
for iFile = 1:length(list_files)
    acq = SnirfClass(char(list_files(iFile)));
    list_acq(iFile) = prestepRun(acq);
end