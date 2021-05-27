 function Set-Wallpaper($image){
  $source = @"
  using System;
  using System.Runtime.InteropServices;
    
  public class Params
  {
      [DllImport("User32.dll",CharSet=CharSet.Unicode)]
      public static extern int SystemParametersInfo (Int32 uAction,
                                                      Int32 uParam,
                                                      String lpvParam,
                                                      Int32 fuWinIni);
  }
"@
    
  Add-Type -TypeDefinition $source
    
  $SPI_SETDESKWALLPAPER = 0x0014
  $UpdateIniFile = 0x01
  $SendChangeEvent = 0x02
    
  $fWinIni = $UpdateIniFile -bor $SendChangeEvent
    
  $ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
  }
  

 $Wallpaperfilefolder='C:\Users\Administrator\Pictures\' 
 #壁纸文件夹    
 #the wallpaper url
 $Filelist=Get-ChildItem  $Wallpaperfilefolder -filter *.*g 
 #图片文件列表  
 #the list of wallpaper file
 $Filecount=$Filelist.Length-1
 $Randomnum= Get-Random -Minimum 0 -Maximum $Filecount
 #随机选一个图片文件 ramdon choose a  wallpaper file
 Set-Wallpaper ($Wallpaperfilefolder + $Filelist[$Randomnum].name)
 #更换壁纸 
 #switch wallpaper 
