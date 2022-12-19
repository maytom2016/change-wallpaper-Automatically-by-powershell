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
  logintofile("设置"+$image+"为壁纸成功")
  }
  function logintofile($str)
  {
    echo ((getdatetime_format)+$str)>>($PSScriptRoot+'\run.log')
  }
  function checkifsuccess($path)
  {
    $wallpaperfilename=[System.IO.Path]::GetFileName($path)
    logintofile("path:"+$path)
    logintofile("wallpaperfilename:"+$wallpaperfilename)
    if($wallpaperfilename)
    {
      logintofile("下载完成，壁纸路径:"+$path+",准备更换壁纸。")
    }
    else
    {
      logintofile("检测到网络可能未连接，没有获取到壁纸信息，将不做任何操作，直接退出。")
      exit;
    }
  }
  function getdatetime_format()
  {
    $timestamp=Get-Date -Format "[yyyy-MM-dd HH:mm:ss]"
    return $timestamp
  }
  function ifmkdir($path)
  {
    $boola=(Test-Path $path)
    if (!$boola)
    {
     mkdir $path
     logintofile('创建'+$path+'成功！')
    }
  }
  function fixphpwallpapername($imgname)
  {
    if($imgname.contains("php"))
    {
      $datenow=get-date -format "yyyy-MM-dd-" 
      $imgname=$datenow+$imgname.replace("php" , "jpg")
      return $imgname
    }
    return $imgname
  }
 function downloadimg($url,$imgfolderpath)
 {
  $resp = Invoke-WebRequest -Uri $url -Method Head
  $imgname=[System.IO.Path]::GetFileName($resp.BaseResponse.ResponseUri.LocalPath)
  $imgname=fixphpwallpapername($imgname)
  if(!$imgname)
  {
    logintofile("检测到网络可能未连接，没有获取到壁纸信息，将不做任何操作，直接退出。")
    exit;
  }
  $imgLink=($resp.BaseResponse.ResponseUri.AbsoluteUri)
  logintofile("已经获取到图片URL为"+$imgLink)
  logintofile("已经获取到图片名为"+$imgname)
  $imgpath=($imgfolderpath + '\' + $imgname)
  if (!(Test-Path $imgpath))
  {
     Invoke-WebRequest -Uri $imgLink -OutFile $imgpath
     checkifsuccess($imgpath)
  }
  else
  {
    logintofile($imgpath+"已经存在，直接使用本地图片文件")
  }
  return $imgpath
 }
 function getvarfromconf($keyword)
 {
  $confpath=$PSScriptRoot+'\wallpaper.ini'
  if(Test-Path $confpath)
  {
    $varc=(Get-Content $confpath | Select-String  $keyword)|Select-String "#" -NotMatch|Out-String
    if($varc.contains("`'"))
    {
       $varc=$varc.split("`'")[1]
      return $varc
    }
    elseif($varc.contains("`""))
    {
       $varc=$varc.split("`"")[1]
      return $varc
    }
    else
    {
      return ""
    }
  }
 }
 function mode1()#从本地文件夹加载壁纸 load wallpaper from local folder
 {
  logintofile("开始执行模式1，从本地文件夹加载壁纸")
  $Wallpaperfilefolder=(getvarfromconf('Wallpaperfilefolder'))+'\'
  if($Wallpaperfilefolder -eq '\')
  {
    logintofile("未配置Wallpaperfilefolde,模式1不起作用")
    return ;
  }
  #壁纸文件夹    
   #the wallpaper url
   logintofile("加载图片文件列表，请稍等")
  $Filelist=Get-ChildItem  $Wallpaperfilefolder -filter *.*g 
  #图片文件列表  
  #the list of wallpaper file
  $Filecount=$Filelist.Length-1
  if ($Filecount -le 0)
  {
    logintofile("在Wallpaperfilefolde没有找到图片,模式1不起作用")
    return ;
  }
  logintofile("正在随机挑选图片作为壁纸")
  $Randomnum= Get-Random -Minimum 0 -Maximum $Filecount
  #随机选一个图片文件 ramdon choose a  wallpaper file
  $path=$Wallpaperfilefolder + $Filelist[$Randomnum].name
  logintofile("此次选中了"+$Filelist[$Randomnum].name+"正在更换壁纸")
  Set-WallPaper ($path)
  #更换壁纸 
  #change wallpaper 
 }
 function mode2()#从网上加载壁纸 load wallpaper from internet 
 {
  logintofile("开始执行模式2，从网上图片源加载壁纸")
  $downloadimgfolder=getvarfromconf('downloadimgfolder')
  if($downloadimgfolder -eq "")
  {
    logintofile("未配置downloadimgfolder,模式2不起作用")
    return;
  }
  ifmkdir ($downloadimgfolder)
  $url =getvarfromconf('imgurl')
  if($url -eq "")
  {
    logintofile("未配置imgurl,模式2不起作用")
    return;
  }
  if($url.contains('cn.bing.com'))
  {
    bingdayswallpaper $url $downloadimgfolder
    return;
  }
  $path=downloadimg $url $downloadimgfolder
  Set-WallPaper ($path)
 }
function mode3()#从网上多个源加载壁纸 load wallpaper from  internet of three source 
 {
  logintofile("开始执行模式3，从图片源中随机抽取一个图片源")
  $items=1,2,3
  $nums= New-Object -TypeName System.Collections.ArrayList
  for($x=1; $x -lt 4; $x=$x+1)   
  {   
    $str=getvarfromconf('url'+$x)
    if (!($str -eq ""))
    {
      $items[$x-1]=$str
      $nums.Add($x)|Out-Null
    }
  }
  $Randomnum= $nums|Get-Random 
  logintofile("本次使用图片源URL"+$Randomnum)
  $foldername="url"+$Randomnum
  $folderpath=(getvarfromconf('mode3imgfolder'))+'\'+$foldername
  ifmkdir($folderpath)
  logintofile("本次使用图片源存放在"+$folderpath)
  $url=$items[$Randomnum-1]
  if($url -eq "")
  {
    logintofile("未配置url1\url2\url3,模式3不起作用")
    return;
  }
  if($url.contains('cn.bing.com'))
  {
    bingdayswallpaper $url $folderpath
    return;
  }
    logintofile("开始下载壁纸，请等待。。。")
    $path=downloadimg $url $folderpath
    Set-WallPaper ($path)
 }
function main()
{
  if(!(Test-Path ($PSScriptRoot+"\wallpaper.ini")))
  {
    logintofile("未找到配置文件wallpaper.ini，正在生成当前目录配置模板")
    mkconfigini
    return;
  }
  $nums= New-Object -TypeName System.Collections.ArrayList
  for($x=1; $x -lt 4; $x=$x+1)   
  {   
    $str=getvarfromconf('mode'+$x+"enable")
    if ($str -eq "ON")
    {
      $nums.Add($x)|Out-Null
    }
  }
  if ($nums.Count -gt 0)
  {
   $randomnum=$nums|Get-Random
    if($randomnum -eq 1)
    {
      logintofile("启动模式1")
      mode1
    }
    elseif($randomnum -eq 2)
    {
      logintofile("启动模式2")
      mode2
    }
    elseif($randomnum -eq 3)
    {
      logintofile("启动模式3")
      mode3
    }
  }
  else 
  {
    logintofile("未开启任何壁纸模式,请进入wallpaper.ini将相应壁纸模式设置为ON")
  }
}
function mkconfigini()
{
  $a= 1..15
   $cfile=""
   $rn="`r`n"
   $a[0] ="[mode1]"+$rn
   $a[1] ="`$mode1enable=`'OFF`'"+$rn
   $a[2] ="`$Wallpaperfilefolder=`"C:\Users\Default\Pictures`" "+$rn
   $a[3] ="[mode2]"+$rn
   $a[4] ="`$mode2enable=`'ON`'"+$rn
   $a[5] ="`$imgurl = `"https://cn.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=zh-CN`""+$rn
   $a[6] = "`$downloadimgfolder=`""+$PSScriptRoot+"\wallpaper"+"`""+$rn
   $a[7] ="[mode3]"+$rn
   $a[8] ="`$mode3enable=`'OFF`'"+$rn
   $a[9] ="`$url1= `"`""+$rn
   $a[10] ="`$url2= `"`""+$rn
   $a[11] ="`$url3= `"`""+$rn
   $a[12] ="`$mode3imgfolder=`""+$PSScriptRoot+"`""+$rn
   $a[13] ="#本配置文件支持使用井号来注释一行内容"+$rn
   $a[14] ="#当修改好配置时，请将文件名改成wallpaper.ini,以供脚本读取使用"
   for($x=0; $x -le 14; $x=$x+1) 
   {
     $cfile=$cfile+$a[$x]
     
   }
   Set-Content -Path ($PSScriptRoot+"\wallpaper_example.ini") -Value ($cfile)
  if (Test-Path ($PSScriptRoot+"\wallpaper_example.ini"))
  { 
   logintofile("已经在当前目录生成配置文件示例wallpaper_example.ini，修改好配置后，请将文件名改成wallpaper.ini,以供脚本读取使用")
   return ;
  }
}
function bingdayswallpaper($url,$imgfolderpath)
{
  logintofile("检测到必应壁纸，使用必应壁纸模式")
  $resp = Invoke-WebRequest -Uri $url -Method GET
  $bingcontent= $resp.content| ConvertFrom-Json
 
  if(!$bingcontent.images.title)
  {
    logintofile("检测到网络可能未连接，没有获取到必应壁纸信息，将不做任何操作，直接退出。")
    exit;
  }
  $imgLink="cn.bing.com"+($bingcontent.images.url|Out-String)
  $datenow=get-date -format "yyyy-MM-dd-" 
  $imgname=$datenow+$bingcontent.images.title+".jpg"
  logintofile("已经获取到图片URL为"+$imgLink)
  logintofile("已经获取到图片名为"+$imgname)
  $imgpath=($imgfolderpath + '\' + $imgname)
  if (!(Test-Path $imgpath))
  {
     Invoke-WebRequest -Uri $imgLink -OutFile $imgpath
     checkifsuccess($imgpath)
  }
  else
  {
    logintofile($imgpath+"已经存在，直接使用本地图片文件")
  }
  Set-WallPaper ($imgpath)
}
main