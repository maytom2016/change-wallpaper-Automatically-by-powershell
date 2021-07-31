shpath = createobject("Scripting.FileSystemObject").GetFile(Wscript.ScriptFullName).ParentFolder.Path+"\AutoChangeWallpaper.ps1"
'Wscript.echo shpath
CreateObject("WScript.Shell").Run "PowerShell -File "+shpath,0