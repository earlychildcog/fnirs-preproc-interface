addpath(genpath("src"))

%%
datapath = "data/data_hyperscanning"; % snirf file or folder with snirf files

%%
guinirs = guinirsClass(datapath);
guinirs.fnPreload = @preload.prestepRunHyperscanning;  % function to run when we first load the data
guinirs.startParallelPool(4);
guinirs.init();
stepRun(guinirs);
channelsToPlot = [1 2 3 4];
guinirs.guibuild(channelsToPlot)

