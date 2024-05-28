addpath(genpath("src"))

%%
datapath = "data/single_device_finger_tapping"; % snirf file or folder with snirf files

%%
guinirs = guinirsClass(datapath);
guinirs.startParallelPool(4)
stepRun(guinirs);
channelsToPlot = [1 2 3 4];
guinirs.guibuild(channelsToPlot)

