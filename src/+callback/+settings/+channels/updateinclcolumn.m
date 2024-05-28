function updaterejections(obj, event, guinirs)
% note: shall make it more targetted (in updating only specific cell) to improve performance
% should actually use `CellSelectionCallback`
incl = obj.Data(:,end) ~= 0;
obj.Data(obj.Data(:,end) ~= 0 & obj.Data(:,end) ~= 1,end) = uint32(1);
pause(0.001)
guinirs.layout.link.incl = incl;
guinirs.guiLayout.updateLink;
guinirs.guiLayout.rerenderRejected;
guinirs.guiSteps.updateRejectedLinestyle;
guinirs.guiSteps.updateVisible;
obj.BackgroundColor = [0.9*ones(length(incl),1), 0.3*ones(length(incl),1), 0.3*ones(length(incl),1)];
obj.BackgroundColor(incl,1) = 0.3;
obj.BackgroundColor(incl,2) = 0.9;
obj.Position = [0 0 0.9 1];

end