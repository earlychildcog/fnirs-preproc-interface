function togglechannelvisible(self, event, other)
% toggles channel to show/hide with left click
% toggles channel to accept/reject with right click
if event.Button == 1    % left click
    self.UserData.selected = 1 - self.UserData.selected;    % depreciated, should be removed
    guilayout = self.UserData.guilayout;
    iChan = self.UserData.iChan;
    guilayout.link(iChan,4) = 1 - guilayout.link(iChan,4);

    % change colour of channel line in layout between solid and transparent
    if guilayout.link(iChan,4) == 1
        set(self, 'Color',[self.UserData.colour 1]);
        pause(0.000001)
    elseif guilayout.link(iChan,4) == 0
        set(self, 'Color',[self.UserData.colour 0.1]);
        pause(0.000001)
    else
        error("guilayout.link entry (%d,4) is not 0 or 1", iChan)
    end

    % make the corresponding trace visible or invisible (also based on rejection status)
    set(other, 'Visible',guilayout.link(iChan,4) == 1 && (guilayout.link(iChan,3) == 1 || guilayout.parent.plotRejected))
    guilayout.parent.guiSteps.updateVisibleArtline;
    pause(0.000001)
elseif event.Button == 3    % right click
    guinirs = self.UserData.guilayout.parent;
    iChan = self.UserData.iChan;
    guinirs.layout.link.incl(iChan) = ~guinirs.layout.link.incl(iChan);
    % guinirs.guiLayout.updateLink;
    guinirs.guiLayout.rerenderRejected;
    guinirs.guiSteps.updateRejectedLinestyle;
    guinirs.guiSteps.updateVisible;
    guinirs.guiSteps.updateVisibleArtline;
    pause(0.001)
end

end