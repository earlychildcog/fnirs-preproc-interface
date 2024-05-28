function include(obj, event, guinirs)
guinirs.meta.included = obj.SelectedObject.String;
% set(obj, 'BackgroundColor',[0.8 0.2 0.1]*(~guinirs.meta.included) + [0.2 0.8 0.1]*guinirs.meta.included)
end