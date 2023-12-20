unit UAria2;

// Simple Aria2 classes for Delphi by Edward G.

// https://aria2.github.io/manual/en/html/aria2c.html#rpc-interface
// https://aria2.github.io/manual/en/html/libaria2.html

// TODO:
//   move to end if download speed lower than xx K more than yy mins
//   metalink?

interface

uses
  SysUtils, Classes, IdHttp, System.NetEncoding, System.Generics.Collections,
{$IFDEF PLM}
  UStrUtil,
{$ENDIF}
  JSON, System.Contnrs, System.SyncObjs;

const // DO NOT localize
  CT_APP_JSON = 'application/json';
{$IFDEF MSWINDOWS}
  ARIA2C_EXEC = 'aria2c.exe';
{$ELSE}
  ARIA2C_EXEC = 'aria2c';
{$ENDIF}
  ARIA2_DEF_PORT = 6800;
  ARAI2_DEF_CFG = 'aria2.conf';
  LOCAL_HOST = '127.0.0.1';

  RUN_FLAG_HIDE = $01; // Run aira2 and hide window
  RUN_FLAG_KEEP = $02; // Do not quit aira2 when free

  FMT_JRPCID = 'daid%d'; // RPC id

  // Aria2 RPC Methods
  METHOD_ADD_URI = 'aria2.addUri';
  METHOD_ADD_TOR = 'aria2.addTorrent';
  METHOD_ADD_METALINK = 'aria2.addMetalink';
  METHOD_TELL_ACTIVE = 'aria2.tellActive';
  METHOD_TELL_WAITING = 'aria2.tellWaiting';
  METHOD_TELL_STOPPED = 'aria2.tellStopped';
  METHOD_TELL_STATUS = 'aria2.tellStatus';
  METHOD_CHG_POS = 'aria2.changePosition';
  METHOD_PAUSE = 'aria2.pause';
  METHOD_PAUSE_ALL = 'aria2.pauseAll';
  METHOD_FORCE_PAUSE = 'aria2.forcePause';
  METHOD_FORCE_PAUSE_ALL = 'aria2.forcePauseAll';
  METHOD_UNPAUSE = 'aria2.unpause';
  METHOD_UNPAUSE_ALL = 'aria2.unpauseAll';
  METHOD_REMOVE = 'aria2.remove';
  METHOD_FORCE_REMOVE = 'aria2.forceRemove';
  METHOD_GET_FILES = 'aria2.getFiles';
  METHOD_GET_URIS = 'aria2.getUris';
  METHOD_GET_PEERS = 'aria2.getPeers';
  METHOD_GET_SERVERS = 'aria2.getServers';
  METHOD_GET_OPTION= 'aria2.getOption';
  METHOD_GET_GOPTION= 'aria2.getGlobalOption';
  METHOD_GET_GSTAT = 'aria2.getGlobalStat';
  METHOD_REMOVE_DOWNLOAD_RESULT = 'aria2.removeDownloadResult';
  METHOD_GET_VER = 'aria2.getVersion';
  METHOD_SHUTDOWN = 'aria2.shutdown';
  METHOD_FORCE_SHUTDOWN = 'aria2.forceShutdown';
  METHOD_CHG_OPT = 'aria2.changeOption';
  METHOD_CHG_GOPT = 'aria2.changeGlobalOption';
  METHOD_PURGE_RESULT = 'aria2.purgeDownloadResult';

  // AddXXX() flags
  ARIA2_FLAG_NO_ENCODE = $0001;
  ARIA2_FLAG_PAUSE = $0002;
  ARIA2_FLAG_FILE_NAME = $0004;
  ARIA2_FLAG_TO_HEAD = $0008; // move to head

  // Download item type
  ARIA2_ITEM_NONE = 0;
  ARIA2_ITEM_HTTP = 1;
  ARIA2_ITEM_FTP = 2;
  ARIA2_ITEM_TOR = 3;
  ARIA2_ITEM_MLINK = 4;

  // Remove reason for event
  REMOVE_BY_FINISH = 0; // task finished
  REMOVE_BY_DUP = 1; // duplicated
  REMOVE_BY_USER = 2; // user did
  REMOVE_BY_ERROR = 3; // error

  // Some standard keys/options
  KEY_GID = 'gid';                     KEY_STATUS = 'status';
  KEY_INDEX = 'index';                 KEY_DIR = 'dir';
  KEY_PAUSE = 'pause';                 KEY_EC = 'errorCode';
  KEY_EMSG = 'errorMessage';           KEY_SEL_FILE = 'select-file';
  KEY_DONE_LEN = 'completedLength';    KEY_TOTAL_LEN = 'totalLength';
  KEY_PATH = 'path';                   KEY_LENGTH = 'length';
  KEY_SELECTED = 'selected';           KEY_URIS = 'uris';
  KEY_URI = 'uri';                     KEY_DL_SPEED = 'downloadSpeed';
  KEY_UP_SPEED = 'uploadSpeed';        KEY_CONN = 'connections';
  KEY_UP_LEN = 'uploadLength';         KEY_NUM_PIECE = 'numPieces';
  KEY_VER_LEN = 'verifiedLength';      KEY_FILES = 'files';
  KEY_BT = 'bittorrent';               KEY_INFO_HASH = 'infoHash';
  KEY_CREATE_DATE = 'creationDate';    KEY_SEEDS = 'numSeeders';
  KEY_COMMENT = 'comment';             KEY_INFO = 'info';
  KEY_NAME = 'name';                   KEY_ACTIVE = 'active';
  KEY_PAUSED = 'paused';               KEY_WAITING = 'waiting';
  KEY_COMPLETE = 'complete';           KEY_REMOVED = 'removed';
  KEY_ERROR = 'error' ;

type
  // Aira2 download item status
  TAria2Status = (asUnknown, asError, asRemoved, asComplete, asPaused, asWaiting, asActive);

  // Aria2 JSONRpc implementation
  TAria2JSONRpc = class
  private
    m_cLock: TCriticalSection;
    m_cHttp: TIdHttp;
    // http://localhost:6800/jsonrpc
    m_sRpcAddr: string;
    m_nID: Integer;
    m_sSecret: string;
    m_bUseGet: Boolean;
    //m_nConnectTimeOut: Integer;
  public
    constructor Create(const sSecret: string);
    destructor Destroy; override;
    procedure SetHost(const sHost: string; nPort: Integer);
    function Request(const sMethod, sParams: string; dwFlags: UInt32; var sResult: string): Integer;
    function GetResult(var sResult: string): Integer;

    function GetVersion(var sResult: string): Integer;
    function Shutdown(bForce: Boolean; var sResult: string): Integer;
    function AddURI(const sURI, sDir: string; dwFlags: UInt32; var sResult: string): Integer;
    function AddTorrent(const sTorFile, sDir: string; dwFlags: UInt32; var sResult: string): Integer;
    function AddMetalink(const sMLinkFile, sDir: string; dwFlags: UInt32; var sResult: string): Integer;
    function Remove(const sGID: string; bForce: Boolean; var sResult: string): Integer;
    function Pause(const sGID: string; bForce: Boolean; var sResult: string): Integer;
    function UnPause(const sGID: string; var sResult: string): Integer;
    function TellStatus(const sGID: string; const sKeys: string; var sResult: string): Integer;
    function GetURIs(const sGID: string; var sResult: string): Integer;
    function GetFiles(const sGID: string; var sResult: string): Integer;
    function GetPeers(const sGID: string; var sResult: string): Integer;
    function GetServers(const sGID: string; var sResult: string): Integer;
    function TellActive(const sKeys: string; var sResult: string): Integer;
    function TellWaiting(nOfs, nNum: Integer; const sKeys: string; var sResult: string): Integer;
    function TellStopped(nOfs, nNum: Integer; const sKeys: string; var sResult: string): Integer;
    function ChangePosition(const sGID: string; nPos: Integer; const sHow: string; var sResult: string): Integer;
    function GetOption(const sGID: string; var sResult: string): Integer; // sGID='' for global
    function ChangeOption(const sGID, sOptions: string; var sResult: string): Integer;// sGID='' for global
    function RemoveDownloadResult(const sGID: string; var sResult: string): Integer;
    function PurgeDownloadResult(): string;
    function GetGlobalStat(var sResult: string): Integer;
  public
    property ID: Integer read m_nID write m_nID;
    property Secret: string read m_sSecret write m_sSecret;
    property UseGet: Boolean read m_bUseGet write m_bUseGet;
  end;

  // File item of download item
  TAria2ItemFile = class
  private
    m_nIndex: Integer;
    m_sPath: string;
    m_nTotalLength: Int64;
    m_nCompletedLength: Int64;
    m_bSelected: Boolean;
    m_nHealth: Byte;
    m_sURL: string;
  public
    procedure Assign(cItem: TAria2ItemFile);
  public
    property Idx: Integer read m_nIndex write m_nIndex;
    property Path: string read m_sPath write m_sPath;
    property TotalLength: Int64 read m_nTotalLength write m_nTotalLength;
    property CompletedLength: Int64 read m_nCompletedLength write m_nCompletedLength;
    property Selected: Boolean read m_bSelected write m_bSelected;
    property URL: string read m_sURL write m_sURL;
    property Health: Byte read m_nHealth write m_nHealth;
  end;

  // File item list
  TAria2ItemFileList = class(TObjectList)
  public
    function LoadFromJson(jy: TJSONArray; const sBaseDir: string): Integer;
    function SelectedCount: Integer;
    function CopyTo(cList: TAria2ItemFileList): Integer;
  end;

  // Download item
  TAria2DownloadItem = class
  private
    m_nIndex: Integer;
    m_sName: string;
    m_sGID: string;
    m_sURL: string;
    m_nType: Integer;  // torrent/http/ftp/mlink
    m_eStatus: TAria2Status;
    m_nTotalLength: Int64;
    m_nCompletedLength: Int64;
    m_nUploadLength: Int64;
    m_nDownSpeed: Integer;
    m_nUpSpeed: Integer;
    m_dtAdded: TDateTime;
    m_sDir: string;
    m_nConnections: Integer;
    m_nPieces: Integer;
    m_nVerifiedLength: Int64;

    // Torrent
    m_nSeeders: Integer;
    m_sHash: string;
    m_dtCreate: TDateTime;
    m_sComment: string;

    m_nErrorCode: Integer;
    m_sErrorMsg: string;

    m_cFiles: TAria2ItemFileList;
  protected
    function GetTorrentInfo(jo: TJSONObject): Boolean;
  public
    constructor Create(const sURL, sGID: string);
    destructor Destroy; override;
    function Clone: TAria2DownloadItem;
    procedure Clear;
    function GetFromStatus(const sStatus: string): Boolean; overload;
    function GetFromStatus(jo: TJSONObject): Boolean; overload;
  public
    property Idx: Integer read m_nIndex write m_nIndex;
    property GID: string read m_sGID write m_sGID;
    property Name: string read m_sName write m_sName;
    property URL: string read m_sURL write m_sURL;
    property Dir: string read m_sDir write m_sDir;
    property Typ: Integer read m_nType write m_nType;
    property Status: TAria2Status read m_eStatus write m_eStatus;
    property TotalLength: Int64 read m_nTotalLength write m_nTotalLength;
    property CompletedLength: Int64 read m_nCompletedLength write m_nCompletedLength;
    property DownSpeed: Integer read m_nDownSpeed write m_nDownSpeed;
    property Connections: Integer read m_nConnections write m_nConnections;
    property Added: TDateTime read m_dtAdded write m_dtAdded;
    property UpSpeed: Integer read m_nUpSpeed write m_nUpSpeed;
    property UpLenght: Int64 read m_nUploadLength write m_nUploadLength;
    property Pieces: Integer read m_nPieces write m_nPieces;
    property VerifiedLength: Int64 read m_nVerifiedLength write m_nVerifiedLength;

    property Hash: string read m_sHash write m_sHash;
    property Seeders: Integer read m_nSeeders write m_nSeeders;
    property CreateDate: TDateTime read m_dtCreate write m_dtCreate;
    property Comment: string read m_sComment write m_sComment;

    property ErrorCode: Integer read m_nErrorCode write m_nErrorCode;
    property ErrorMessage: string read m_sErrorMsg write m_sErrorMsg;
    property Files: TAria2ItemFileList read m_cFiles;
  end;

  // Download list
  TAria2DownloadList = class(TObjectList)
  private
  public
    function LoadFromResult(const sRet: string): Integer;
    function GetList(cResult: TStrings): Integer;
    function FindByGID(const sGID: string): TAria2DownloadItem;
  end;

  TOnRemoveDownload = procedure (const sGID: string; cItem: TAria2DownloadItem;
    nReason: Integer) of object;

  TAria2GetListThread = class;

  // Aira2 control
  TAria2Delphi = class
  private
    m_cRPC: TAria2JSONRpc;
    m_cDownloadList: TAria2DownloadList;
    m_dtUpdate: TDateTime;
    m_cLock: TCriticalSection;
    m_cGetListThrd: TAria2GetListThread;
    m_eOnUpdateList: TThreadProcedure;
    m_eOnErrorConnect: TThreadProcedure;
    m_eOnRemoveDownload: TOnRemoveDownload;

    m_sAria2Path: string;
    m_nAria2Port: Integer;
    m_dwRunFlags: UInt32;
    m_bExecuted: Boolean;

    m_bServerActive: Boolean;
  private
    procedure SetOnUpdateList(const Value: TThreadProcedure);
  public
    constructor Create(const sAria2Path: string; nAira2Port: Integer;
      const sSecret: string; bAutoStart: Boolean; dwRunFlags: UInt32;
      nGetListSleep: Integer);
    destructor Destroy; override;
    procedure Lock; inline;
    procedure Unlock; inline;
    procedure SetAutoStart;
    function MakeSureRunAria2(bChkFirst: Boolean = True): Integer;
    function IsAria2Running(nPort: Integer): Boolean;
    function DownloadURL(const sURL, sDir: string; dwFlags: UInt32; var sGID: string): Integer;
    function DownloadTorrent(const sTorFile, sDir, sSelected: string; dwFlags: UInt32; var sGID: string): Integer;
    function GetDownloadList(cResult: TStrings; bUpdNow: Boolean): Integer;
    function QuitAria2(bForce: Boolean): Integer;
    function DeleteDownload(const sGID: string; var sMsg: string): Integer;
    function Pause(const sGID: string; bPause: Boolean; var sMsg: string): Integer;
    function MoveTo(const sGID, sPos: string; var sMsg: string): Integer;
    function SelectFiles(const sGID, sSelected: string; var sMsg: string): Integer;
  public
    property DownloadList: TAria2DownloadList read m_cDownloadList;
    property RPC: TAria2JSONRpc read m_cRPC;
    property Executed: Boolean read m_bExecuted;
    property ServerActive: Boolean read m_bServerActive;
    property OnUpdateList: TThreadProcedure read m_eOnUpdateList write SetOnUpdateList;
    property OnErrorConnect: TThreadProcedure read m_eOnErrorConnect write m_eOnErrorConnect;
    property OnRemoveDownload: TOnRemoveDownload read m_eOnRemoveDownload write m_eOnRemoveDownload;
  end;

  // Thread to get Aira2's download list
  TAria2GetListThread = class(TThread)
  private
    m_nSleep: Integer;
    m_cAria2: TAria2Delphi;
    m_bAutoStart: Boolean;
    m_cEvent: TSimpleEvent;
  protected
    procedure TerminatedSet; override;
    procedure Execute; override;
  public
    constructor Create(cAria2: TAria2Delphi; nSleep: Integer; bAutoStart: Boolean);
    destructor Destroy; override;
    procedure AutoStartAira2;
    procedure NotifyGetList;
  end;

var
  // Easier to multi lang
  g_yAria2Status: array[TAria2Status] of string = ('Unknown', KEY_ERROR,
    KEY_REMOVED, KEY_COMPLETE, KEY_PAUSED, KEY_WAITING, KEY_ACTIVE);
  g_sAria2ErrCodeFmt: string = 'Error code=%d';

  g_cAria2Inst: TAria2Delphi = nil; // global singleton Aria2 control object

function GetAria2StatusText(eStatus: TAria2Status): string; inline;

{$IFNDEF PLM}
function StringFromJSString(const sStr: string): string;
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}
uses
  Windows;
{$ENDIF}

function RunEXE (const sEXE: string; bHide: Boolean; dwWait: UInt32): Boolean;
{$IFDEF MSWINDOWS}
var
  szEXE: array[0..MAX_PATH] of Char;
  rSI: TStartUpInfo;
  rPI: TProcessInformation;
begin
  StrPCopy(szEXE, sEXE);
  // Set startup info
  FillChar(rSI, sizeof(rSI), 0);
  rSI.cb := sizeof(rSI);
  rSI.dwFlags:= STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK or STARTF_USESTDHANDLES;

  if not bHide then rSI.wShowWindow := SW_SHOWNORMAL else
    rSI.wShowWindow:= SW_HIDE;
  // Fill process info
  FillChar(rPI, sizeof(rPI), 0);

  Result := CreateProcess(nil,szEXE,nil,nil,False,0,nil,nil,rSI,rPI);

  if (Result) then
  begin
    CloseHandle(rPI.hThread);
    if dwWait>0 then WaitForInputIdle(rPI.hProcess, dwWait);
    CloseHandle(rPI.hProcess);
  end;
end;
{$ELSE}
{uses
  Macapi.Appkit,       // for NSWorkspace
  Macapi.Foundation;   // for NSSTR
var
  Workspace : NSWorkspace;         }
begin
  _system(PAnsiChar('open ' + AnsiString(sEXE)));
  Result := True;
  // TODO: fork/exec, execv() execl()
  //Workspace := TNSWorkspace.Create;
  //Workspace.openFile(NSSTR(sEXE));
end;
{$ENDIF}

{$IFNDEF PLM}
function StringFromJSString(const sStr: string): string;
var
  p1: PAnsiChar;
  p2: PChar;
  i, len, n, nVal: Integer;
  s: string;
  sWC: string;
  sUTF8, sRaw: RawByteString;
begin
  len := Length(sStr); // num of char
  if len<=0 then
  begin
    Result := '';
    Exit;
  end;
  SetLength(sUTF8, len*3);
  p1 := PAnsiChar(sUTF8);
  p2 := PChar(sStr);

  n := 0;
  case p2^ of
  '"', '''':
    begin
      Dec(len, 2); // sub first and last
      Inc(p2);
    end;
  end;

  while len>0 do
  begin
    case p2^ of
    #0: Break;
    '\':
      begin
        if len>1 then
        begin
          Inc(p2);
          Dec(len);
          case p2^ of
          #$0a, #$0d:
            begin
              Dec(len);
              Inc(p2);
              case p2^ of
              #$0a, #$0d:
                begin
                  Dec(len);
                  Inc(p2);
                end;
              end;
              Continue;
            end;
          '0': p1^ := #$0;
          'b': p1^ := #$8;
          'f': p1^ := #$c;
          'n': p1^ := #$a;
          'r': p1^ := #$d;
          't': p1^ := #$9;
          'u': // unicode
             begin
              // 4 bytes more
              Inc(p2);
              Dec(len);
              if len>=4 then
              begin
                SetLength(s, 4);
                Move(p2^, s[1], 4*sizeof(Char));
                Inc(p2, 4);
                Dec(len, 4);
                nVal := StrToIntDef('0x'+s, Ord('?'));
                if nVal<$100 then
                begin
                  p1^ := AnsiChar(Byte(nVal));
                  Inc(n);
                  Inc(p1);
                end else
                begin
                  sWC := WideChar(nVal); // to UTF8 first
                  sRaw := UTF8Encode(sWC);
                  for i := 1 to Length(sRaw) do
                  begin
                    p1^ := sRaw[i];
                    Inc(n);
                    Inc(p1);
                  end;
                end;
                Continue;
              end;
            end;
          'v': p1^ := #$b;
          'x': // hexchar
            begin
              // 2 bytes more
              Inc(p2);
              Dec(len);
              if len>=2 then
              begin
                SetLength(s, 2);
                Move(p2^, s[1], 2*sizeof(Char));
                Inc(p2, 2);
                Dec(len, 2);
                nVal := StrToIntDef('0x'+string(s), Ord('?'));
                p1^ := AnsiChar(Byte(nVal));
                Inc(n);
                Inc(p1);
                Continue;
              end;
            end;
          '"': p1^ := #$22;
          '''': p1^ := #$27;
          '\': p1^ := #$5c;
          else Continue; // ignore \
          end;
          Inc(n);
          Inc(p1);
        end else
          Break;
      end;
    else
      begin
        nVal := Integer(p2^);
        if nVal<$100 then
        begin
          p1^ := AnsiChar(Byte(nVal));
          Inc(n);
          Inc(p1);
        end else
        begin
          sWC := WideChar(nVal);
          sRaw := UTF8Encode(sWC);
          for i := 1 to Length(sRaw) do
          begin
            p1^ := sRaw[i];
            Inc(n);
            Inc(p1);
          end;
        end;
      end;
    end;
    Dec(len);
    Inc(p2);
  end;
  SetLength(sUTF8, n);
  Result := UTF8ToString(sUTF8);
end;
{$ENDIF PLM}

function SpanOfNowAndThen(const ANow, AThen: TDateTime): TDateTime; inline;
begin
  if ANow < AThen then
    Result := AThen - ANow
  else
    Result := ANow - AThen;
end;

function SecondSpan(const ANow, AThen: TDateTime): Double; inline;
begin
  Result := SecsPerDay * SpanOfNowAndThen(ANow, AThen);
end;

function GetAria2StatusText(eStatus: TAria2Status): string;
begin
  Result := g_yAria2Status[eStatus];
end;


{ TAria2Delphi }

constructor TAria2Delphi.Create(const sAria2Path: string; nAira2Port: Integer;
  const sSecret: string; bAutoStart: Boolean; dwRunFlags: UInt32; nGetListSleep: Integer);
begin
  m_sAria2Path := sAria2Path;
  m_nAria2Port := nAira2Port;
  m_dwRunFlags := dwRunFlags;
  m_cRPC := TAria2JSONRpc.Create(sSecret);
  m_cLock := TCriticalSection.Create;
  m_cDownloadList := TAria2DownloadList.Create;
  m_cGetListThrd := TAria2GetListThread.Create(Self, nGetListSleep, bAutoStart);
  inherited Create;
end;

destructor TAria2Delphi.Destroy;
begin
  m_cGetListThrd.Terminate;
  if m_bExecuted and (m_dwRunFlags and RUN_FLAG_KEEP=0) then
  begin
    QuitAria2(False);
  end;
  m_cLock.Enter; // wait for the thread to rest
  FreeAndNil(m_cGetListThrd);
  FreeAndNil(m_cRPC);
  FreeAndNil(m_cDownloadList);
  FreeAndNil(m_cLock);
  inherited;
end;

function TAria2Delphi.DownloadTorrent(const sTorFile, sDir, sSelected: string;
  dwFlags: UInt32; var sGID: string): Integer;
var
  cItem: TAria2DownloadItem;
  sParams, sRet: string;
  i, j: Integer;
  s: string;
begin
  sGID := '';
  // Pause first
  Result := m_cRPC.AddTorrent(sTorFile, sDir, ARIA2_FLAG_PAUSE, sGID);
  if Result<>0 then Exit;

  if sGID<>'' then
  begin
    cItem := TAria2DownloadItem.Create(sTorFile, sGID);
    if m_cDownloadList.Add(cItem)<0 then
    begin
      cItem.Free;
      Exit;
    end;

    // Select files
    if (Length(sGID)>0) and (Length(sSelected)>0) then
    begin
      sParams := Format('"'+KEY_SEL_FILE+'":"%s"', [sSelected]);
      m_cRPC.ChangeOption(sGID, sParams, sRet);
    end;
    // Resume
    m_cRPC.UnPause(sGID, sRet);
    Result := 0;
    if m_cRPC.TellStatus(sGID, '"'+KEY_GID+'","'+KEY_EC+'","'+KEY_EMSG+'"', sRet)=0 then
    begin
      // May cause error after resume if duplicated
      // {"status":"error","errorCode":"12"}
      i := Pos('"'+KEY_EC+'"', sRet);
      if i>0 then
      begin
        sParams := Copy(sRet, i+11, 20);
        i := Pos('"', sParams);      // :"12", i=2,j=5
        j := Pos('"', sParams, i+1);
        if (i>0) and (j>0) then
        begin
          s := Copy(sParams, i+1, j-i-1);
          i := StrToIntDef(s, 0);
          sGID := sRet;  // whole message
          Result := i; // ARIA2 error code
        end;
      end;
    end;
    // Refresh download list
    GetDownloadList(nil, True);
  end;
end;

function TAria2Delphi.DownloadURL(const sURL, sDir: string; dwFlags: UInt32;
  var sGID: string): Integer;
begin
  Result := m_cRPC.AddURI(sURL, sDir, dwFlags, sGID);
end;

function TAria2Delphi.GetDownloadList(cResult: TStrings; bUpdNow: Boolean): Integer;
var
  sRet, sKeys: string;
  i: Integer;
  cItem: TAria2DownloadItem;
  eNotify: TThreadProcedure;
begin
  if bUpdNow then
  begin
    sKeys := '';
    m_cLock.Enter;
    try
      m_cDownloadList.Clear;
      i := m_cRPC.TellStopped(-1, 2000, '', sRet);
      if i=0 then
      begin
        m_bServerActive := True; // not great
        m_cDownloadList.LoadFromResult(sRet);
        for i := m_cDownloadList.Count-1 downto 0 do
        begin
          cItem := TAria2DownloadItem(m_cDownloadList[i]);
          case cItem.ErrorCode of
          0:
            begin
              if Assigned(m_eOnRemoveDownload) then
                m_eOnRemoveDownload(cItem.GID, cItem, REMOVE_BY_FINISH);
              m_cRPC.RemoveDownloadResult(cItem.GID, sRet);
            end;
          11, 12:
            begin
              // dup, delete
              if Assigned(m_eOnRemoveDownload) then
                m_eOnRemoveDownload(cItem.GID, cItem, REMOVE_BY_DUP);
              m_cRPC.RemoveDownloadResult(cItem.GID, sRet);
            end;
          end;
        end;
      end else
      begin
        if i<0 then // no server
        begin
          Result := i;
          m_bServerActive := False;
          Exit;
        end;
      end;
      m_cDownloadList.Clear;
      if m_cRPC.TellActive(sKeys, sRet)=0 then m_cDownloadList.LoadFromResult(sRet);
      if m_cRPC.TellWaiting(-1, 2000, '', sRet)=0 then m_cDownloadList.LoadFromResult(sRet);
      if m_cRPC.TellStopped(-1, 2000, '', sRet)=0 then m_cDownloadList.LoadFromResult(sRet);
      m_dtUpdate := Now;
      if cResult<>nil then m_cDownloadList.GetList(cResult);
      Result := m_cDownloadList.Count;
      eNotify := m_eOnUpdateList;
    finally
      m_cLock.Leave;
    end;
    if Assigned(eNotify) then // take outside to avoid dead lock
    try
      TThread.Synchronize(nil, eNotify); // TODO: use a procedure to call
    except
    end;
  end else
  begin
    m_cLock.Enter;
    if cResult<>nil then m_cDownloadList.GetList(cResult);
    Result := m_cDownloadList.Count;
    m_cLock.Leave;
  end;
end;

function TAria2Delphi.IsAria2Running(nPort: Integer): Boolean;
var
  sRet: string;
begin
  m_cRPC.SetHost('', nPort);
  if m_cRPC.GetVersion(sRet)=0 then
  begin
    Result := True;
    Exit;
  end;
  Result := False;
end;

procedure TAria2Delphi.Lock;
begin
  m_cLock.Enter;
end;

function TAria2Delphi.QuitAria2(bForce: Boolean): Integer;
var
  sRet: string;
begin
  Result := m_cRPC.Shutdown(bForce, sRet);
  m_bExecuted := False;
end;

function TAria2Delphi.SelectFiles(const sGID, sSelected: string;
  var sMsg: string): Integer;
begin
  Result := m_cRPC.ChangeOption(sGID, Format('"'+KEY_SEL_FILE+'":"%s"', [sSelected]), sMsg);
end;

procedure TAria2Delphi.SetAutoStart;
begin
  m_cGetListThrd.AutoStartAira2;
end;

procedure TAria2Delphi.SetOnUpdateList(const Value: TThreadProcedure);
begin
//  m_cLock.Enter;
  m_eOnUpdateList := Value;
//  m_cLock.Leave;
end;

procedure TAria2Delphi.Unlock;
begin
  m_cLock.Leave;
end;

function RunAria2(const sPath: string; nPort: Integer; dwFlags: UInt32): Boolean;
var
  sOld, s: string;
  bHide: Boolean;
begin
  // TODO: pipe stdout
  //CreatePipe(vStdInPipe.Output, vStdInPipe.Input, @vSecurityAttributes, 0)
  Result := False;
  sOld := GetCurrentDir();
  try
    SetCurrentDir(sPath);
    // TODO: backup log if exists
    s := Format('%s --enable-rpc --rpc-listen-port=%d --conf-path=%s', //--quiet --rpc-secret
      [ARIA2C_EXEC, nPort, ARAI2_DEF_CFG]);
    bHide := dwFlags and RUN_FLAG_HIDE<>0;
    if RunExe(s, bHide, 2000) then
    begin
      Result := True;
    end;
  finally
    SetCurrentDir(sOld);
  end;
end;

function TAria2Delphi.MakeSureRunAria2(bChkFirst: Boolean): Integer;
var
  b: Boolean;
begin
  if bChkFirst then
  if IsAria2Running(m_nAria2Port) then
  begin
    Result := 0;
    Exit;
  end;

  Result := -1;
  m_cLock.Enter;
  try
    b := RunAria2(m_sAria2Path, m_nAria2Port, m_dwRunFlags);
  finally
    m_cLock.Leave;
  end;
  if b then
  begin
    m_bExecuted := True;
    Sleep(500);
    if IsAria2Running(m_nAria2Port) then Result := 0;
  end;
end;

function TAria2Delphi.MoveTo(const sGID, sPos: string; var sMsg: string): Integer;
var
  s, sHow: string;
  nPos: Integer;
begin
  sHow := 'POS_SET';
  nPos := 0;
  s := AnsiLowercase(sPos);
  if s='' then
  begin
    Result := -2;
    Exit;
  end else
  begin
    if s='end' then
    begin
      sHow := 'POS_END';
    end else
    begin
      case s[1] of
      '+', '-': sHow := 'POS_CUR';  
      end;    
      nPos := StrToIntDef(s, 0);
    end;
  end;

  Result := m_cRPC.ChangePosition(sGID, nPos, sHow, sMsg);
end;

function TAria2Delphi.Pause(const sGID: string; bPause: Boolean; var sMsg: string): Integer;
begin
  if bPause then Result := m_cRPC.Pause(sGID, True, sMsg) else
    Result := m_cRPC.UnPause(sGID, sMsg);
end;

function TAria2Delphi.DeleteDownload(const sGID: string; var sMsg: string): Integer;
var
  i: Integer;
  cItem: TAria2DownloadItem;
  bFound: Boolean;
begin
  m_cLock.Enter;
  try
    bFound := False;
    cItem := nil;
    for i := m_cDownloadList.Count-1 downto 0 do
    begin
      cItem := TAria2DownloadItem(m_cDownloadList[i]);
      if cItem.GID=sGID then
      begin
        bFound := True;
        Break;
      end;
    end;
    if not bFound then cItem := nil;

    Result := m_cRPC.Remove(sGID, True, sMsg);
    if Result<>0 then
    begin
      Result := m_cRPC.RemoveDownloadResult(sGID, sMsg);
    end;
    if Result=0 then
    begin
      if Assigned(m_eOnRemoveDownload) then
        m_eOnRemoveDownload(cItem.GID, cItem, REMOVE_BY_USER);
      m_cRPC.PurgeDownloadResult;
    end;
  finally
    m_cLock.Leave;
  end;
end;

function GetDirJson(const sDir: string): string;
var
  i, j, n: Integer;
begin
  n := Length(sDir);
  SetLength(Result, 2*n);
  if (n>0) then
    case sDir[n] of
    '\', '/': Dec(n);
    end;

  j := 0;
  for i := 1 to n do
  begin
    Inc(j);
    case sDir[i] of
    '\', '/':
      begin
        Result[j] := '\';
        Inc(j);
      end;
    end;
    Result[j] := sDir[i];
  end;
  SetLength(Result, j);
end;

{ TAria2JSONRpc }

function TAria2JSONRpc.AddMetalink(const sMLinkFile, sDir: string; dwFlags: UInt32;
  var sResult: string): Integer;
var
  sParams, sExtParams: string;
  cEnc64: TBase64Encoding;
  cMTFile: TFileStream;
  cOutStm: TStringStream;
begin
  cMTFile := TFileStream.Create(sMLinkFile, fmOpenRead or fmShareDenyNone);
  cOutStm := TStringStream.Create;
  cEnc64 := TBase64Encoding.Create;
  try
    cEnc64.Encode(cMTFile, cOutStm);
    sParams := '"'+cOutStm.DataString+'"';
  finally
    cEnc64.Free;
    cOutStm.Free;
    cMTFile.Free;
  end;

  sExtParams := '';
  if dwFlags and ARIA2_FLAG_PAUSE<>0 then sExtParams := sExtParams+'"'+KEY_PAUSE+'":"true"';
  if sDir<>'' then
  begin
    if sExtParams<>'' then sExtParams := sExtParams+',';
    sExtParams := sExtParams+Format('"'+KEY_DIR+'":"%s"', [GetDirJson(sDir)]);
  end;
  if sExtParams<>'' then
    sParams := sParams + ',{'+sExtParams+'}';
  if dwFlags and ARIA2_FLAG_TO_HEAD<>0 then  // TODO: test
  begin
    sParams := sParams+',0';
  end;

  Result := Request(METHOD_ADD_METALINK, sParams, 0, sResult);
end;

function TAria2JSONRpc.AddTorrent(const sTorFile, sDir: string; dwFlags: UInt32;
  var sResult: string): Integer;
var
  sExtParams, sParams: string;
  cEnc64: TBase64Encoding;
  cTorFile: TFileStream;
  cOutStm: TStringStream;
begin
//{
//	"jsonrpc": "2.0",
//	"method": "aria2.addTorrent",
//	"id": "xxx",
//	"params": ["token:xxxxx", "torrentµÄbase64Öµ", [], {}]
//}

{
aria2.addTorrent([secret, ]torrent[, uris[, options[, position]]])
}

  cTorFile := TFileStream.Create(sTorFile, fmOpenRead or fmShareDenyNone);
  cOutStm := TStringStream.Create;
  cEnc64 := TBase64Encoding.Create;
  try
    cEnc64.Encode(cTorFile, cOutStm);
    sParams := '"'+cOutStm.DataString+'"';
  finally
    cEnc64.Free;
    cOutStm.Free;
    cTorFile.Free;
  end;
  sExtParams := '';
  if dwFlags and ARIA2_FLAG_PAUSE<>0 then sExtParams := sExtParams+'"'+KEY_PAUSE+'":"true"';
  if sDir<>'' then
  begin
    if sExtParams<>'' then sExtParams := sExtParams+',';
    sExtParams := sExtParams+Format('"'+KEY_DIR+'":"%s"', [GetDirJson(sDir)]);
  end;
  if sExtParams<>'' then
    sParams := Format('%s,[],{%s}', [sParams, sExtParams]);
  if dwFlags and ARIA2_FLAG_TO_HEAD<>0 then  // TODO: test
  begin
    sParams := sParams+',0';
  end;
  Result := Request(METHOD_ADD_TOR, sParams, ARIA2_FLAG_NO_ENCODE, sResult);
end;

function TAria2JSONRpc.AddURI(const sURI, sDir: string; dwFlags: UInt32;
  var sResult: string): Integer;
var
  sParams, sExtParams: string;
begin
//{
//    "jsonrpc": "2.0",
//    "id": "10",
//    "method": "aria2.addUri",
//    "params":
//    [
//        [
//            "http://url/to/a.torrent"
//        ],
//        {
//            "pause": "true",
//            'dir': 'D:\Downloads',
//            'out': 'button.png'
//        }
//    ]
//}
  sParams := '["'+sURI+'"]';
  sExtParams := '';
  if dwFlags and ARIA2_FLAG_PAUSE<>0 then sExtParams := sExtParams+'"'+KEY_PAUSE+'":"true"';
  if sDir<>'' then
  begin
    if sExtParams<>'' then sExtParams := sExtParams+',';
    sExtParams := sExtParams+Format('"'+KEY_DIR+'":"%s"', [GetDirJson(sDir)]);
  end;
  if sExtParams<>'' then
    sParams := sParams + ',{'+sExtParams+'}';
  if dwFlags and ARIA2_FLAG_TO_HEAD<>0 then  // TODO: test
  begin
    sParams := sParams+',0';
  end;

  Result := Request(METHOD_ADD_URI, sParams, 0, sResult);
end;

function TAria2JSONRpc.ChangeOption(const sGID, sOptions: string; var sResult: string): Integer;
begin
  if sGID<>'' then
    Result := Request(METHOD_CHG_OPT, Format('"%s",{%s}', [sGID, sOptions]), 0, sResult)
  else
    Result := Request(METHOD_CHG_GOPT, Format('{%s}', [sOptions]), 0, sResult);
end;

function TAria2JSONRpc.ChangePosition(const sGID: string; nPos: Integer;
  const sHow: string; var sResult: string): Integer;
begin
  // Works only in waiting queue
  // errorCode=1 GID#c17e3d141b357d90 not found in the waiting queue.
  Result := Request(METHOD_CHG_POS, Format('"%s",%d,"%s"', [sGID, nPos, sHow]), 0, sResult);
end;

constructor TAria2JSONRpc.Create(const sSecret: string);
begin
  m_cLock := TCriticalSection.Create;
  m_cHttp := TIdHttp.Create(nil);
  m_cHttp.Request.Accept := CT_APP_JSON;
  SetHost('127.0.0.1', ARIA2_DEF_PORT);
  m_sSecret := sSecret;
  inherited Create;
end;

destructor TAria2JSONRpc.Destroy;
begin
  FreeAndNil(m_cHttp);
  FreeAndNil(m_cLock);
  inherited;
end;

function TAria2JSONRpc.GetResult(var sResult: string): Integer;
var
  jv: TJSONValue;
  jo: TJSONObject;
  jp: TJSONPair;
  sVer: string;
  sID: string;
begin
  Result := -1;
  //{"id":"pfm1","jsonrpc":"2.0","result":"71f4d6f726bcc8f7"}
  //{"jsonrpc": "2.0", "result": "gid", "id": 2}
  //{"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "1"}
  //Log(sResult, False);
  jv := TJSONObject.ParseJSONValue(sResult);
  try
    if jv is TJSONObject then
    begin
      Result := -2;
      jo := TJSONObject(jv);
      jp := jo.Get('jsonrpc');
      if jp<>nil then
      begin
        sVer := jp.JsonValue.Value;
        jp := jo.Get('id');
        if jp<>nil then
        begin
          sID := jp.JsonValue.Value;
          Result := -3;
          if sID=Format(FMT_JRPCID, [m_nID]) then
          begin
            jp := jo.Get('result');
            if jp<>nil then
            begin
              if (jp.JsonValue is TJSONString) then
              begin
                sResult := jp.JsonValue.Value;
              end else
              //if jp.JsonValue is TJSONArray then
              begin
                sResult := jp.JsonValue.ToJSON;
              end;
              Result := 0;
            end else
            begin
              jp := jo.Get('error');
              if jp<>nil then
              begin
                jo := TJSONObject(jp);
                jp := jo.Get('code');
                if jp<>nil then
                  Result := StrToIntDef(jp.JsonValue.Value, -4);
                jp := jo.Get('message');
                if jp<>nil then
                  sResult := jp.JsonValue.Value;
              end;
            end;
          end;
        end;
      end;
    end;
  finally
    jv.Free;
  end;
end;

function TAria2JSONRpc.GetServers(const sGID: string;
  var sResult: string): Integer;
begin
  Result := Request(METHOD_GET_SERVERS, '"'+sGID+'"', 0, sResult);
end;

function TAria2JSONRpc.GetFiles(const sGID: string; var sResult: string): Integer;
begin
  Result := Request(METHOD_GET_FILES, '"'+sGID+'"', 0, sResult);
end;

function TAria2JSONRpc.GetGlobalStat(var sResult: string): Integer;
begin
  Result := Request(METHOD_GET_GSTAT, '', 0, sResult);
end;

function TAria2JSONRpc.GetOption(const sGID: string; var sResult: string): Integer;
begin
  if sGID<>'' then
    Result := Request(METHOD_GET_OPTION, '"'+sGID+'"', 0, sResult)
  else
    Result := Request(METHOD_GET_GOPTION, '', 0, sResult);
end;

function TAria2JSONRpc.GetPeers(const sGID: string;
  var sResult: string): Integer;
begin
  Result := Request(METHOD_GET_PEERS, '"'+sGID+'"', 0, sResult);
end;

function TAria2JSONRpc.GetURIs(const sGID: string; var sResult: string): Integer;
begin
  Result := Request(METHOD_GET_URIS, '"'+sGID+'"', 0, sResult);
end;

function TAria2JSONRpc.GetVersion(var sResult: string): Integer;
begin
  Result := Request(METHOD_GET_VER, '', 0, sResult);
end;

function TAria2JSONRpc.Pause(const sGID: string; bForce: Boolean; var sResult: string): Integer;
begin
  if sGID='' then
  begin
    if bForce then
      Result := Request(METHOD_FORCE_PAUSE_ALL, '', 0, sResult)
    else
      Result := Request(METHOD_PAUSE_ALL, '', 0, sResult);
  end else
  begin
    if bForce then
      Result := Request(METHOD_FORCE_PAUSE, '"'+sGID+'"', 0, sResult)
    else
      Result := Request(METHOD_PAUSE, '"'+sGID+'"', 0, sResult);
  end;
end;

function TAria2JSONRpc.PurgeDownloadResult: string;
begin
  Request(METHOD_PURGE_RESULT, '', 0, Result);
end;

function TAria2JSONRpc.Remove(const sGID: string; bForce: Boolean; var sResult: string): Integer;
begin
  if bForce then
    Result := Request(METHOD_FORCE_REMOVE, '"'+sGID+'"', 0, sResult)
  else
    Result := Request(METHOD_REMOVE, '"'+sGID+'"', 0, sResult);
end;

function TAria2JSONRpc.RemoveDownloadResult(const sGID: string; var sResult: string): Integer;
begin
  Result := Request(METHOD_REMOVE_DOWNLOAD_RESULT, '"'+sGID+'"', 0, sResult);
end;

function TAria2JSONRpc.Request(const sMethod, sParams: string;
  dwFlags: UInt32; var sResult: string): Integer;
var
  sReq, s: string;
  cStm: TStringStream;
  cEnc64: TBase64Encoding;
begin
  m_cLock.Enter;
  try
    Inc(m_nID);
    m_cHttp.Response.ResponseCode := 0; // reset
    //jsonrpc?method=METHOD_NAME&id=ID&params=BASE64_ENCODED_PARAMS
    if m_bUseGet then
    begin
      if dwFlags and ARIA2_FLAG_NO_ENCODE=0 then
      begin
        cEnc64 := TBase64Encoding.Create;
        sReq := cEnc64.Encode(sParams);
        cEnc64.Free;
      end else
        sReq := sParams;
      sResult := m_cHttp.Get(Format('%s?method=%s&id='+FMT_JRPCID+'&params=%s',
        [m_sRpcAddr, sMethod, m_nID, sReq]));
    end else
    begin
      if dwFlags and ARIA2_FLAG_NO_ENCODE=0 then
        s := string(UTF8Encode(sParams)) else
        s := sParams;
      if m_sSecret<>'' then
        s := '"token:'+m_sSecret+'",'+s;
      sReq := Format('{"jsonrpc":"2.0","id":"'+FMT_JRPCID+'","method":"%s","params":[%s]}',
        [m_nID, sMethod, s]);

      m_cHttp.Request.ContentType := CT_APP_JSON;
      //if m_cHttp.IOHandler=nil then
      //  m_cHttp.CreateIOHandler();
      //if m_nConnectTimeOut>0 then
      //  m_cHttp.IOHandler.ConnectTimeout := m_nConnectTimeOut;
      cStm := TStringStream.Create(sReq);
      try
        sResult := m_cHttp.Post(m_sRpcAddr, cStm);
      finally
        cStm.Free;
      end;
    end;
    Result := m_cHttp.ResponseCode;
    if (Result>=200) and (Result<300) then
      Result := GetResult(sResult)
    else
      Result := -Result; // make it < 0
  except
    Result := -m_cHttp.ResponseCode;
    if Result=0 then Result := -408;

    sResult := m_cHttp.ResponseText;
    if sResult='' then
    begin
      sResult := Format(g_sAria2ErrCodeFmt, [Result]);
    end;
  end;
  m_cLock.Leave;
end;

procedure TAria2JSONRpc.SetHost(const sHost: string; nPort: Integer);
var
  s: string;
begin
  s := sHost;
  if s='' then s := LOCAL_HOST;
  if nPort<=0 then nPort := ARIA2_DEF_PORT;
  m_sRpcAddr := Format('http://%s:%d/jsonrpc', [s, nPort]);
end;

function TAria2JSONRpc.Shutdown(bForce: Boolean; var sResult: string): Integer;
begin
  if bForce then
    Result := Request(METHOD_FORCE_SHUTDOWN, '', 0, sResult)
  else
    Result := Request(METHOD_SHUTDOWN, '', 0, sResult);
end;

function TAria2JSONRpc.TellActive(const sKeys: string; var sResult: string): Integer;
var
  sParams: string;
begin
  if sKeys<>'' then sParams := '['+sKeys+']' else sParams := '';
  Result := Request(METHOD_TELL_ACTIVE, sParams, 0, sResult);
end;

function TAria2JSONRpc.TellStatus(const sGID, sKeys: string; var sResult: string): Integer;
var
  sAddParams: string;
begin
  if sKeys<>'' then sAddParams := ',['+sKeys+']' else sAddParams := '';
  Result := Request(METHOD_TELL_STATUS, Format('"%s"%s', [sGID, sAddParams]), 0, sResult);
end;

function TAria2JSONRpc.TellStopped(nOfs, nNum: Integer; const sKeys: string; var sResult: string): Integer;
var
  sAddParams: string;
begin
  if sKeys<>'' then sAddParams := ',['+sKeys+']' else sAddParams := '';
  Result := Request(METHOD_TELL_STOPPED, Format('%d,%d%s', [nOfs, nNum, sAddParams]), 0, sResult);
end;

function TAria2JSONRpc.TellWaiting(nOfs, nNum: Integer; const sKeys: string; var sResult: string): Integer;
var
  sAddParams: string;
begin
  if sKeys<>'' then sAddParams := ',['+sKeys+']' else sAddParams := '';
  Result := Request(METHOD_TELL_WAITING, Format('%d,%d%s', [nOfs, nNum, sAddParams]), 0, sResult);
end;

function TAria2JSONRpc.UnPause(const sGID: string; var sResult: string): Integer;
begin
  if sGID='' then
    Result := Request(METHOD_UNPAUSE_ALL, '', 0, sResult)
  else
    Result := Request(METHOD_UNPAUSE, '"'+sGID+'"', 0, sResult);
end;


{ TAria2DownloadItem }

procedure TAria2DownloadItem.Clear;
begin
  m_nIndex := 0;
  m_sName := '';
  m_sGID := '';
  m_sURL := '';
  m_nType := ARIA2_ITEM_NONE;
  m_eStatus := asUnknown;
  m_nTotalLength := 0;
  m_nCompletedLength := 0;
  m_nUploadLength := 0;
  m_nDownSpeed := 0;
  m_nUpSpeed := 0;
  m_dtAdded := 0;
  m_sDir := '';
  m_nConnections := 0;
  m_nPieces := 0;
  m_nVerifiedLength := 0;

  // Torrent
  m_nSeeders := 0;
  m_sHash := '';
  m_dtCreate := 0;
  m_sComment := '';

  m_nErrorCode := 0;
  m_sErrorMsg := '';

  m_cFiles.Clear;
end;

function TAria2DownloadItem.Clone: TAria2DownloadItem;
begin
  Result := TAria2DownloadItem.Create(m_sURL, m_sGID);
  Result.Idx := m_nIndex;
  Result.Name := m_sName;
  Result.Dir := m_sDir;
  Result.Typ := m_nType;
  Result.Status := m_eStatus;
  Result.TotalLength := m_nTotalLength;
  Result.CompletedLength := m_nCompletedLength;
  Result.DownSpeed := m_nDownSpeed;
  Result.Connections := m_nConnections;
  Result.Added := m_dtAdded;
  Result.UpSpeed := m_nUpSpeed;
  Result.UpLenght := m_nUploadLength;
  Result.Pieces := m_nPieces;
  Result.VerifiedLength := m_nVerifiedLength;
  Result.Hash := m_sHash;
  Result.Seeders := m_nSeeders;
  Result.CreateDate := m_dtCreate;
  Result.Comment := m_sComment;
  Result.ErrorCode := m_nErrorCode;
  Result.ErrorMessage := m_sErrorMsg;
  m_cFiles.CopyTo(Result.Files);
end;

constructor TAria2DownloadItem.Create(const sURL, sGID: string);
begin
  m_sURL := sURL;
  m_sGID := sGID;
  m_dtAdded := Now;
  m_cFiles := TAria2ItemFileList.Create;
  inherited Create;
end;

function TAria2DownloadItem.GetFromStatus(const sStatus: string): Boolean;
var
  jv: TJSONValue;
  jo: TJSONObject;
begin
  Result := False;
  try
    jv := TJSONObject.ParseJSONValue(sStatus);
    if jv is TJSONObject then
    try
      jo := TJSONObject(jv);
      Result := GetFromStatus(jo);
    finally
      jv.Free;
    end;
    Result := True;
  except
  end;
end;

function TAria2DownloadItem.GetTorrentInfo(jo: TJSONObject): Boolean;
var
  jo1: TJSONObject;
  jp: TJSONPair;
  n: Int64;
  V: Double;
begin
  Result := False;

  jp := jo.Get(KEY_CREATE_DATE);
  if jp<>nil then
  begin
    n := StrToInt64Def(jp.JsonValue.Value, 0);
    if n>0 then
    begin
      V := SecondSpan(Now, 25569);
      V := (V - n) / SecsPerDay;
      m_dtCreate := Now - V
    end;
  end;

  jp := jo.Get(KEY_COMMENT);
  if jp<>nil then
  begin
    m_sComment := StringFromJSString(jp.JsonValue.Value);
  end;

  jp := jo.Get(KEY_INFO);
  if jp<>nil then
  begin
    jo1 := TJSONObject(jp.JsonValue);
    jp := jo1.Get(KEY_NAME);
    if jp<>nil then
      m_sName := StringFromJSString(jp.JsonValue.Value);
    Result := True;
  end;
end;

destructor TAria2DownloadItem.Destroy;
begin
  m_cFiles.Free;
  inherited;
end;

function TAria2DownloadItem.GetFromStatus(jo: TJSONObject): Boolean;
var
  btjo: TJSONObject;
  jp: TJSONPair;
  s: string;
  i: Integer;
begin
  Clear;
  Result := False;
  jp := jo.Get(KEY_INDEX);
  if jp<>nil then
    m_nIndex := StrToIntDef(jp.JsonValue.Value, 0);

  jp := jo.Get(KEY_EC);
  if jp<>nil then
    m_nErrorCode := StrToIntDef(jp.JsonValue.Value, 0);
  jp := jo.Get(KEY_EMSG);
  if jp<>nil then
    m_sErrorMsg := jp.JsonValue.Value; // StringFromJSString()?

  jp := jo.Get(KEY_GID);
  if jp<>nil then
  begin
    Result := True;
    m_sGID := jp.JsonValue.Value;
  end;
  jp := jo.Get(KEY_DIR);
  if jp<>nil then
    m_sDir := IncludeTrailingPathDelimiter(jp.JsonValue.Value);

  jp := jo.Get(KEY_DL_SPEED);
  if jp<>nil then
    m_nDownSpeed := StrToIntDef(jp.JsonValue.Value, 0);
  jp := jo.Get(KEY_DONE_LEN);
  if jp<>nil then
    m_nCompletedLength := StrToInt64Def(jp.JsonValue.Value, 0);
  jp := jo.Get(KEY_TOTAL_LEN);
  if jp<>nil then
    m_nTotalLength := StrToInt64Def(jp.JsonValue.Value, 0);
  jp := jo.Get(KEY_CONN);
  if jp<>nil then
    m_nConnections := StrToIntDef(jp.JsonValue.Value, 0);
  jp := jo.Get(KEY_UP_SPEED);
  if jp<>nil then
    m_nUpSpeed := StrToIntDef(jp.JsonValue.Value, 0);
  jp := jo.Get(KEY_UP_LEN);
  if jp<>nil then
    m_nUploadLength := StrToInt64Def(jp.JsonValue.Value, 0);
  jp := jo.Get(KEY_NUM_PIECE);
  if jp<>nil then
    m_nPieces := StrToIntDef(jp.JsonValue.Value, 0);
  jp := jo.Get(KEY_VER_LEN);
  if jp<>nil then
    m_nVerifiedLength := StrToInt64Def(jp.JsonValue.Value, 0);

  jp := jo.Get(KEY_STATUS);
  if jp<>nil then
  begin
    s := AnsiLowercase(jp.JsonValue.Value);
    if s=KEY_ACTIVE then m_eStatus := asActive
    else if s=KEY_PAUSED then m_eStatus := asPaused
    else if s=KEY_WAITING then m_eStatus := asWaiting
    else if s=KEY_COMPLETE then m_eStatus := asComplete
    else if s=KEY_REMOVED then m_eStatus := asRemoved
    else if s=KEY_ERROR then m_eStatus := asError
    else m_eStatus := asUnknown;
  end;

  jp := jo.Get(KEY_FILES);
  if jp<>nil then
  begin
    if jp.JsonValue is TJSONArray then
      m_cFiles.LoadFromJson(TJSONArray(jp.JsonValue), m_sDir);
  end;

  jp := jo.Get(KEY_BT);
  if jp<>nil then
  begin
    btjo := TJSONObject(jp.JsonValue);
    GetTorrentInfo(btjo);
    m_nType := ARIA2_ITEM_TOR;
    jp := jo.Get(KEY_INFO_HASH);
    if jp<>nil then
      m_sHash := jp.JsonValue.Value;
    jp := jo.Get(KEY_SEEDS);
    if jp<>nil then
      m_nSeeders := StrToIntDef(jp.JsonValue.Value, 0);
  end;

  if m_sURL='' then
  begin
    if m_cFiles.Count>0 then // for BT URL might be blank
    begin
      m_sURL := TAria2ItemFile(m_cFiles[0]).URL;
    end;
  end;

  if m_sName='' then
  begin
    if m_sURL<>'' then
    begin
      i := LastDelimiter('/', m_sURL);
      if i<=0 then i := LastDelimiter('\', m_sURL);
      if i>0 then
      begin
        m_sName := Copy(m_sURL, i+1, MaxInt);
      end;
    end;
  end;
end;

{ TAria2DownloadList }

function TAria2DownloadList.FindByGID(const sGID: string): TAria2DownloadItem;
var
  i: Integer;
  cItem: TAria2DownloadItem;
begin
  for i := 0 to Count-1 do
  begin
    cItem := TAria2DownloadItem(Get(i));
    if cItem.GID=sGID then
    begin
      Result := cItem;
      Exit;
    end;
  end;
  Result := nil;
end;

function TAria2DownloadList.GetList(cResult: TStrings): Integer;
var
  i: Integer;
  cItem: TAria2DownloadItem;
  s: string;
begin
  Result := Count;
  cResult.BeginUpdate;
  for i := 0 to Count-1 do
  begin
    cItem := TAria2DownloadItem(Get(i));
    s := Format('Type=%d;Name=%s;GID=%s;Status=%s;Code=%d;SpeedDown=%d;SpeedUp=%d;'+
     'Total=%d;Current=%d;Connection=%d;Seed=%d;Files=%d/%d;Dir=%s;URL=%s;Error=%s',
      [cItem.Typ, cItem.Name, cItem.GID, GetAria2StatusText(cItem.Status),
       cItem.ErrorCode, cItem.DownSpeed, cItem.UpSpeed, cItem.TotalLength,
       cItem.CompletedLength, cItem.Connections, cItem.Seeders,
       cItem.Files.SelectedCount, cItem.Files.Count, cItem.Dir, cItem.URL,
       cItem.ErrorMessage]);
    cResult.AddObject(s, cItem);
  end;
  cResult.EndUpdate;
end;

function TAria2DownloadList.LoadFromResult(const sRet: string): Integer;
var
  jv: TJSONValue;
  ja: TJSONArray;
  jo: TJSONObject;
  i: Integer;
  cItem: TAria2DownloadItem;
begin
  Result := 0;
  try
    jv := TJSONObject.ParseJSONValue(sRet);
    if jv is TJSONArray then
    try
      ja := TJSONArray(jv);
      for i := 0 to ja.Count-1 do
      begin
        jo := TJSONObject(ja.Items[i]);
        cItem := TAria2DownloadItem.Create('', '');
        if cItem.GetFromStatus(jo) then
        begin
          if Add(cItem)<0 then cItem.Free;
        end else
          cItem.Free;
      end;
    finally
      jv.Free;
    end;
  except
  end;
end;


{ TAria2ItemFile }

procedure TAria2ItemFile.Assign(cItem: TAria2ItemFile);
begin
  m_nIndex := cItem.Idx;
  m_sPath := cItem.Path;
  m_nTotalLength := cItem.TotalLength;
  m_nCompletedLength := cItem.CompletedLength;
  m_bSelected := cItem.Selected;
  m_nHealth := cItem.Health;
  m_sURL := cItem.URL;
end;

{ TAria2ItemFileList }

function TAria2ItemFileList.CopyTo(cList: TAria2ItemFileList): Integer;
var
  i: Integer;
  cItem1, cItem2: TAria2ItemFile;
begin
  for i := 0 to Count-1 do
  begin
    cItem1 := TAria2ItemFile(Get(i));
    cItem2 := TAria2ItemFile.Create;
    cItem2.Assign(cItem1);
    if cList.Add(cItem2)<0 then cItem2.Free;
  end;
  Result := Count;
end;

function TAria2ItemFileList.LoadFromJson(jy: TJSONArray; const sBaseDir: string): Integer;
var
  jo: TJSONObject;
  jp: TJSONPair;
  jv: TJSONValue;
  jy1: TJSONArray;
  i, j: Integer;
  cItem: TAria2ItemFile;
  s, s1, lasturl: string;
begin
  Clear;
  for i := 0 to jy.Count-1 do
  begin
    jo := TJSONObject(jy.Items[i]);
    jp := jo.Get(KEY_PATH);
    if jp<>nil then
    begin
      cItem := TAria2ItemFile.Create;
      cItem.Path := StringFromJSString(jp.JsonValue.ToJson);
      jp := jo.Get(KEY_INDEX);
      if jp<>nil then
        cItem.Idx := StrToIntDef(jp.JsonValue.Value, -1);
      jp := jo.Get(KEY_DONE_LEN);
      if jp<>nil then
        cItem.CompletedLength := StrToInt64Def(jp.JsonValue.Value, -1);
      jp := jo.Get(KEY_LENGTH);
      if jp<>nil then
        cItem.TotalLength := StrToInt64Def(jp.JsonValue.Value, -1);
      jp := jo.Get(KEY_SELECTED);
      if jp<>nil then
        cItem.Selected := AnsiLowercase(jp.JsonValue.Value) = 'true';
      jp := jo.Get(KEY_URIS);
      if jp<>nil then
      begin
        // [{"status":"used","uri":"https:\/\/abc.com\/def.rar"},]

        if jp.JsonValue is TJSONArray then
        begin
          jy1 := TJSONArray(jp.JsonValue);
          s := '';
          lasturl := '';
          for j := 0 to jy1.Count-1 do
          begin
            jv := jy1[j];
            if jv is TJSONString then
            begin
              s1 := StringFromJSString(TJSONString(jv).ToJSON);
              if lasturl<>s1 then
              begin
                s := s+s1+';';
                lasturl := s1;
              end;
            end else
            if jv is TJSONObject then
            begin
              jo := TJSONObject(jv);
              jp := jo.Get(KEY_URI);
              if jp<>nil then
              begin
                s1 := StringFromJSString(jp.JsonValue.ToJSON);
                if lasturl<>s1 then
                begin
                  s := s+s1+';';
                  lasturl := s1;
                end;
              end;
            end;
          end;
          if Length(s)>0 then
          begin
            SetLength(s, Length(s)-1);
            cItem.URL := s;
          end;
        end else
        begin
          cItem.URL := StringFromJSString(jp.JsonValue.ToJSON);
        end;
      end;

      if cItem.URL='' then
      begin
        if PathDelim='\' then
          s := StringReplace(cItem.Path, '/', PathDelim, [rfReplaceAll])
        else
          s := cItem.Path;
        s1 := IncludeTrailingPathDelimiter(sBaseDir);
        if sBaseDir='' then cItem.URL := ExtractFileName(s) else
        begin
          if Pos(s1, s)=1 then
            System.Delete(s, 1, Length(s1));
          cItem.URL := s;
        end;
      end;

      if Add(cItem)<0 then cItem.Free;
    end;
  end;

  Result := Count;
end;

function TAria2ItemFileList.SelectedCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count-1 do
  begin
    if TAria2ItemFile(Get(i)).Selected then Inc(Result);
  end;
end;

{ TAria2GetListThread }

procedure TAria2GetListThread.AutoStartAira2;
begin
  m_bAutoStart := True;
  m_cEvent.SetEvent;
end;

constructor TAria2GetListThread.Create(cAria2: TAria2Delphi; nSleep: Integer;
  bAutoStart: Boolean);
begin
  m_nSleep := nSleep;
  m_cAria2 := cAria2;
  m_bAutoStart := bAutoStart;
  m_cEvent := TSimpleEvent.Create();
  inherited Create(False);
  //FreeOnTerminate := True;
end;

destructor TAria2GetListThread.Destroy;
begin
  Terminate;
  WaitFor;
  inherited;
  m_cEvent.Free;
end;

procedure TAria2GetListThread.Execute;
begin
  try
    while not Terminated do
    begin
      m_cEvent.WaitFor(m_nSleep);
      m_cEvent.ResetEvent;
      if Terminated then Break;
      if m_cAria2.GetDownloadList(nil, True)<0 then
      begin
        // auto start aria2?
        if m_bAutoStart then
        begin
          m_bAutoStart := False;
          m_cAria2.MakeSureRunAria2(False);
        end;
        if Assigned(m_cAria2.OnErrorConnect) then
        try
          TThread.Synchronize(nil, m_cAria2.OnErrorConnect);
        except
        end;
      end;
    end;
  except
  end;
end;

procedure TAria2GetListThread.NotifyGetList;
begin
  m_cEvent.SetEvent;
end;

procedure TAria2GetListThread.TerminatedSet;
begin
  inherited;
  m_cEvent.SetEvent;
end;

initialization
finalization
  FreeAndNil(g_cAria2Inst);

end.
