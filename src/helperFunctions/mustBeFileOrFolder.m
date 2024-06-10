function mustBeFileOrFolder(s)
   try
       mustBeFile(s);
   catch err1
        try
            mustBeFolder(s);
        catch err2
            error("Input provided is not a file or a folder")
        end
   end
end