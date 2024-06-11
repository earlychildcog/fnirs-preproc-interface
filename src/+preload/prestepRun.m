function acquired = prestepRun(acquired)
% here you can put code to be executed during the FIRST loading of the ORIGINAL snirf files
% you can remove markers you are not interested in, shorten the recording, make fixes etc 
% that you would not want to do on your snirf files

disp(1)
thresslow = -30;
advance = 22;
acquired.probe.sourcePos2D(acquired.probe.sourcePos2D < thresslow) = acquired.probe.sourcePos2D(acquired.probe.sourcePos2D < thresslow) + advance;
acquired.probe.sourcePos3D(acquired.probe.sourcePos3D < thresslow) = acquired.probe.sourcePos3D(acquired.probe.sourcePos3D < thresslow) + advance;
acquired.probe.detectorPos2D(acquired.probe.detectorPos2D < thresslow) = acquired.probe.detectorPos2D(acquired.probe.detectorPos2D < thresslow) + advance;
acquired.probe.detectorPos3D(acquired.probe.detectorPos3D < thresslow) = acquired.probe.detectorPos3D(acquired.probe.detectorPos3D < thresslow) + advance;