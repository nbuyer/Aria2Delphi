# Aria2Delphi
A very simple aria2 client written in Delphi/Pascal

Usage:
```
var
  // Aria2
  g_sAria2Dir: string = DEF_ARIA2_PATH + PathDelim; // path to store aria2c executable
  g_nAria2Port: Integer = 6800; // Aria2 JSONRPC port
  g_sAria2Secret: string = ''; // Secret token
  g_nStartAria2: Integer = 1; // 1=auto start in thread; 2=start when needed
  g_nGetDownloadListWait: Integer = 500; // get download status list interval
  g_nRunAria2Flags: UInt32 = 1; // bit0:hide, bit1:keep


  if g_cAria2Inst=nil then
  begin
    g_cAria2Inst := TAria2Delphi.Create(g_sAria2Dir, g_nAria2Port,
      g_sAria2Secret, False, g_nRunAria2Flags, g_nGetDownloadListWait);
  end;
  g_cAria2Inst.MakeSureRunAria2;
  if g_cAria2Inst.DownloadTorrent(m_sFile, g_sDownloadDir, sSelected, 0, sGID)=0 then ShowMessage('OK');
  ...
```
