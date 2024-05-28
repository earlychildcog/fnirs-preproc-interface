function selectAll(obj, event, guinirs)

arrayfun(@(ln)set(ln, 'Color', [ln.Color 1]),guinirs.guiLayout.linesChannels)
pause(0.00001) % increases rendering speed of layout a lot in my macbook
% set(guinirs.guiSteps.lines(1).Parent.Parent.Parent.SelectedTab.Children.Children,'Visible','on');
% pause(0.00001) % we render current tab first (then the others)
% set(guinirs.guiSteps.lines,'Visible','on');

guinirs.channelsToPlot = 1:size(guinirs.layout.link,1);
guinirs.guiLayout.link(:,4) = 1;
guinirs.guiSteps.updateVisible;
pause(0.00001)
% tic
% set(guinirs.guiSteps.lines(arrayfun(@(x)turnoffrejected(x),guinirs.guiSteps.lines)),'Visible','off');
% toc
arrayfun(@(ln)toggleuserselected(ln,1),guinirs.guiLayout.linesChannels)
arrayfun(@(ln)toggleuserselected(ln,1),guinirs.guiSteps.lines)
end

function toggleuserselected(lnObj, value)
lnObj.UserData.selected = value;
end

function turnoff = turnoffrejected(lnObj)
    if lnObj.UserData.rejected == 1
        turnoff = true;
    else
        turnoff = false;
    end
end