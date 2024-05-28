function subjpick(obj, event, guinirs)
% disp(obj.Value);
if ~strcmp(guinirs.filename, guinirs.listFiles(obj.Value))
    guinirs.disable;
    % guinirs.export;
    guinirs.subjload(guinirs.listFiles(obj.Value));
    guinirs.enable;
    % disp(1)
    % else % else run!
    % colour1 = obj.BackgroundColor;
    % obj.BackgroundColor = [1 0.8 0.8];
    % guinirs.rerun("all");
    % obj.BackgroundColor = colour1;

end
end