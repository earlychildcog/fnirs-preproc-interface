function buttonZoom(self, event)
% for zoom in and out keys
if self.Value == 1
    self.UserData.Value = self.UserData.Min;
    zoom('Direction', 'in')
    zoom on
elseif self.Value == 0
    zoom off
elseif self.Value == -1
    self.UserData.Value = self.UserData.Min;
    zoom('Direction', 'out')
    zoom on
end