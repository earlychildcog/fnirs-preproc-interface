function getposition(obj, event, guinirs, action)
arguments
    obj
    event
    guinirs
    action string = ""
end
cpt = get(obj,'CurrentPoint');
disp(cpt);

t = cpt(1,1);
y = cpt(1,2);

if action == "removetoend"
    
end