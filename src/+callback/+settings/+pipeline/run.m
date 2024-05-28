function run(obj, event, guinirs, whichrun)
arguments
    obj
    event
    guinirs     guinirsClass
    whichrun        string {mustBeMember(whichrun, ["current", "forward", "all"])} = "all"
end
whichstep = string(guinirs.guiSettings.controls.pipeline.whichstep.String(guinirs.guiSettings.controls.pipeline.whichstep.Value));
% whichrun = string(guinirs.guiSettings.controls.pipeline.whichrun.String(guinirs.guiSettings.controls.pipeline.whichrun.Value));
colour1 = obj.BackgroundColor;
% processes again: either only step which is active in plot view, that and all the next ones, or all steps.
fprintf("\nrunning %s...", whichstep)
obj.BackgroundColor = [1 0.8 0.8];
pause(0.00001)
if whichrun == "current"
    guinirs.rerun(whichstep);
    fprintf("complete\n")
    pause(0.00001)
elseif whichrun == "all"
    listSubj = string(guinirs.guiSettings.controls.pipeline.subjpick.String);
    nSubj = length(listSubj);
    for iSubj = 1:nSubj
        guinirs.guiSettings.controls.pipeline.subjpick.Value = iSubj;
        guinirs.subjload(guinirs.listFiles(iSubj));
        guinirs.rerun(whichstep);
    end
end
obj.BackgroundColor = colour1;



