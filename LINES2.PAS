Program Lines2;
{$G3+}
{$M 32768}
{$PMType PM}
uses PMApp, OS2PMApi, Strings, Os2Base, Os2Def, Objects, Format, Os2MM, PMValid;

{$R Lines2.Res}

{$Define UsesMM}

{*$Define MMDebug}

const
  CellSize      = 36;
  InfoCellSize  = 30;
  BallSize      = 26;
  BallDstr2Size = 30;
  GameAreaSize  = 9;
  BallColors    = 7;
  ResBmpCount   = BallColors*4;
  BallAnStep    = 3;
  LineLength    = 5;

  {score window}
  ScoreWinSizeW = 64;
  ScoreWinSizeH = 22;

  {base window}
  gawDX1 =  4;
  gawDX2 = 128;
  gawDY1 =  4;
  gawDY2 =  2;
  GameAreaBorderX = 12;
  GameAreaBorderY = 12;

  ArrowW = 26;
  ArrowH = 26;

  CBButtonW = 90;
  CBButtonH = 22;

  ButtonW = 90;
  ButtonH = 24;

  SliderW = 90;
  SliderH = 16;

  Top10Dx     = 4;
  Top10Dy     = 4;
  Top10ColNum = 3;

  id_Cell_0     = id_User; {100}
  id_MainWindow = 200;
  id_Arrow      = 230;
  id_Top10Window= 269;
  id_AboutDlg   = 270;

  id_PopupMenu  = 280;

  cm_NewGame   = id_PopupMenu+1;
  cm_Path      = id_PopupMenu+3;
  cm_NextColor = id_PopupMenu+4;
  cm_Sound     = id_PopupMenu+5;

  id_User2      = 300;

  id_Timer          = id_User2+1;
  id_Score          = id_User2+2;
  id_Timer_NewGame  = id_User2+3;
  id_InfoCell_0     = id_User2+4;
  id_PathButton     = id_User2+7;
  id_NextButton     = id_User2+8;
  id_SoundButton    = id_User2+9;
  id_NewGameButton  = id_User2+10;
  id_Top10Button    = id_User2+11;
  id_AboutButton    = id_User2+12;
  id_Top10Container = id_User2+13;
  id_Slider         = id_User2+14;

  wm_Appearance    = wm_User+1;
  wm_DisAppearance = wm_User+2;
  wm_ReInitCell    = wm_User+3;
  wm_CellSelect    = wm_User+4;
  wm_CellUnselect  = wm_User+5;
  wm_DestroyBall   = wm_User+6;
  wm_NextColor     = wm_User+7;
  wm_Jamp          = wm_User+8;
  wm_DrawArrow     = wm_User+9;
  wm_ClearArrow    = wm_User+10;
  wm_ButtonChecked = wm_User+11;
  wm_UpdateList    = wm_User+12;
  wm_PopupMenu     = wm_User+13;
  wm_CloseTop10Win = wm_User+14;

  clr_Cell_Back = clr_Palegray;

  ObjT_Champion = 4000;
  EnCodeByte  = $6D;

  IniName = 'Lines2.Ini';

  RecordBufSize = 40;

type
  TLines=object(TApplication)
    constructor Init;
    procedure InitMainWindow; virtual;
    procedure LoadIni;
    procedure StoreIni;
    procedure CheckMultiMedia;
    destructor Done; virtual;
  end;

  PBaseFrameWindow=^TBaseFrameWindow;
  TBaseFrameWindow=object(TFrameWindow)
    constructor Init(aParent:PWindowsObject;aTitle:PChar);
    procedure InitClientWindow; virtual;
    procedure CloseWindow; virtual;
  end;

  TBallMode=(None,Up,Down);

  PCell=^TCell;
  TCell=object(TWindow)
    Value:Byte;
    BallPnt:PointL;
    BX,BY:byte;
    constructor Init(aParent:PWindowsObject;anID:LongInt;X,Y,Sz:LongInt);
    procedure Paint(PS:HPS; var Rect:RectL); virtual;
    procedure WMAppearance(var Msg:TMessage);    virtual wm_First + wm_Appearance;
    procedure WMButton1Down(var Msg:TMessage);   virtual wm_First + wm_Button1Down;
    procedure WMButton2Click(var Msg:TMessage);  virtual wm_First + wm_Button2Click;
    procedure WMClearArrow(var Msg:TMessage);    virtual wm_First + wm_ClearArrow;
    procedure WMDestroyBall(var Msg:TMessage);   virtual wm_First + wm_DestroyBall;
    procedure WMDisAppearance(var Msg:TMessage); virtual wm_First + wm_DisAppearance;
    procedure WMDrawArrow(var Msg:TMessage);     virtual wm_First + wm_DrawArrow;
    procedure WMReInitCell(var Msg:TMessage);    virtual wm_First + wm_ReInitCell;
    procedure WMTimer(var Msg:TMessage);         virtual wm_First + wm_Timer;
    procedure WMUnselect(var Msg:TMessage);      virtual wm_First + wm_CellUnselect;
    destructor Done; virtual;
  private
    BallMode:TBallMode;
    procedure InitBallPnt;
    procedure MoveBall;
  end;

  PInfoCell=^TInfoCell;
  TInfoCell=object(TCell)
    procedure Paint(PS:HPS; var Rect:RectL); virtual;
    procedure WMButton1Down(var Msg:TMessage);  virtual wm_First + wm_Button1Down;
    procedure WMButton2Click(var Msg:TMessage); virtual wm_First + wm_Button2Click;
    procedure WMNextColor(var Msg:TMessage);    virtual wm_First + wm_NextColor;
  end;

  PScore=^TScore;
  TScore=object(TStatic)
    Value:Long;
    constructor Init(aPatern:PWindowsObject; anID:LongInt; X,Y,W,H:LongInt);
    procedure SetValue(aValue:Long);
    procedure WMPaint(var Msg:TMessage);         virtual wm_First + wm_Paint;
  end;

  PChampion=^TChampion;
  TChampion=object(TObject)
    Day,Month:byte;
    Year:Word;
    sName:PString;
    Name:PChar;
    Score:Long;
    constructor Init(aName:PChar;aScore:Long);
    constructor Load(var S:TStream);
    procedure Store(var S:TStream);
    procedure Encode;
    procedure Decode;
    destructor Done; virtual;
  end;

  PChampionList=^TChampionList;
  TChampionList=object(TSortedCollection)
    constructor Init(ALimit,ADelta:integer);
    function KeyOf(Item:pointer):pointer; virtual;
    function Compare(Key1,Key2:pointer):LongInt; virtual;
  end;

  PChampionCore=^TChampionCore;
  TChampionCore=record
    MRC:MiniRecordCore;
    Date:CDate;
    Score:ULong;
  end;

  PTop10Frame=^TTop10Frame;
  TTop10Frame=object(TFrameWindow)
    constructor Init(aParent:PWindowsObject;aTitle:PChar);
    procedure InitClientWindow; virtual;
    procedure WMUpdateList(var Msg:TMessage); virtual wm_First+wm_UpdateList;
  end;

  PTop10Window=^TTop10Window;
  TTop10Window=object(TWindow)
    Container:PContainer;
    Core:PChampionCore;
    Info:PFieldInfo;
    constructor Init(aParent:PWindowsObject);
    procedure Focus;  virtual;
    procedure SetupWindow; virtual;
    procedure UpdateList;
    procedure WMChar(var Msg:TMessage);       virtual wm_First + wm_Char;
    procedure WMUpdateList(var Msg:TMessage); virtual wm_First + wm_UpdateList;
    destructor Done; virtual;
  end;

  PLinesCheckBox=^TLinesCheckBox;
  TLinesCheckBox=object(TCheckBox)
    constructor Init(aParent:PWindowsObject;anID:LongInt;
    aTitle:PChar;X,Y,W,H:LongInt;aGroup:PGroupBox);
    procedure WMButton1Up(var Msg:TMessage); virtual wm_First+wm_Button1Up;
  end;

  PLinesButton=^TLinesButton;
  TLinesButton=object(TButton)
    constructor Init(aParent:PWindowsObject;anID:LongInt;aTitle:PChar;X,Y,W,H:LongInt);
  end;

  PLinesSlider=^TLinesSlider;
  TLinesSlider=object(TSlider)
    constructor Init(aParent:PWindowsObject;anID,X,Y,W,H,Increments,Spacing:LongInt);
    procedure SetupWindow; virtual;
    function Transfer(DataPtr:pointer; TransferFlag:LongInt):LongInt; virtual;
  end;

  PGameAreaWindow=^TGameAreaWindow;
  TGameAreaWindow=object(TWindow)
    ActiveGame:boolean;                                    {game is active}
    Cells:Array[1..GameAreaSize,1..GameAreaSize] of PCell; {game cells}
    FreeCellCount:Long;                                    {free cells count}
    InfoCells:array[0..2] of  PInfoCell;                   {information cells}
    NextColors:array[0..BallAnStep-1] of byte;             {next step colors}
    Score:PScore;                                          {score}
    RemovedCells:PCollection;                              {collection of removed cells}
    SelectedCell:PCell;                                    {selected cell}
    PathButton,NextButton,SoundButton:PLinesCheckBox;      {check boxes}
    NewGameButton,Top10Button,AboutButton:PLinesButton;    {buttons}
    Slider:PLinesSlider;
    constructor Init(aParent:PWindowsObject;aTitle:PChar);
    procedure CloseWindow; virtual;
    procedure CMNextColor(var Msg:TMessage); virtual cm_First + cm_NextColor;
    procedure CMNewGame(var Msg:TMessage);   virtual cm_First + cm_NewGame;
    procedure CMPath(var Msg:TMessage);      virtual cm_First + cm_Path;
    procedure CMSound(var Msg:TMessage);     virtual cm_First + cm_Sound;
    procedure GameOver;
    procedure InitNewGame;
    procedure InitNextColors;
    procedure IDAbout(var Msg:TMessage);    virtual id_First + id_AboutButton;
    procedure IDNewGame(var Msg:TMessage);  virtual id_First + id_NewGameButton;
    procedure IDSlider(var Msg:TMessage);   virtual id_First + id_Slider;
    procedure IDTop10(var Msg:TMessage);    virtual id_First + id_Top10Button;
    procedure Jamp(Src,Trg:PCell);
    procedure LoadArrows;
    procedure Paint(PS : HPS;var Rect : RectL); virtual;
    procedure RemoveLines;
    procedure SetupWindow; virtual;
    procedure ViewTop10;
    procedure WMButton2Down(var Msg:TMessage);   virtual wm_First + wm_Button2Down;
    procedure WMButtonChecked(var Msg:TMessage); virtual wm_First + wm_ButtonChecked;
    procedure WMCellSelect(var Msg:TMessage);    virtual wm_First + wm_CellSelect;
    procedure WMChar(var Msg:TMessage);          virtual wm_First + wm_Char;
    procedure WMCloseTop10Win(var Msg:TMessage); virtual wm_First + wm_CloseTop10Win;
    procedure WMPopupMenu(var Msg:TMessage);     virtual wm_First + wm_PopupMenu;
    procedure WMTimer(var Msg : TMessage);       virtual wm_First + wm_Timer;
    procedure UnloadArrows;
    Destructor Done; virtual;
  private
    function  CheckOfLines(Cell:PCell):boolean;
    function  CheckPath(Src,Trg:PCell):boolean;
    procedure DrawBestResult(PS:HPS);
    procedure DrawGameBorder(PS:HPS);
    procedure GameStep;
    function  GetPrize(CountBalls:Long):Long;
    function  NextGameStep:PCell;
  end;

  TGameStateRec=record
    swPath,
    swNextColor,
    swSound,
    swSoundVol:SmallWord;
  end;

  {multimedia functions}
  {$cdecl+}
  TMciSendCommandFunc=Function(Id,M:UShort; P1:ULong; var P2; UP:UShort):ULong;
  TMMIOCloseFunc=Function(Mmio:Hmmio; usFlag:UShort):UShort;
  TMMIOGetHeaderFunc=Function(Mmio:Hmmio; pHeader:pointer; LHeaderLenght:Long;
                              plBytesRead:PLong; ulRes,ulFlag:ULong):ULong;
  TMMIOOpenFunc=Function(pszFileName:PChar; mmioInfo:pMMIOInfo; ulFlag:ULong):Hmmio;
  TMMIOReadFunc=Function(mmio:Hmmio; Buf:PChar; cBytes:Long):Long;
  {$cdecl-}

const
  Dop: DevOpenStruc = (pszLogAddress :nil;
                       pszDriverName :'DISPLAY';
                       pDriv :nil;
                       pszDataType :nil;
                       pszComment :nil;
                       pszQueueProcName :nil;
                       pszQueueProcParams  :nil;
                       pszSpoolerParams :nil;
                       pszNetworkParams :nil);
  PSSize: SizeL = (cx:0; cy:0);

  MMVolumeLevel:byte = 56;
  WaveCount    = 5;
  WaveName:array[0..WaveCount-1] of PChar = ('Lns1.Wav',
                                             'Lns2.Wav',
                                             'Lns3.Wav',
                                             'Lns4.Wav',
                                             'Lns5.Wav');

  wvPop        = 0;
  wvDelLine    = 1;
  wvNoPath     = 2;
  wvViewPath   = 3;
  wvFanfare    = 4;

type
  TWaveInfo=record
    Buf:pointer;
    BufSize:ULong;
    ulSamplesPerSec:ULong;
    usBitsPerSample:UShort;
  end;

  TWaveDevice=record
    ID:UShort;
    ulSamplesPerSec:ULong;
    usBitsPerSample:UShort;
  end;

  TPlayListData=record
    Command:ULong;
    Op1,Op2,OP3:ULong;
  end;

const
  PlayListCommandCount = 2;
  PlayList:array[0..PlayListCommandCount-1] of TPlayListData =
    ((Command:Data_Operation;
      Op1:0;
      Op2:0;
      Op3:0),
     (Command:Exit_Operation;
      Op1:0;
      Op2:0;
      Op3:0));

var
  BallsBmp: array[1..ResBmpCount] of HBitMap;
  BDC: array[1..ResBmpCount] of HDC;
  BPS: array[1..ResBmpCount] of HPS;

  ArrowsBmp: array[0..3,0..3] of HBitMap;
  ArrowsDC: array[0..3,0..3] of HDC;
  ArrowsPS: array[0..3,0..3] of HPS;

  GameStateRec:TGameStateRec;

  BlackMaskBmp: HBitMap;
  BlackMaskDC:  HDC;
  BlackMaskPS:  HPS;

  ViewNextColor:boolean;
  ViewPath:boolean;
  ActiveSound:boolean;
  MargeIniName:PString;

  TopList:PChampionList;
  LastGamerName:PChar;

  LastRecordNum:LongInt;
  Top10Win:PTop10Frame;

  mciSndCmd:TMciSendCommandFunc;
  mmClose:TMmioCloseFunc;
  mmGetHeader:TMmioGetHeaderFunc;
  mmOpen:TMmioOpenFunc;
  mmRead:TMmioReadFunc;
  MMPresent:boolean;
  MDM:HModule;
  MMIO:HModule;
  WavesData:array[0..WaveCount-1] of TWaveInfo;
  WaveDevice:TWaveDevice;
  WaveBeginSem,WaveEndSem,WaveExitSem,WaveVolSem:HEv;
  WaveUseSem:HMtx;
  WaveNumber:byte;
  PlayProcTID:TID;
  OverrideVolumeLevel:boolean;

  WinX,WinY:LongInt;

const
  RChampion : TStreamRec = (
    ObjType: ObjT_Champion;
    VmtLink: Ofs(Typeof(TChampion)^);
    Load : @TChampion.Load;
    Store : @TChampion.Store);

  RChampionList : TStreamRec = (
    ObjType: ObjT_Champion+1;
    VmtLink: Ofs(Typeof(TChampionList)^);
    Load : @TCollection.Load;
    Store : @TCollection.Store);

{-------------------------------------------------------------------------------}
{$IfDef UsesMM}
function PlayProcessor(P:pointer):LongInt;

  procedure ReadWaveIntoMem;
  var
    I:byte;
    H:HMMIO;
    AudioHeader:mmAudioHeader;
    BRead:Long;
  begin
    for I:=0 to WaveCount-1 do begin
      H:=mmOpen(WaveName[i],nil,mmio_Read);
      if H=NullHandle then WaveName[I]:=nil
      else begin
        if mmGetHeader(H,@AudioHeader,SizeOf(AudioHeader),@BRead,0,0)=mmio_Success then begin
          with WavesData[I] do begin
            Buf:=nil;
            BufSize:=AudioHeader.mmXWAVHeader.XWAVHeaderInfo.ulAudioLengthInBytes;
            ulSamplesPerSec:=AudioHeader.mmXWAVHeader.WAVEHeader.ulSamplesPerSec;
            usBitsPerSample:=AudioHeader.mmXWAVHeader.WAVEHeader.usBitsPerSample;
            GetMem(Buf,BufSize);
            if mmRead(H,Buf,BufSize)<>BufSize then begin
              FreeMem(Buf,BufSize); Buf:=nil;
              WaveName[I]:=nil;
            end;
          end;
        end
        else WaveName[I]:=nil;
      end;
      mmClose(H,0);
    end;
  end;

  procedure SetVolume(NewVolumeLevel:byte);
  var
    MSP:Mci_Set_Parms;
  begin
    with MSP do begin
      ulLevel:=NewVolumeLevel; ulAudio:=MCI_SET_AUDIO_ALL;
    end;
    mciSndCmd(WaveDevice.ID,MCI_SET,MCI_WAIT or MCI_SET_AUDIO or MCI_SET_VOLUME,
      MSP,0);
  end;

  procedure OpenWaveDevice;
  var
    MOP:Mci_Open_Parms;
  begin
    FillChar(Mop,SizeOf(Mop),0);
    with Mop do begin
      pszDeviceType:=PChar(mci_DevType_WaveForm_Audio);
      pszElementName:=@PlayList[0];
      pszAlias:=nil;
    end;
    if mciSndCmd(0,MCI_OPEN,
      MCI_WAIT or MCI_OPEN_PLAYLIST or MCI_Open_Type_ID or Mci_Open_Shareable,
      Mop,0)=mciErr_Success then begin
      WaveDevice.ID:=Mop.usDeviceID;
      SetVolume(MMVolumeLevel);
    end else WaveDevice.ID:=0;
  end;

  procedure PlayElement(wID:Byte);
  var
    MWSP:Mci_Wave_Set_Parms;
    MPP:Mci_Play_Parms;
    MGP:Mci_Generic_Parms;
    RetCode:ULong;
  begin
    if WaveDevice.ID=0 then Exit;
    if (WavesData[wID].Buf=nil)or(WaveName[wID]=nil) then Exit;
    if (WavesData[wID].ulSamplesPerSec<>WaveDevice.ulSamplesPerSec)or
       (WavesData[wID].usBitsPerSample<>WaveDevice.usBitsPerSample) then begin
      FillChar(MWSP,SizeOf(Mci_Wave_Set_Parms),0);
      with WaveDevice do begin
        ulSamplesPerSec:=WavesData[wID].ulSamplesPerSec;
        usBitsPerSample:=WavesData[wID].usBitsPerSample;
        MWSP.ulSamplesPerSec:=ulSamplesPerSec;
        MWSP.usBitsPerSample:=usBitsPerSample;
      end;
      MWSP.ulAudio:=MCI_Set_Audio_All;
      RetCode:=mciSndCmd(WaveDevice.ID,MCI_SET,
        MCI_WAIT or MCI_WAVE_SET_SamplesPerSec or MCI_WAVE_SET_BitsPerSample,
        MWSP,0);
    end;
    with PlayList[0] do begin
      Op1:=ULong(WavesData[wID].Buf); Op2:=WavesData[wID].BufSize;
    end;
    MGP.hwndCallback:=0;
    RetCode:=mciSndCmd(WaveDevice.ID,MCI_AcquireDevice,MCI_Wait or MCI_Acquire_Queue,MGP,0);
    if RetCode<>MCIErr_Success then Exit;
    FillChar(MPP,SizeOf(Mci_Play_Parms),0);
    RetCode:=mciSndCmd(WaveDevice.ID,MCI_Play,MCI_Wait or MCI_From,MPP,0);
  end;

  procedure CloseWaveDevice;
  var
    MGP:Mci_Generic_Parms;
  begin
    if (WaveDevice.ID<>0) then mciSndCmd(WaveDevice.ID,MCI_CLOSE,MCI_WAIT,MGP,0);
  end;

  procedure RemoveWaveFromMem;
  var
    I:byte;
  begin
    for I:=0 to WaveCount-1 do begin
      with WavesData[I] do begin
        if Buf<>nil then FreeMem(Buf,BufSize);
      end;
    end;
  end;

const
  MuxWaitCount = 3;
var
  MWSem:HMux;
  SR:array[0..MuxWaitCount-1] of SemRecord;
  i,wvID,NewVol:byte;
  RetCode,RetData,PostCount:ULong;
begin
  for I:=0 to MuxWaitCount-1 do begin
    case  I of
      0:SR[I].hSemCur:=HSem(WaveBeginSem);
      1:SR[I].hSemCur:=HSem(WaveExitSem);
      2:SR[I].hSemCur:=HSem(WaveVolSem);
    end;
    SR[I].ulUser:=I;
  end;
  RetCode:=DosCreateMuxWaitSem(nil,MWSem,MuxWaitCount,SR[0],dcmw_Wait_Any);
  if RetCode<>0 then DosExit(0,RetCode);
  ReadWaveIntoMem;
  OpenWaveDevice;
  repeat
    {$IfDef MMDebug}
    DosWaitMuxWaitSem(MWSem,512,RetData);
    {$Else}
    DosWaitMuxWaitSem(MWSem,sem_Indefinite_Wait,RetData);
    {$EndIf}
    case RetData of
      0:begin
          DosResetEventSem(WaveBeginSem,PostCount);
          DosRequestMutexSem(WaveUseSem,sem_Indefinite_Wait);
          wvID:=WaveNumber;
          DosReleaseMutexSem(WaveUseSem);
          PlayElement(wvID);
          DosPostEventSem(WaveEndSem);
        end;
      1:begin
          CloseWaveDevice;
          RemoveWaveFromMem;
          DosPostEventSem(WaveEndSem);
          DosCloseMuxWaitSem(MWSem);
          DosExit(0,0);
        end;
      2:begin
          DosResetEventSem(WaveVolSem,PostCount);
          DosRequestMutexSem(WaveUseSem,sem_Indefinite_Wait);
          NewVol:=MMVolumeLevel;
          DosReleaseMutexSem(WaveUseSem);
          SetVolume(NewVol);
        end;
    end;
  until false;
end;
{$EndIf}

procedure PlayWave(wvID:ULong);
var
  PC:ULong;
begin
  DosResetEventSem(WaveEndSem,PC);
  DosRequestMutexSem(WaveUseSem,Sem_Indefinite_Wait);
  WaveNumber:=wvID;
  DosReleaseMutexSem(WaveUseSem);
  DosPostEventSem(WaveBeginSem);
end;

{-------------------------------------------------------------------------------}
constructor TChampion.Init(aName:PChar;aScore:Long);
var
  L:word;
  DT:OS2Base.DateTime;
begin
  if aName<>nil then begin
    L:=StrLen(aName);
    GetMem(sName,L+2);
    FillChar(sName^[L],2,0);
    Move(aName^,sName^[1],L);
    sName^[0]:=Chr(Lo(L));
    Name:=Addr(sName^[1]);
  end else begin
    sName:=nil; Name:=nil;
  end;
  Score:=aScore;
  DosGetDateTime(DT);
  Day:=DT.Day; Month:=DT.Month; Year:=DT.Year;
end;

constructor TChampion.Load(var S:TStream);
var
  P:PString;
begin
  S.Read(Day,SizeOf(Day));
  S.Read(Month,SizeOf(Month));
  S.Read(Year,SizeOf(Year));
  P:=S.ReadStr;
  if P<>nil then begin
    GetMem(sName,Length(P^)+2);
    FillChar(sName^[Length(P^)],2,0);
    Move(P^,sName^,Length(P^)+1);
    Name:=Addr(sName^[1]);
    DisposeStr(P);
  end
  else begin
    sName:=nil; Name:=nil;
  end;
  S.Read(Score,SizeOf(Score));
  Decode;
end;

procedure TChampion.Store(var S:TStream);
var
  P:PString;
begin
  Encode;
  S.Write(Day,SizeOf(Day));
  S.Write(Month,SizeOf(Month));
  S.Write(Year,SizeOf(Year));
  S.WriteStr(sName);
  S.Write(Score,SizeOf(Score));
end;

procedure TChampion.Encode;
var
  i:byte;
begin
  Day:=Day xor EncodeByte;
  Month:=Month xor EncodeByte;
  Year:=Year xor EncodeByte;
  Score:=Score xor EncodeByte;
  if sName<>nil then for i:=1 to Length(sName^) do
  sName^[i]:=Chr(Byte(sName^[i]) xor EncodeByte);
end;

procedure TChampion.Decode;
begin
  Encode;
end;

destructor TChampion.Done;
begin
  Name:=nil;
  DisposeStr(sName);
  inherited Done;
end;

{-------------------------------------------------------------------------------}

constructor TChampionList.Init(ALimit,ADelta:integer);
begin
  inherited Init(ALimit,ADelta);
  Duplicates:=true;
end;

function TChampionList.KeyOf(Item:pointer):pointer;
begin
  KeyOf:=Addr(PChampion(Item)^.Score);
end;

function TChampionList.Compare(Key1,Key2:pointer):LongInt;
var
  L1,L2:Long;
begin
  L1:=PLong(Key1)^; L2:=PLong(Key2)^;
  if L1>L2 then Compare:=-1 else
  if L1<L2 then Compare:=1 else
  Compare:=0;
end;

{-------------------------------------------------------------------------------}

constructor TScore.Init(aPatern:PWindowsObject; anID:LongInt; X,Y,W,H:LongInt);
begin
  inherited Init(aPatern,anId,'',X,Y,W,H,6);
  Value:=0;
  DisableTransfer;
end;

procedure TScore.SetValue(aValue:Long);
var
  Sc:array[0..5] of Char;
  S:string;
begin
  Value:=aValue;
  FillChar(Sc[0],5,0);
  Sc[5]:=#0;
  Str(Value,S);
  Move(S[1],Sc[0],Length(S));
  SetText(@Sc);
end;

procedure TScore.WMPaint(var Msg:TMessage);
 var
  PS : HPS;
  Rect : RectL;
  P:PointL;
  Sc:array[0..5] of Char;
 begin
  PS:=WinBeginPaint(HWindow,0,@Rect);
  WinQueryWindowRect(HWindow,Rect);
  WinFillRect(PS,Rect,clr_Palegray);
  GpiSetColor(PS,clr_DarkGray);
  P.X:=Rect.xLeft; P.Y:=Rect.yBottom; GpiMove(PS,P);
  P.Y:=Rect.yTop-1; GpiLine(PS,P);
  P.X:=Rect.xRight-1; GpiLine(PS,P);
  GpiSetColor(PS,clr_White);
  Dec(P.Y); GpiMove(PS,P); P.Y:=Rect.yBottom; GpiLine(PS,P);
  P.X:=Rect.xLeft+1; GpiLine(PS,P);
  FillChar(Sc,6,0);
  GetText(@Sc,6);
  WinDrawText(PS,-1,@Sc,Rect,clr_Black,clr_PaleGray,dt_Center or dt_VCenter);
  WinEndPaint(PS);
end;

{-------------------------------------------------------------------------------}
constructor TLinesCheckBox.Init(aParent:PWindowsObject;anID:LongInt;
    aTitle:PChar;X,Y,W,H:LongInt;aGroup:PGroupBox);
begin
  inherited Init(aParent,anID,aTitle,X,Y,W,H,aGroup);
  Attr.Style:=Attr.Style or bs_NoPointerFocus;
  EnableTransfer;
end;

procedure TLinesCheckBox.WMButton1Up(var Msg:TMessage);
begin
  DefWndProc(Msg);
  WinSendMsg(Parent^.HWindow,wm_ButtonChecked,Long(Attr.ID),0);
end;
{-------------------------------------------------------------------------------}
constructor TLinesButton.Init(aParent:PWindowsObject;anID:LongInt;
    aTitle:PChar;X,Y,W,H:LongInt);
begin
  inherited Init(aParent,anID,aTitle,X,Y,W,H,false);
  Attr.Style:=Attr.Style or bs_NoPointerFocus;
end;

{-------------------------------------------------------------------------------}
constructor TLinesSlider.Init(aParent:PWindowsObject;anID,X,Y,W,H,Increments,Spacing:LongInt);
begin
  inherited Init(aParent,anID,X,Y,W,H,Increments,Spacing,false,true);
  Attr.Style:=Attr.Style or bs_NoPointerFocus or sls_Left or sls_ButtonsRight;
  EnableTransfer;
end;

procedure TLinesSlider.SetupWindow;
var
  BClr:Long;
begin
  BClr:=clr_PaleGray;
  WinSetPresParam(HWindow,pp_BackgroundColorIndex,SizeOf(Long),@BClr);
  inherited SetupWindow;
  if not MMPresent then Disable;
end;

function TLinesSlider.Transfer(DataPtr:pointer; TransferFlag:LongInt):LongInt;
var
  ArmPos:SmallWord;
begin
  if TransferFlag = tf_GetData then begin
    ArmPos:=GetSliderInfo(sma_SliderArmPosition,sma_IncrementValue);
    Move(ArmPos,DataPtr^,SizeOf(ArmPos));
  end else if TransferFlag = tf_SetData then
    SetSliderInfo(sma_SliderArmPosition,sma_IncrementValue,SmallWord(DataPtr^));
  Transfer := SizeOf(ArmPos);
end;


{-------------------------------------------------------------------------------}
constructor TCell.Init(aParent:PWindowsObject;anID:LongInt;X,Y,Sz:LongInt);
begin
  TWindow.Init(aParent,nil);
  Attr.X:=X; Attr.Y:=Y;
  with Attr do begin
    H:=Sz; W:=Sz; ID:=anID;
  end;
  Value:=0;
  BX:=0; BY:=0;
  BallMode:=None;
  InitBallPnt;
end;

procedure TCell.WMAppearance(var Msg : TMessage);
var
  PS:HPS;
  arPoints:array[0..2] of PointL;
begin
  Value:=Msg.Param1;
  arPoints[0].x:=BallPnt.X;
  arPoints[0].y:=BallPnt.Y;                         {Tx1,Ty1}
  arPoints[1].x:=BallPnt.X+BallSize;
  arPoints[1].y:=BallPnt.Y+BallSize;                {Tx2,Ty2}
  arPoints[2].x:=0; arPoints[2].y:=0;               {Sx1,Sy1}
  PS:=WinGetPS(HWindow);
  GpiBitBlt(PS,BPS[Value+BallColors],3,arPoints[0],rop_SrcCopy,bbo_Ignore);
  DosSleep(48);
  GpiBitBlt(PS,BPS[Value],3,arPoints[0],rop_SrcCopy,bbo_Ignore);
  WinReleasePS(PS);
end;


procedure TCell.WMDisAppearance(var Msg : TMessage);
var
  PS:HPS;
  arPoints:array[0..2] of PointL;
begin
  if Value>0 then begin
    arPoints[0].x:=BallPnt.X;
    arPoints[0].y:=BallPnt.Y;                         {Tx1,Ty1}
    arPoints[1].x:=BallPnt.X+BallSize;
    arPoints[1].y:=BallPnt.Y+BallSize;                {Tx2,Ty2}
    arPoints[2].x:=0; arPoints[2].y:=0;               {Sx1,Sy1}
    PS:=WinGetPS(HWindow);
    GpiBitBlt(PS,BPS[Value+BallColors],3,arPoints[0],rop_SrcCopy,bbo_Ignore);
    DosSleep(48);
    GpiSetColor(PS,clr_Cell_Back);
    GpiMove(PS,arPoints[0]);
    GpiBox(PS,dro_Fill,arPoints[1],0,0);
    WinReleasePS(PS);
    Value:=0;
  end;
end;

procedure TCell.WMDestroyBall(var Msg : TMessage);
const
  D=3;
var
  P:PointL;
  PS:HPS;
  arPoints:array[0..2] of PointL;
begin
  if Value>0 then begin
    PS:=WinGetPS(HWindow);

    if Msg.Param1=0 then begin
      arPoints[0].x:=BallPnt.X;
      arPoints[0].y:=BallPnt.Y;                         {Tx1,Ty1}
      arPoints[1].x:=BallPnt.X+BallSize;
      arPoints[1].y:=BallPnt.Y+BallSize;                {Tx2,Ty2}
      arPoints[2].x:=0; arPoints[2].y:=0;               {Sx1,Sy1}
      GpiBitBlt(PS,BPS[Value+BallColors*2],3,arPoints[0],rop_SrcCopy,bbo_Ignore);
    end
    else begin
      arPoints[0].x:=(CellSize-BallDstr2Size) div 2;
      arPoints[0].y:=arPoints[0].x;                     {Tx1,Ty1}
      arPoints[1].x:=arPoints[0].x+BallDstr2Size;
      arPoints[1].y:=arPoints[0].y+BallDstr2Size;       {Tx2,Ty2}
      arPoints[2].x:=0; arPoints[2].y:=0;               {Sx1,Sy1}
      GpiBitBlt(PS,BPS[Value+BallColors*3],3,arPoints[0],rop_SrcCopy,bbo_Ignore);
    end;

    WinReleasePS(PS);
  end;
end;

procedure TCell.WMDrawArrow(var Msg:TMessage);
var
  PS:HPS;
  arPoints:array[0..2] of PointL;
begin
  arPoints[0].x:=(CellSize-ArrowW) div 2;
  arPoints[0].y:=(CellSize-ArrowH) div 2;       {Tx1,Ty1}
  arPoints[1].x:=arPoints[0].X+ArrowW;
  arPoints[1].y:=arPoints[0].Y+ArrowH;          {Tx2,Ty2}
  arPoints[2].x:=0; arPoints[2].y:=0;           {Sx1,Sy1}
  PS:=WinGetPS(HWindow);
  GpiBitBlt(PS,ArrowsPS[Lo(Msg.Param2),Lo(Msg.Param1)],3,arPoints[0],rop_SrcCopy,bbo_Ignore);
  WinReleasePS(PS);
end;

procedure TCell.WMClearArrow(var Msg:TMessage);
var
  P:PointL;
  PS:HPS;
begin
  PS:=WinGetPS(HWindow);
  GpiSetColor(PS,clr_Cell_Back);
  P.X:=(CellSize-ArrowW) div 2; P.Y:=(CellSize-ArrowH) div 2;
  GpiMove(PS,P);
  Inc(P.X,ArrowW); Inc(P.Y,ArrowH);
  GpiBox(PS,dro_Fill,P,0,0);
  WinReleasePS(PS);
end;

procedure TCell.WMReInitCell(var Msg:TMessage);
var
  P:PointL;
  PS:HPS;
begin
  if Value>0 then begin
    Value:=0;
    PS:=WinGetPS(HWindow);
    GpiSetColor(PS,clr_Cell_Back);
    if Msg.Param1>0 then begin
      P.X:=(CellSize-BallDstr2Size) div 2; P.Y:=P.X;
      GpiMove(PS,P);
      Inc(P.X,BallDstr2Size); Inc(P.Y,BallDstr2Size);
    end
    else begin
      GpiMove(PS,BallPnt);
      P.X:=BallPnt.X+BallSize;
      P.Y:=BallPnt.Y+BallSize;
    end;
    GpiBox(PS,dro_Fill,P,0,0);
    WinReleasePS(PS);
    InitBallPnt;
    if BallMode<>None then begin
      WinStopTimer(HAnchor,HWindow,id_Timer);
      BallMode:=None;
    end;
  end;
end;

procedure TCell.InitBallPnt;
begin
  with BallPnt do begin
    X:=(Attr.W-BallSize) div 2; Y:=X;
  end;
end;

procedure TCell.MoveBall;
var
  PS:HPS;
  arPoints:array[0..2] of PointL;
  BottomstLine:boolean;
begin
  BottomstLine:=false;
  if BallMode=None then BallMode:=Up else
  if (BallMode=Up)and(BallPnt.Y+BallSize=Attr.H-1) then BallMode:=Down else
  if (BallMode=Down)and(BallPnt.Y=1) then begin
    BallMode:=Up; BottomstLine:=true;
  end;
  PS:=WinGetPS(HWindow);
  GpiSetColor(PS,clr_Cell_Back);
  if BallMode=Up then begin
    arPoints[0].X:=BallPnt.X; arPoints[0].Y:=BallPnt.Y; GpiMove(PS,arPoints[0]);
    Inc(arPoints[0].X,BallSize); GpiLine(PS,arPoints[0]);
    Inc(BallPnt.Y);
  end else begin
    arPoints[0].X:=BallPnt.X; arPoints[0].Y:=BallPnt.Y+BallSize-1; GpiMove(PS,arPoints[0]);
    Inc(arPoints[0].X,BallSize); GpiLine(PS,arPoints[0]);
    Dec(BallPnt.Y);
  end;
  arPoints[0].x:=BallPnt.X;
  arPoints[0].y:=BallPnt.Y;                         {Tx1,Ty1}
  arPoints[1].x:=BallPnt.X+BallSize;
  arPoints[1].y:=BallPnt.Y+BallSize;                {Tx2,Ty2}
  arPoints[2].x:=0; arPoints[2].y:=0;               {Sx1,Sy1}
  GpiBitBlt(PS,BPS[Value],3,arPoints[0],rop_SrcCopy,bbo_Ignore);
  WinReleasePS(PS);
  if BottomstLine then if ActiveSound then
    if MMPresent then PlayWave(wvPop) else DosBeep(40,20);
end;

procedure TCell.Paint(PS:HPS; var Rect:RectL);
var
  arPoints:array[0..2] of PointL;
begin
  WinFillRect(PS,Rect,clr_Cell_Back);
  WinQueryWindowRect(HWindow,Rect);
  GpiSetColor(PS,clr_White);
  arPoints[0].X:=Rect.xLeft; arPoints[0].Y:=Rect.yBottom+1; GpiMove(PS,arPoints[0]);
  arPoints[0].Y:=Rect.yTop-1; GpiLine(PS,arPoints[0]);
  arPoints[0].X:=Rect.xRight-2; GpiLine(PS,arPoints[0]);
  GpiSetColor(PS,clr_DarkGray);
  arPoints[0].X:=Rect.xRight-1; arPoints[0].Y:=Rect.yTop-2; GpiMove(PS,arPoints[0]);
  arPoints[0].Y:=Rect.yBottom; GpiLine(PS,arPoints[0]);
  arPoints[0].X:=Rect.xLeft+1; GpiLine(PS,arPoints[0]);
  if Value>0 then begin
    arPoints[0].x:=BallPnt.X;
    arPoints[0].y:=BallPnt.Y;                         {Tx1,Ty1}
    arPoints[1].x:=BallPnt.X+BallSize;
    arPoints[1].y:=BallPnt.Y+BallSize;                {Tx2,Ty2}
    arPoints[2].x:=0; arPoints[2].y:=0;               {Sx1,Sy1}
    GpiBitBlt(PS,BPS[Value],3,arPoints[0],rop_SrcCopy,bbo_Ignore);
  end;
end;

procedure TCell.WMButton1Down(var Msg:TMessage);
begin
  DefWndProc(Msg);
  WinSendMsg(Parent^.HWindow,wm_CellSelect,Long(@Self),0);
end;

procedure TCell.WMButton2Click(var Msg:TMessage);
begin
  DefWndProc(Msg);
  WinSendMsg(Parent^.HWindow,wm_PopupMenu,0,0);
end;

procedure TCell.WMUnselect(var Msg:TMessage);
var
  PS:HPS;
  Rect:RectL;
begin
  if (Value>0)and(BallMode<>None) then begin
    WinStopTimer(HAnchor,HWindow,id_Timer);
    InitBallPnt;
    PS:=WinGetPS(HWindow);
    WinQueryWindowRect(HWindow,Rect);
    Paint(PS,Rect);
    WinReleasePS(PS);
    BallMode:=None;
  end;
end;

procedure TCell.WMTimer(var Msg:TMessage);
begin
  if Value>0 then MoveBall
  else WinStopTimer(HAnchor,HWindow,id_Timer);
end;

destructor TCell.Done;
begin
  if BallMode<>None then WinStopTimer(HAnchor,HWindow,id_Timer);
  inherited Done;
end;

{-------------------------------------------------------------------------------}
procedure TInfoCell.Paint(PS:HPS; var Rect:RectL);
var
  arPoints:array[0..2] of PointL;
begin
  WinFillRect(PS,Rect,clr_Cell_Back);
  WinQueryWindowRect(HWindow,Rect);
  GpiSetColor(PS,clr_White);
  arPoints[0].X:=Rect.xLeft; arPoints[0].Y:=Rect.yBottom+1; GpiMove(PS,arPoints[0]);
  arPoints[0].Y:=Rect.yTop-1; GpiLine(PS,arPoints[0]);
  arPoints[0].X:=Rect.xRight-2; GpiLine(PS,arPoints[0]);
  GpiSetColor(PS,clr_DarkGray);
  arPoints[0].X:=Rect.xRight-1; arPoints[0].Y:=Rect.yTop-2; GpiMove(PS,arPoints[0]);
  arPoints[0].Y:=Rect.yBottom; GpiLine(PS,arPoints[0]);
  arPoints[0].X:=Rect.xLeft+1; GpiLine(PS,arPoints[0]);
  if Value>0 then begin
    arPoints[0].x:=BallPnt.X;
    arPoints[0].y:=BallPnt.Y;                         {Tx1,Ty1}
    arPoints[1].x:=BallPnt.X+BallSize;
    arPoints[1].y:=BallPnt.Y+BallSize;                {Tx2,Ty2}
    arPoints[2].x:=0; arPoints[2].y:=0;               {Sx1,Sy1}
    GpiBitBlt(PS,BPS[Value+BallColors],3,arPoints[0],rop_SrcCopy,bbo_Ignore);
  end;
end;

procedure TInfoCell.WMButton1Down(var Msg:TMessage);
begin
  DefWndProc(Msg);
end;

procedure TInfoCell.WMButton2Click(var Msg:TMessage);
begin
  DefWndProc(Msg);
end;

procedure TInfoCell.WMNextColor(var Msg:TMessage);
var
  PS:HPS;
  arPoints:array[0..2] of PointL;
begin
  Value:=Lo(Msg.Param1);
  arPoints[0].x:=BallPnt.X;
  arPoints[0].y:=BallPnt.Y;                         {Tx1,Ty1}
  arPoints[1].x:=BallPnt.X+BallSize;
  arPoints[1].y:=BallPnt.Y+BallSize;                {Tx2,Ty2}
  arPoints[2].x:=0; arPoints[2].y:=0;               {Sx1,Sy1}
  PS:=WinGetPS(HWindow);
  GpiBitBlt(PS,BPS[Value+BallColors],3,arPoints[0],rop_SrcCopy,bbo_Ignore);
  WinReleasePS(PS);
end;

{-------------------------------------------------------------------------------}
constructor TGameAreaWindow.Init(aParent:PWindowsObject;aTitle:PChar);
const
  InfoCellsYPos=6;
var
  I,J:LongInt;
  P:PointL;
  CX,CY,CX1:Long;
begin
  inherited Init(aParent,aTitle);
  for J:=1 to GameAreaSize do begin
    for I:=1 to GameAreaSize do begin
      Cells[I,J]:=New(PCell,Init(@Self,id_Cell_0+J*10+I,
      gawDX1+GameAreaBorderX+CellSize*(I-1),gawDY1+GameAreaBorderY+CellSize*(J-1),CellSize));
      Cells[I,J]^.BX:=I; Cells[I,J]^.BY:=J;
    end;
  end;

  FillChar(GameStateRec,SizeOf(GameStateRec),0);
  with GameStateRec do begin
    if ViewPath then swPath:=bf_Checked;
    if ViewNextColor then swNextColor:=bf_Checked;
    if ActiveSound then swSound:=bf_Checked;
    if MMPresent then swSoundVol:=MMVolumeLevel div 2;
  end;
  TransferBuffer:=@GameStateRec;

  CX:=gawDX1+GameAreaBorderX*2+CellSize*GameAreaSize;
  CY:=gawDY1+GameAreaBorderY;

  P.X:=CX+(gawDX2-InfoCellSize*3) div 2;
  P.Y:=CY+CellSize*InfoCellsYPos+(CellSize-InfoCellSize)div 2;
  for I:=0 to 2 do begin
    InfoCells[I]:=New(PInfoCell,Init(@Self,id_InfoCell_0+I,
    P.X+InfoCellSize*I,P.Y,InfoCellSize));
  end;

  P.Y:=CY+CellSize*(InfoCellsYPos-1)+(CellSize-ScoreWinSizeH)div 2;
  Score:=New(PScore,Init(@Self,id_Score,
  CX+(gawDX2-ScoreWinSizeW) div 2,P.Y,ScoreWinSizeW,ScoreWinSizeH));

  CX1:=CX+(gawDX2-CBButtonW)div 2;

  Dec(P.Y,CBButtonH+6);
  PathButton:=New(PLinesCheckBox,Init(@Self,id_PathButton,'Path',
  CX1,P.Y,CBButtonW,CBButtonH,nil));

  Dec(P.Y,CBButtonH);
  NextButton:=New(PLinesCheckBox,Init(@Self,id_NextButton,'Next Colors',
  CX1,P.Y,CBButtonW,CBButtonH,nil));

  Dec(P.Y,CBButtonH);
  SoundButton:=New(PLinesCheckBox,Init(@Self,id_SoundButton,'Sound',
  CX1,P.Y,CBButtonW,CBButtonH,nil));

  CX1:=CX+(gawDX2-ButtonW)div 2;

  Dec(P.Y,SliderH+3);
  Slider:=New(PLinesSlider,Init(@Self,id_Slider,CX1,P.Y,SliderW,SliderH,50,0));

  P.Y:=CY-1;
  AboutButton:=New(PLinesButton,Init(@Self,id_AboutButton,'About',
  CX1,P.Y,ButtonW,ButtonH));

  Inc(P.Y,ButtonH+2);
  Top10Button:=New(PLinesButton,Init(@Self,id_Top10Button,'Scores',
  CX1,P.Y,ButtonW,ButtonH));

  Inc(P.Y,ButtonH+2);
  NewGameButton:=New(PLinesButton,Init(@Self,id_NewGameButton,'Start',
  CX1,P.Y,ButtonW,ButtonH));

  for i:=1 to ResBmpCount do begin
    BDC[i]:=DevOpenDC(HAnchor,od_Memory,'*',5,@Dop,0);
    BPS[i]:=GpiCreatePS(HAnchor,BDC[i],PSSize,gpit_Micro or gpia_Assoc or pu_Pels);
    BallsBmp[i]:=GpiLoadBitmap(BPS[i],NullHandle,200+i,0,0);
    GpiSetBitMap(BPS[i],BallsBmp[i]);
  end;

  LoadArrows;

  RemovedCells:=New(PCollection,Init(16,4));
  SelectedCell:=nil;
  FreeCellCount:=GameAreaSize*GameAreaSize;
  ActiveGame:=false;
end;

procedure TGameAreaWindow.CloseWindow;
begin
  if Top10Win<>nil then WinSendMsg(Top10Win^.HWindow,wm_Close,0,0);
  inherited CloseWindow;
end;

procedure TGameAreaWindow.CMNextColor(var Msg:TMessage);
begin
  NextButton^.Toggle; Msg.Param1:=id_NextButton; WMButtonChecked(Msg);
end;

procedure TGameAreaWindow.CMNewGame(var Msg:TMessage);
begin
  IDNewGame(Msg);
end;

procedure TGameAreaWindow.CMPath(var Msg:TMessage);
begin
  PathButton^.Toggle; Msg.Param1:=id_PathButton; WMButtonChecked(Msg);
end;

procedure TGameAreaWindow.CMSound(var Msg:TMessage);
begin
  SoundButton^.Toggle; Msg.Param1:=id_SoundButton; WMButtonChecked(Msg);
end;

procedure TGameAreaWindow.DrawBestResult(PS:HPS);
var
  arPT:array[0..TxtBox_Count] of PointL;
  C:PChampion;
  S:string[10];
  CX,CY,TextHeight,MaxTextY,TY,MY:Long;
  R:RectL;
begin
  CX:=gawDX1+GameAreaBorderX*2+CellSize*GameAreaSize;
  CY:=gawDY1+GameAreaBorderY+CellSize*GameAreaSize;
  R.xLeft:=CX+1; R.yTop:=CY; R.xRight:=Attr.W-1;
  R.yBottom:=InfoCells[0]^.Attr.Y+InfoCells[0]^.Attr.H+1;
  WinFillRect(PS,R,clr_PaleGray);

  if TopList^.Count>0 then begin
    C:=PChampion(TopList^.At(0));
    MY:=R.yBottom+(R.yTop-R.yBottom) div 2;

    if C^.Name<>nil then begin
      GpiQueryTextBox(PS,Length(C^.sName^),C^.Name,TxtBox_Count,arPT[0]);
      TextHeight:=arPT[TxtBox_TopRight].Y-arPT[TxtBox_BottomLeft].Y;
      R.yBottom:=MY; R.yTop:=R.yBottom+TextHeight;
      if R.yTop>CY then R.yTop:=CY;
      WinDrawText(PS,-1,C^.Name,R,clr_Red,clr_PaleGray,dt_Center or dt_Bottom);
    end;

    FillChar(S[0],10,0);
    Str(C^.Score,S);
    GpiQueryTextBox(PS,Length(S),@S[1],TxtBox_Count,arPT[0]);
    TextHeight:=arPT[TxtBox_TopRight].Y-arPT[TxtBox_BottomLeft].Y;
    R.yTop:=MY; R.yBottom:=R.yTop-TextHeight;
    WinDrawText(PS,-1,@S[1],R,clr_Red,clr_PaleGray,dt_Center or dt_Top);
  end;
end;

procedure TGameAreaWindow.DrawGameBorder(PS:HPS);
var
  P:PointL;
begin
  GpiSetColor(PS,Clr_DarkGray);
  P.X:=gawDX1+GameAreaBorderX div 2; P.Y:=gawDY1+GameAreaBorderY div 2; GpiMove(PS,P);
  P.Y:=P.Y+CellSize*GameAreaSize+GameAreaBorderY; GpiLine(PS,P);
  P.X:=P.X+CellSize*GameAreaSize+GameAreaBorderX; GpiLine(PS,P);
  GpiSetColor(PS,clr_White);
  Dec(P.Y); GpiMove(PS,P);
  P.Y:=gawDY1+GameAreaBorderY div 2; GpiLine(PS,P);
  P.X:=gawDX1+GameAreaBorderX div 2+1; GpiLine(PS,P);
end;


function TGameAreaWindow.CheckOfLines(Cell:PCell):boolean;
var
  I,J:Long;
  N,V:byte;
  EqColor:boolean;
begin
  V:=Cell^.Value;
  {horizintal}
  N:=0; I:=Cell^.BX; J:=Cell^.BY;
  repeat
    if I>1 then begin
      Dec(I);
      EqColor:=Cells[I,J]^.Value=V;
      if EqColor then begin
        RemovedCells^.Insert(Cells[I,J]);
        Inc(N);
      end;
    end;
  until (I=1)or(not EqColor);
  I:=Cell^.BX;
  repeat
    if I<GameAreaSize then begin
      Inc(I);
      EqColor:=Cells[I,J]^.Value=V;
      if EqColor then begin
        RemovedCells^.Insert(Cells[I,J]);
        Inc(N);
      end;
    end;
  until (I=GameAreaSize)or(not EqColor);
  if N<LineLength-1 then RemovedCells^.DeleteAll;
  {vertical}
  N:=0; I:=Cell^.BX; J:=Cell^.BY;
  repeat
    if J>1 then begin
      Dec(J);
      EqColor:=Cells[I,J]^.Value=V;
      if EqColor then begin
        RemovedCells^.Insert(Cells[I,J]);
        Inc(N);
      end;
    end;
  until (J=1)or(not EqColor);
  J:=Cell^.BY;
  repeat
    if J<GameAreaSize then begin
      Inc(J);
      EqColor:=Cells[I,J]^.Value=V;
      if EqColor then begin
        RemovedCells^.Insert(Cells[I,J]);
        Inc(N);
      end;
    end;
  until (J=GameAreaSize)or(not EqColor);
  if N>0 then begin
    if N<LineLength-1 then begin
      if RemovedCells^.Count=N then RemovedCells^.DeleteAll
      else begin
        repeat
          RemovedCells^.AtDelete(RemovedCells^.Count-1);
          Dec(N);
        until N=0;
      end;
    end;
  end;
  {diagonal left down - right up}
  N:=0; I:=Cell^.BX; J:=Cell^.BY;
  repeat
    if (I>1)and(J>1) then begin
      Dec(I); Dec(J);
      EqColor:=Cells[I,J]^.Value=V;
      if EqColor then begin
        RemovedCells^.Insert(Cells[I,J]);
        Inc(N);
      end;
    end;
  until (I=1)or(J=1)or(not EqColor);
  I:=Cell^.BX; J:=Cell^.BY;
  repeat
    if (I<GameAreaSize)and(J<GameAreaSize) then begin
      Inc(I); Inc(J);
      EqColor:=Cells[I,J]^.Value=V;
      if EqColor then begin
        RemovedCells^.Insert(Cells[I,J]);
        Inc(N);
      end;
    end;
  until (I=GameAreaSize)or(J=GameAreaSize)or(not EqColor);
  if N>0 then begin
    if N<LineLength-1 then begin
      if RemovedCells^.Count=N then RemovedCells^.DeleteAll
      else begin
        repeat
          RemovedCells^.AtDelete(RemovedCells^.Count-1);
          Dec(N);
        until N=0;
      end;
    end;
  end;
  {diagonal right down - left up}
  N:=0; I:=Cell^.BX; J:=Cell^.BY;
  repeat
    if (I<GameAreasize)and(J>1) then begin
      Inc(I); Dec(J);
      EqColor:=Cells[I,J]^.Value=V;
      if EqColor then begin
        RemovedCells^.Insert(Cells[I,J]);
        Inc(N);
      end;
    end;
  until (I=GameAreaSize)or(J=1)or(not EqColor);
  I:=Cell^.BX; J:=Cell^.BY;
  repeat
    if (I>1)and(J<GameAreaSize) then begin
      Dec(I); Inc(J);
      EqColor:=Cells[I,J]^.Value=V;
      if EqColor then begin
        RemovedCells^.Insert(Cells[I,J]);
        Inc(N);
      end;
    end;
  until (I=1)or(J=GameAreaSize)or(not EqColor);
  if N>0 then begin
    if N<LineLength-1 then begin
      if RemovedCells^.Count=N then RemovedCells^.DeleteAll
      else begin
        repeat
          RemovedCells^.AtDelete(RemovedCells^.Count-1);
          Dec(N);
        until N=0;
      end;
    end;
  end;
  if RemovedCells^.Count>0 then begin
    RemovedCells^.Insert(Cell);
    CheckOfLines:=true;
  end else CheckOfLines:=false;
end;

function  TGameAreaWindow.CheckPath(Src,Trg:PCell):boolean;
var
  Tx,Ty:Long;
  Found:boolean;
  G:array[1..GameAreaSize,1..GameAreaSize] of byte;

  procedure InitGlass;
  var
    I,J:Long;
  begin
    for J:=1 to GameAreaSize do begin
      for I:=1 to GameAreaSize do begin
        if Cells[I,J]^.Value>0 then G[I,J]:=1
        else G[I,J]:=0;
      end;
    end;
  end;

  procedure Search(x,y:integer);
  var
    i,x1,y1:byte;
  begin
   i:=0;
   repeat
     if Not Found then begin
       inc(i); x1:=x; y1:=y;
       case i of
         1: Inc(y);
         2: Inc(x);
         3: Dec(y);
         4: Dec(x);
       end;
       if (x=0)or(x>GameAreaSize)or(Y=0)or(Y>GameAreaSize) then begin
         x:=x1; y:=y1;
         continue;
       end;
       if G[x,y]=0 then begin
         G[x,y]:=2;
         if (x=Tx)and(y=Ty) then Found:=true
         else search(x,y);
         case I of
           2: if ((x=1)and((y=1)or(y=GameAreaSize)))or
                 ((x=GameAreaSize)and((y=1)or(y=GameAreaSize))) then G[x,y]:=3
                 else G[x,y]:=0;
           3: if (x=1)or(x=GameAreaSize)or(y=1)or(Y=GameAreaSize) then G[x,y]:=3
                 else G[x,y]:=0;
           4: G[x,y]:=3;
           else G[x,y]:=0;
         end;
       end;
       x:=x1; y:=y1;
     end;
   until (i=4) or Found;
  end;

begin
  Found:=false; Tx:=Trg^.BX; Ty:=Trg^.By;
  InitGlass;
  Search(Src^.BX,Src^.BY);
  CheckPath:=Found;
end;

function  TGameAreaWindow.GetPrize(CountBalls:Long):Long;
var
  C,I:Long;
begin
  C:=5;
  if CountBalls>5 then for I:=6 to CountBalls do Inc(C,1+(I-5));
  GetPrize:=C;
end;

procedure TGameAreaWindow.InitNewGame;
var
  I,J:Long;
  P:PCell;
begin
  SelectedCell:=nil;
  FreeCellCount:=GameAreaSize*GameAreaSize;
  for J:=1 to GameAreaSize do begin
    for I:=1 to GameAreaSize do WinSendMsg(Cells[I,J]^.HWindow,wm_ReInitCell,0,0);
  end;
  Score^.SetValue(0);
  ActiveGame:=true;
  RemovedCells^.DeleteAll;
  for I:=1 to BallAnStep+2 do begin
    P:=NextGameStep;
    if P<>nil then begin
      WinSendMsg(P^.HWindow,wm_Appearance,Random(BallColors)+1,0);
      Dec(FreeCellCount);
    end;
  end;
  InitNextColors;
end;

procedure TGameAreaWindow.InitNextColors;
var
  I,N:byte;
begin
  if not ActiveGame then Exit;
  FillChar(NextColors[0],BallAnStep,0);
  if FreeCellCount>BallAnStep then N:=BallAnStep else N:=FreeCellCount;
  for I:=0 to N-1 do NextColors[I]:=Random(BallColors)+1;
  if ViewNextColor and (BallAnStep<4) then begin
    for I:=0 to N-1 do
    WinSendMsg(InfoCells[I]^.HWindow,wm_NextColor,NextColors[I],0);
    if N<BallAnStep then begin
      for I:=N to BallAnStep-1 do
      WinSendMsg(InfoCells[I]^.HWindow,wm_ReinitCell,0,0);
    end;
  end;
end;

procedure TGameAreaWindow.Jamp(Src,Trg:PCell);
var
  V:byte;
  Tx,Ty,Sx,Sy,CrX,CrY,N:Long;
  Found,FirstFound,WaitSound:boolean;
  G,SG:array[1..GameAreaSize,1..GameAreaSize] of byte;
  min,AbsMin:Long;
  C,CPred,CNext:PCell;
  A1,A2:byte;

  procedure InitGlass;
  var
    I,J:Long;
  begin
    for J:=1 to GameAreaSize do begin
      for I:=1 to GameAreaSize do begin
        if Cells[I,J]^.Value>0 then G[I,J]:=1
        else G[I,J]:=0;
      end;
    end;
  end;

  procedure SearchMinPath(k:LongInt; x,y:integer);
  var
    i,x1,y1,fc:byte;
    dx,dy:integer;
  begin
   i:=0;
   repeat
     inc(i);
     if not Found then begin
       x1:=x; y1:=y; dx:=Tx-x; dy:=Ty-Y;
       if Abs(dy)>=Abs(dx) then begin
         case I of
           1: if dy>=0 then Inc(y) else Dec(y);
           2: if dx>=0 then Inc(x) else Dec(x);
           3: if dx>=0 then Dec(x) else Inc(x);
           4: if dy>=0 then Dec(y) else Inc(y);
         end;
       end
       else begin
         case I of
           1: if dx>0 then Inc(x) else Dec(x);
           2: if dy>0 then Inc(y) else Dec(y);
           3: if dy>0 then Dec(y) else Inc(y);
           4: if dx>0 then Dec(x) else Inc(x);
         end;
       end;
       if not ((x=0)or(x>GameAreaSize)or(Y=0)or(Y>GameAreaSize)) then begin
         if G[x,y]=0 then begin
           if k+(Abs(Tx-x)+Abs(Ty-y))<min then begin
             G[x,y]:=2;
             if (x=Tx)and(Y=Ty) then begin
               if k<min then begin
                 FirstFound:=true;
                 min:=k; SG:=G;
                 if min=absmin then Found:=true;
               end;
               G[x,y]:=0;
             end else SearchMinPath(k+1,x,y);
             if not FirstFound then begin
               case I of
                 2: if ((x=1)and((y=1)or(y=GameAreaSize)))or
                       ((x=GameAreaSize)and((y=1)or(y=GameAreaSize))) then G[x,y]:=3
                       else G[x,y]:=0;
                 3: if (x=1)or(x=GameAreaSize)or(y=1)or(Y=GameAreaSize) then G[x,y]:=3
                       else G[x,y]:=0;
                 4: G[x,y]:=3;
                 else G[x,y]:=0;
               end;
             end
             else if G[x,y]<>0 then begin
               fc:=3;
               if x>1 then begin
                 if G[x-1,y] in [1,3] then Dec(fc);
               end else Dec(fc);
               if x<GameAreaSize then begin
                 if G[x+1,y] in [1,3] then Dec(fc);
               end else Dec(fc);
               if y>1 then begin
                 if G[x,y-1] in [1,3] then Dec(fc);
               end else Dec(fc);
               if y<GameAreasize then begin
                 if G[x,y+1] in [1,3] then Dec(fc);
               end else Dec(fc);
               if fc>0 then G[x,y]:=0 else G[x,y]:=3;
             end;
           end;
         end;
       end;
       x:=x1; y:=y1;
     end;
   until (i=4) or Found;
  end;

begin
  V:=Src^.Value;
  if not ViewPath then begin
    WinSendMsg(Src^.HWindow,wm_CellUnselect,0,0);
    WinSendMsg(Src^.HWindow,wm_DisAppearance,0,0);
    WinSendMsg(Trg^.HWindow,wm_Appearance,V,0);
    if ActiveSound then
      if MMPresent then PlayWave(wvPop) else DosBeep(40,20);
    DosSleep(1);
  end
  else begin
    Found:=false; Tx:=Trg^.BX; Ty:=Trg^.By; FirstFound:=false;
    Sx:=Src^.Bx; Sy:=Src^.By;
    InitGlass;  G[SX,Sy]:=2;
    min:=GameAreaSize*GameAreaSize;
    AbsMin:=Abs(Tx-Sx)+Abs(Ty-Sy);
    SearchMinPath(1,SX,SY);
    WinSendMsg(Src^.HWindow,wm_CellUnselect,0,0);
    RemovedCells^.DeleteAll;
    CrX:=SX; CRY:=SY;
    repeat
      RemovedCells^.Insert(Cells[CrX,CrY]);
      SG[CrX,CrY]:=0;
      if CrX>1 then begin
        if SG[CrX-1,CrY]=2 then begin
          Dec(CrX); Continue;
        end;
      end;
      if CrX<GameAreaSize then begin
        if SG[CrX+1,CrY]=2 then begin
          Inc(CrX); Continue;
        end;
      end;
      if CrY<GameAreaSize then begin
        if SG[CrX,CrY+1]=2 then begin
          Inc(CrY); Continue;
        end;
      end;
      if CrY>1 then begin
        if SG[CrX,CrY-1]=2 then begin
          Dec(CrY); Continue;
        end;
      end;
    until (CrX=Tx)and(CrY=Ty);
    RemovedCells^.Insert(Cells[CrX,CrY]);
    WaitSound:=false;
    if RemovedCells^.Count>2 then begin
      if ActiveSound then if MMPresent then begin
        PlayWave(wvViewPath);
        WaitSound:=true;
      end;
      for N:=1 to RemovedCells^.Count-2 do begin
        CPred:=PCell(RemovedCells^.At(N-1));
        C:=PCell(RemovedCells^.At(N));
        CNext:=PCell(RemovedCells^.At(N+1));
        if CPred^.Bx=C^.Bx then begin
          if CPred^.By<C^.By then A1:=3
          else A1:=2;
        end
        else begin
          if CPred^.Bx<C^.Bx then A1:=0
          else  A1:=1;
        end;
        if CNext^.Bx=C^.Bx then begin
          if CNext^.By<C^.By then A2:=3
          else A2:=2;
        end
        else begin
          if CNext^.Bx<C^.Bx then A2:=0
          else  A2:=1;
        end;
        WinSendMsg(C^.HWindow,wm_DrawArrow,Long(A1),Long(A2));
        DosSleep(1);
      end;
    end;
    if MMPresent then begin
      if (ActiveSound)and(WaitSound) then DosWaitEventSem(WaveEndSem,512);
    end else DosSleep(16);
    WinSendMsg(Src^.HWindow,wm_DisAppearance,0,0);
    WinSendMsg(Trg^.HWindow,wm_Appearance,V,0);
    if ActiveSound then if MMPresent then PlayWave(wvPop) else DosBeep(40,20);
    DosSleep(72);
    if RemovedCells^.Count>2 then begin
      for N:=1 to RemovedCells^.Count-2 do begin
        C:=PCell(RemovedCells^.At(N));
        WinSendMsg(C^.HWindow,wm_ClearArrow,0,0);
      end;
    end;
    RemovedCells^.DeleteAll;
  end;
end;

function TGameAreaWindow.NextGameStep:PCell;
var
  N,I,J:Long;
  FreeCells:array[0..(GameAreaSize*GameAreaSize)-1] of pointer;
begin
  N:=0;
  for J:=1 to GameAreaSize do begin
    for I:=1 to GameAreaSize do begin
      if Cells[I,J]^.Value=0 then begin
        FreeCells[N]:=Cells[I,J];
        Inc(N);
      end;
    end;
  end;
  case N of
    0: NextGameStep:=nil;
    1: NextGameStep:=FreeCells[0];
    else NextGameStep:=FreeCells[Random(N)];
  end;
end;

procedure TGameAreaWindow.GameStep;
var
  I,N:byte;
  P:PCell;
begin
  if FreeCellCount>BallAnStep then N:=BallAnStep else N:=FreeCellCount;
  if N>0 then begin
    for I:=1 to N do begin
      P:=NextGameStep;
      if P<>nil then begin
        WinSendMsg(P^.HWindow,wm_Appearance,NextColors[I-1],0);
        Dec(FreeCellCount);
        if CheckOfLines(P) then RemoveLines;
      end;
    end;
    if FreeCellCount>0 then InitNextColors else GameOver;
  end else GameOver;
end;

procedure TGameAreaWindow.GameOver;
const
  Anonymous:PChar='Anonymous';
var
  i:byte;
  InTopList:boolean;
  Buf:PChar;
  S:string;
  V1,V2:Long;
  C:PChampion;
  PS:HPS;
begin
  ActiveGame:=false;
  if ViewNextColor then begin
    for I:=0 to BallAnStep-1 do
    WinSendMsg(InfoCells[I]^.HWindow,wm_ReinitCell,0,0);
  end;
  V1:=Score^.Value;
  InTopList:=(TopList^.Count<10)and(V1>0);
  if not InTopList then begin
    V2:=PChampion(TopList^.At(TopList^.Count-1))^.Score;
    if V1>V2 then InTopList:=true;
  end;
  if not InTopList then begin
    Str(V1,S);
    S:=S+#0;
    WinAlarm(HWnd_Desktop,wa_Note);
    WinMessageBox(HWnd_Desktop,HWindow,'Game over.','Information',0,
    mb_Ok or mb_Information or mb_Moveable);
  end
  else begin
    if ActiveSound then if MMPresent then PlayWave(wvFanfare);
    GetMem(Buf,RecordBufSize);
    FillChar(Buf^,RecordBufSize,0);
    if LastGamerName<>nil then StrCopy(Buf,LastGamerName);
    V2:=Application^.ExecDialog(New(PInputDialog,
    Init(@Self,'New High Score','Your Name:',Buf,RecordBufSize)));
    if V2=mbID_Ok then begin
      if StrLen(Buf)>0 then C:=New(PChampion,Init(Buf,V1))
      else C:=New(PChampion,Init(Anonymous,V1));
      TopList^.Insert(C);
      if LastGamerName<>nil then StrDispose(LastGamerName);
      LastGamerName:=StrNew(Buf);
      if TopList^.Count>10 then
        TopList^.Free(PChampion(TopList^.At(TopList^.Count-1)));
      LastRecordNum:=TopList^.IndexOf(C);
      if LastRecordNum=0 then begin
        PS:=WinGetPS(HWindow);
        DrawBestResult(PS);
        WinReleasePS(PS);
      end;
    end;
    FreeMem(Buf,RecordBufSize);
    if Top10Win<>nil then WinPostMsg(Top10Win^.HWindow,wm_UpdateList,0,0);
    ViewTop10;
  end;
  InitNewGame;
end;

procedure TGameAreaWindow.IDSlider(var Msg:TMessage);
var
  NewVol:byte;
begin
  if not ActiveGame then Exit;
  if (Msg.Param1Hi=sln_Change) or (Msg.Param1Hi=sln_SliderTrack) then begin
    NewVol:=Byte(Msg.Param2)*2; if NewVol>100 then NewVol:=100;
    DosRequestMutexSem(WaveUseSem,Sem_Indefinite_Wait);
    MMVolumeLevel:=NewVol;
    DosReleaseMutexSem(WaveUseSem);
    DosPostEventSem(WaveVolSem);
  end;
end;

procedure TGameAreaWindow.IDNewGame(var Msg:TMessage);
begin
  if WinMessageBox(HWnd_Desktop,HWindow,'Start new game?','Confirmation',
  0,mb_OkCancel or mb_IconQuestion or mb_Moveable)=mbID_Ok then InitNewGame;
end;

procedure TGameAreaWindow.IDTop10(var Msg:TMessage);
begin
  ViewTop10;
end;

procedure TGameAreaWindow.IDAbout(var Msg:TMessage);
begin
  Application^.ExecDialog(New(PDialog,Init(@Self,id_AboutDlg)));
end;

procedure TGameAreaWindow.LoadArrows;
var
  I,J:byte;
begin
  for J:=0 to 3 do begin
    for I:=0  to 3 do begin
      if I<>J then begin
        ArrowsDC[I,J]:=DevOpenDC(HAnchor,od_Memory,'*',5,@Dop,0);
        ArrowsPS[I,J]:=GpiCreatePS(HAnchor,ArrowsDC[I,J],PSSize,
        gpit_Micro or gpia_Assoc or pu_Pels);
        ArrowsBmp[I,J]:=GpiLoadBitmap(ArrowsPS[i,j],NullHandle,
        id_Arrow+(4*j)+i,0,0);
        GpiSetBitMap(ArrowsPS[i,j],ArrowsBmp[i,j]);
      end
      else begin
        ArrowsDC[I,J]:=NullHandle;
        ArrowsPS[I,J]:=NullHandle;
        ArrowsBmp[I,J]:=NullHandle;
      end;
    end;
  end;
end;

procedure TGameAreaWindow.UnloadArrows;
var
  I,J:byte;
begin
  for J:=0 to 3 do begin
    for I:=0 to 3 do begin
      if I<>J then begin
        GpiDestroyPS(ArrowsPS[i,j]);
        DevCloseDC(ArrowsDC[i,j]);     {dev_Ok}
        GpiDeleteBitMap(ArrowsBmp[i,j]);
      end;
    end;
  end;
end;

procedure TGameAreaWindow.Paint(PS : HPS;var Rect : RectL);
begin
  WinFillRect(PS,Rect,clr_Palegray);
  DrawGameBorder(PS);
  DrawBestResult(PS);
end;


procedure TGameAreaWindow.RemoveLines;

  procedure SendMsg1(Item:PCell);
  begin
    WinSendMsg(Item^.HWindow,wm_DestroyBall,0,0);
  end;

  procedure SendMsg2(Item:PCell);
  begin
    WinSendMsg(Item^.HWindow,wm_DestroyBall,1,0);
  end;

  procedure SendMsg3(Item:PCell);
  begin
    WinSendMsg(Item^.HWindow,wm_ReInitCell,1,0);
  end;

var
  I:byte;
  V:Long;
  InitNextColor:boolean;
begin
  RemovedCells^.ForEach(@SendMsg1);
  if ActiveSound then begin
    if MMPresent then PlayWave(wvDelLine);
  end
  else DosSleep(32);
  RemovedCells^.ForEach(@SendMsg2);
  DosSleep(32);
  RemovedCells^.ForEach(@SendMsg3);
  if MMPresent then begin
    if ActiveSound then DosWaitEventSem(WaveEndSem,1024) else DosSleep(64);
  end else DosSleep(64);
  if ActiveSound then if not MMPresent then DosBeep(40,20);
  InitNextColor:=BallAnStep>FreeCellCount;
  Inc(FreeCellCount,RemovedCells^.Count);
  V:=Score^.Value;
  Inc(V,GetPrize(RemovedCells^.Count));
  if FreeCellCount=GameAreaSize*GameAreaSize then Inc(V,50);
  RemovedCells^.DeleteAll;
  Score^.SetValue(V);
  for i:=0 to BallAnStep-1 do begin
    if NextColors[i]=0 then begin
      NextColors[I]:=Random(BallColors)+1;
      if ViewNextColor and (BallAnStep<4) then
      WinSendMsg(InfoCells[I]^.HWindow,wm_NextColor,NextColors[I],0);
    end;
  end;
end;

procedure TGameAreaWindow.SetupWindow;
var
  BClr:Long;
begin
  BClr:=clr_PaleGray;
  WinSetPresParam(HWindow,pp_BackgroundColorIndex,SizeOf(Long),@BClr);
  inherited SetupWindow;
end;

procedure TGameAreaWindow.ViewTop10;
begin
  if Top10Win=nil then begin
    Top10Win:=New(PTop10Frame,Init(nil,'High Scores'));
    Application^.MakeWindow(Top10Win);
  end;
  if Top10Win<>nil then Top10Win^.Focus;
end;

procedure TGameAreaWindow.WMButton2Down(var Msg:TMessage);
begin
  DefWndProc(Msg);
end;

procedure TGameAreaWindow.WMButtonChecked(var Msg:TMessage);
var
  i:byte;
begin
  case Msg.Param1 of
    id_PathButton: ViewPath:=PathButton^.GetCheck>0;
    id_NextButton:
      begin
        ViewNextColor:=NextButton^.GetCheck>0;
        if not ViewNextColor then for I:=0 to BallAnStep-1 do
        WinSendMsg(InfoCells[I]^.HWindow,wm_ReinitCell,0,0)
        else for I:=0 to High(NextColors) do if NextColors[I]>0 then
        WinSendMsg(InfoCells[I]^.HWindow,wm_NextColor,NextColors[I],0);
      end;
    id_SoundButton: ActiveSound:=SoundButton^.GetCheck>0;
  end;
end;

procedure TGameAreaWindow.WMCellSelect(var Msg:TMessage);
var
  Cell:PCell;
begin
  if not ActiveGame then Exit;
  Cell:=PCell(Msg.Param1);
  if SelectedCell<>nil then begin
    if Cell=SelectedCell then begin
      WinSendMsg(SelectedCell^.HWindow,wm_CellUnselect,0,0);
      SelectedCell:=nil;
      Exit;
    end;
    if Cell^.Value=0 then begin
      if CheckPath(SelectedCell,Cell) then begin
        if MMPresent then if ActiveSound then DosWaitEventSem(WaveEndSem,256);
        Jamp(SelectedCell,Cell);
        SelectedCell:=nil;
        if CheckOfLines(Cell) then RemoveLines else GameStep;
        Exit;
      end
      else begin
        if ActiveSound then
          if MMPresent then PlayWave(wvNoPath) else DosBeep(440,50);
        Exit;
      end;
    end;
    WinSendMsg(SelectedCell^.HWindow,wm_CellUnselect,0,0);
  end;
  if Cell^.Value>0 then begin
    SelectedCell:=Cell;
    WinStartTimer(HAnchor,Cell^.HWindow,id_Timer,30);
  end;
end;

procedure TGameAreaWindow.WMCloseTop10Win(var Msg:TMessage);
begin
  if not IsMinimized(HWindow) then Focus;
end;

procedure TGameAreaWindow.WMChar(var Msg:TMessage);
begin
end;

procedure TGameAreaWindow.WMPopupMenu(var Msg:TMessage);
var
  Point : PointL;
  Menu : HWnd;
begin
  WinQueryPointerPos(HWnd_Desktop,Point);
  WinMapWindowPoints(HWnd_Desktop,HWindow,Point,1);
  Menu:=WinLoadMenu(HWindow,Application^.Module,id_PopupMenu);
  WinCheckMenuItem(Menu,cm_Path,ViewPath);
  WinCheckMenuItem(Menu,cm_NextColor,ViewNextColor);
  WinCheckMenuItem(Menu,cm_Sound,ActiveSound);
  WinPopupMenu(HWindow,HWindow,Menu,Point.x,Point.y,cm_NewGame,pu_Keyboard or pu_MouseButton1);
end;

procedure TGameAreaWindow.WMTimer(var Msg:TMessage);
begin
  if Msg.Param1=id_Timer_NewGame then begin
    WinStopTimer(HAnchor,HWindow,id_Timer_NewGame);
    InitNewGame;
  end;
end;

destructor TGameAreaWindow.Done;
var
  I:byte;
begin
  UnloadArrows;
  for I:=1 to ResBmpCount do begin
    GpiDestroyPS(BPS[i]);
    DevCloseDC(BDC[i]);     {dev_Ok}
    GpiDeleteBitMap(BallsBmp[i]);
  end;
  RemovedCells^.DeleteAll;
  Dispose(RemovedCells,Done);
  inherited Done;
end;

{-------------------------------------------------------------------------------}
constructor TBaseFrameWindow.Init(aParent:PWindowsObject;aTitle:PChar);
begin
  inherited Init(aParent,aTitle);
  flCreate:=(flCreate and not (fcf_ShellPosition or fcf_SizeBorder or fcf_Maxbutton))
             or fcf_Border or fcf_Icon;
  with Attr do begin
    H:=gawDY1+GameAreaBorderY*2+CellSize*GameAreaSize+gawDY2
     +WinQuerySysValue(hwnd_Desktop,sv_CyTitleBar)
     +WinQuerySysValue(hwnd_Desktop,sv_CyBorder)*2;
    W:=gawDX1+GameAreaBorderX*2+CellSize*GameAreaSize+gawDX2
     +WinQuerySysValue(hwnd_Desktop,sv_CxBorder)*2;
    if WinX<>-1 then X:=WinX
    else X:=(WinQuerySysValue(hwnd_Desktop,sv_CxScreen)-W) div 2;
    if WinY<>-1 then Y:=WinY
    else Y:=(WinQuerySysValue(hwnd_Desktop,sv_CyScreen)-H) div 2;
    ID:=id_MainWindow;
  end;
end;

procedure TBaseFrameWindow.InitClientWindow;
begin
  ClientWnd:=New(PGameAreaWindow,Init(@Self,nil));
end;

procedure TBaseFrameWindow.CloseWindow;
begin
  WinX:=Attr.X;
  WinY:=Attr.Y;
  inherited CloseWindow;
end;

{-------------------------------------------------------------------------------}
constructor TTop10Frame.Init(aParent:PWindowsObject;aTitle:PChar);
begin
  inherited Init(aParent,aTitle);
  flCreate:=(flCreate and not
            (fcf_ShellPosition or fcf_SizeBorder or fcf_Maxbutton or fcf_MinButton))
            or fcf_DlgBorder or fcf_Icon or fcf_NoMoveWithOwner;
  with Attr do begin
    W:=330; H:=270;
    X:=(WinQuerySysValue(hwnd_Desktop,sv_CxScreen)-W) div 2;
    Y:=(WinQuerySysValue(hwnd_Desktop,sv_CyScreen)-H) div 2;
    ID:=id_MainWindow;
  end;
end;

procedure TTop10Frame.InitClientWindow;
begin
  ClientWnd:=New(PTop10Window,Init(@Self));
end;

procedure TTop10Frame.WMUpdateList(var Msg:TMessage);
begin
  WinPostMsg(ClientWnd^.HWindow,wm_UpdateList,0,0);
end;

constructor TTop10Window.Init(aParent:PWindowsObject);
begin
  inherited Init(aParent,nil);
  Container:=New(PContainer,Init(@Self,id_Top10Container,nil,Top10Dx,Top10Dy,
  310,250));
  Container^.Attr.Style:=Container^.Attr.Style or ccs_ReadOnly or ccs_SingleSel
  or ccs_MiniRecordCore;
end;

procedure TTop10Window.Focus;
begin
  Container^.Focus;
end;

procedure TTop10Window.SetupWindow;
const
  pzTitleDate:PChar='Date';
  pzTitleName:PChar='Name';
  pzTiTleScore:PChar='Score';
var
  i:byte;
  CurInfo:PFieldInfo;
  FII:FieldInfoInsert;
begin
  inherited SetupWindow;
  Core:=PChampionCore(Container^.AllocRecord(SizeOf(TChampionCore)-SizeOf(MiniRecordCore),10));
  Info:=Container^.AllocDetailFieldInfo(Top10ColNum);
  CurInfo:=Info;
  for i:=1 to Top10ColNum do begin
    with CurInfo^ do begin
      cb:=SizeOf(FieldInfo);
      case I of
        1:begin
            flData:=cfa_Date or cfa_Separator or cfa_Left;
            pTitleData:=pzTitleDate;
            offStruct:=Ofs(PChampionCore(nil)^.Date);
          end;
        2:begin
            flData:=cfa_String or cfa_Separator or cfa_Left;
            pTitleData:=pzTitleName;
            offStruct:=Ofs(PChampionCore(nil)^.MRC.pszIcon);
          end;
        3:begin
            flData:=cfa_Ulong or cfa_Right;
            pTitleData:=pzTitleScore;
            offStruct:=Ofs(PChampionCore(nil)^.Score);
          end;
      end;
      flData:=flData or cfa_HorzSeparator or cfa_VCenter or cfa_FIReadOnly;
      flTitle:=flTitle or cfa_FITitleReadOnly or cfa_VCenter or cfa_Center;
    end;
    CurInfo:=CurInfo^.pNextFieldInfo;
  end;
  with FII do begin
    cb:=SizeOf(FieldInfoInsert);
    pFieldInfoOrder:=PFieldInfo(cma_First);
    fInvalidateFieldInfo:=ULong(true);
    cFieldInfoInsert:=Top10ColNum;
  end;
  Container^.InsertDetailFieldInfo(Info,@FII);
  Container^.SetDetailView(true);
  Updatelist;
end;

procedure TTop10Window.UpdateList;
var
  i:byte;
  CurCore:PChampionCore;
  SelCore:PChampionCore;
  RI:RecordInsert;
  C:PChampion;
  CI:CnrInfo;
begin
  with Container^ do begin
    GetCnrInfo(@CI,SizeOf(CnrInfo));
    if CI.cRecords>0 then RemoveRecord(PChampionCore(Core),0,0);
  end;
  if TopList^.Count=0 then Exit;
  CurCore:=Core;
  for i:=0 to TopList^.Count-1 do begin
    C:=PChampion(TopList^.At(i));
    with CurCore^ do begin
      MRC.cb:=SizeOf(MiniRecordCore);
      MRC.flRecordAttr:=cra_RecordReadOnly;
      MRC.pszIcon:=C^.Name;
      Date.Day:=C^.Day;
      Date.Month:=C^.Month;
      Date.Year:=C^.Year;
      Score:=C^.Score;
    end;
    if I=LastRecordNum then SelCore:=CurCore;
    CurCore:=PChampionCore(CurCore^.MRC.preccNextRecord);
  end;
  with RI do begin
    cb:=SizeOf(RecordInsert);
    pRecordOrder:=PRecordCore(cma_End);
    pRecordParent:=nil;
    fInvalidateRecord:=ULong(true);
    zOrder:=cma_Top;
    cRecordsInsert:=TopList^.Count;
  end;
  Container^.InsertRecord(PRecordCore(Core),@RI);
  Container^.SetCursored(PRecordCore(SelCore),true);
end;

procedure TTop10Window.WMChar(var Msg:TMessage);
begin
end;

procedure TTop10Window.WMUpdateList(var Msg:TMessage);
begin
  UpdateList;
end;

destructor TTop10Window.Done;
begin
  Container^.RemoveDetailFieldInfo(Info,0,cma_Free);
  Container^.RemoveRecord(PChampionCore(Core),0,cma_Free);
  WinPostMsg(PFrameWindow(Application^.MainWindow)^.ClientWnd^.HWindow,wm_CloseTop10Win,0,0);
  inherited Done;
  Top10Win:=nil;
end;

{-------------------------------------------------------------------------------}

constructor TLines.Init;
const
  scNoSB   = 'NOAD';
  scSBVol  = 'ADVOL:';
  scResult = 'RES:';
  h100 = 100;
var
  S:string;
  I,J,V:byte;
  NoSB:boolean;
  Code:LongInt;
begin
  RegisterType(RCollection);
  RegisterType(RChampion);
  RegisterType(RChampionList);
  LastGamerName:=nil;
  Top10Win:=nil;
  LastRecordNum:=0;
  NoSB:=false;
  OverrideVolumeLevel:=false;
  MargeIniName:=nil;
  if ParamCount>0 then begin
    for I:=1 to ParamCount do begin
      S:=ParamStr(I);
      if Length(S)>4 then begin
        if S[1] in ['/','-'] then begin
          for J:=2 to Length(S) do S[j]:=UpCase(S[j]);
          if Pos(scNoSB,S)=2 then NoSB:=true else
          if (Pos(scSBVol,S)=2)and(Length(S)>7) then begin
            S:=Copy(S,8,Length(S)-7);
            Val(S,V,Code);
            if Code=0 then begin
              if V>h100 then V:=V mod h100;
              MMVolumeLevel:=V;
              OverrideVolumeLevel:=true;
            end;
          end else
          if (Pos(scResult,S)=2)and(Length(S)>5) then
            MargeIniName:=NewStr(Copy(S,6,Length(S)-5));
        end;
      end;
    end;
  end;
  LoadIni;
  MMPresent:=false;
  {$IfDef UsesMM}
  MDM:=NullHandle;
  if not NoSB then CheckMultiMedia;
  {$EndIf}
  inherited Init('Lines2');
  WinStartTimer(HAnchor,PGameAreaWindow(PBaseFrameWindow(MainWindow)^.ClientWnd)^.HWindow,
  id_Timer_NewGame,256);
end;

procedure TLines.InitMainWindow;
begin
  MainWindow:=New(PBaseFrameWindow,Init(nil,'Lines/2'));
end;

procedure TLines.CheckMultiMedia;
const
  RetBufSize=8;

  mciModuleName:PChar='MDM';
  mciSCFuncName:PChar='mciSendCommand';

  mmioModuleName:PChar='MMIO';
  mmioCloseFName:PChar='mmioClose';
  mmioGetHeaderFName:PChar   ='mmioGetHeader';
  mmioGetLastErrorFName:PChar='mmioGetLastError';
  mmioOpenFName:PChar='mmioOpen';
  mmioReadFName:PChar='mmioRead';

  procedure ErrorQueryAddr;
  begin
    if MDM<>NullHandle then DosFreeModule(MDM);
    if MMIO<>NullHandle then DosFreeModule(MMIO);
    MDM:=NullHandle; MMIO:=NullHandle;
  end;

var
  LError:array[0..255] of Char;
{$IfDef UsesMM}
  SI:mci_SysInfo_Parms;
  SIRet:array[0..RetBufSize] of Char;
{$EndIf}
  RetCode:ULong;
begin
{$IfDef UsesMM}
  MDM:=NullHandle; MMIO:=NullHandle;

  if DosLoadModule(@LError,SizeOf(LError),mciModuleName,MDM)<>0 then Exit;
  if DosLoadModule(@LError,SizeOf(LError),mmioModuleName,MMIO)<>0 then begin
    DosFreeModule(MDM);
    Exit;
  end;

  if DosQueryProcAddr(MDM,0,mciSCFuncName,@mciSndCmd)<>0 then begin
    ErrorQueryAddr; Exit;
  end;

  if DosQueryProcAddr(MMIO,0,mmioCloseFName,@mmClose)<>0 then begin
    ErrorQueryAddr; Exit;
  end;

  if DosQueryProcAddr(MMIO,0,mmioGetHeaderFName,@mmGetHeader)<>0 then begin
    ErrorQueryAddr; Exit;
  end;

  if DosQueryProcAddr(MMIO,0,mmioOpenFName,@mmOpen)<>0 then begin
    ErrorQueryAddr; Exit;
  end;

  if DosQueryProcAddr(MMIO,0,mmioReadFName,@mmRead)<>0 then begin
    ErrorQueryAddr; Exit;
  end;

  FillChar(SI,SizeOf(mci_SysInfo_Parms),0);
  FillChar(SIRet,RetBufSize+1,0);
  with SI do begin
    usDeviceType:=MCI_DEVTYPE_WAVEFORM_AUDIO;
    pszReturn:=@SIRet;
    ulRetSize:=RetBufSize;
  end;
  RetCode:=mciSndCmd(0,MCI_SYSINFO,MCI_SYSINFO_QUANTITY or MCI_WAIT,SI,0);
  if RetCode=mciErr_Success then begin
    if SIRet[0]>'0' then begin
      MMPresent:=true;
      RetCode:=DosCreateEventSem(nil,WaveBeginSem,0,false);
      RetCode:=DosCreateEventSem(nil,WaveEndSem,0,false);
      RetCode:=DosCreateEventSem(nil,WaveExitSem,0,false);
      RetCode:=DosCreateEventSem(nil,WaveVolSem,0,false);
      RetCode:=DosCreateMutexSem(nil,WaveUseSem,0,false);
      {$IfDef MMDebug}
      PlayProcessor(nil);
      {$Else}
      RetCode:=BeginThread(nil,16384,PlayProcessor,nil,Stack_Committed,PlayProcTID);
      if RetCode=0 then RetCode:=DosSetPriority(prtys_Thread,prtyc_TimeCritical,-16,PlayProcTID);
      {$EndIf}
    end;
  end;
{$EndIf}
end;

procedure TLines.LoadIni;
var
  IniFile:PBufStream;
  i:byte;
  Rulez:boolean;
  S:string;
  B:boolean;
  MargeTopList:PChampionList;
  C,CM:PChampion;
  Bt:Byte;
begin
  ViewNextColor:=true;
  ViewPath:=true;
  ActiveSound:=true;
  WinX:=-1; WinY:=-1;
  IniFile:=New(PBufStream,Init(IniName,stOpenRead,2048));
  if IniFile^.Status=stOk then begin
    TopList:=PChampionList(IniFile^.Get);
      if IniFile^.Status<>stOk then TopList:=New(PChampionList,Init(10,2));
    i:=0;
    while (i<3)and(IniFile^.Status=stOk) do begin
      IniFile^.Read(B,SizeOf(Boolean));
      Inc(i);
      case I of
        1: ViewPath:=B;
        2: ViewNextColor:=B;
        3: ActiveSound:=B;
      end;
    end;
    if IniFile^.Status=stOk then IniFile^.Read(Bt,SizeOf(Byte));
    if (IniFile^.Status=stOk)and(not OverrideVolumeLevel) then MMVolumeLevel:=Bt;
    IniFile^.Read(WinX,SizeOf(LongInt));
      if IniFile^.Status<>stOk then WinX:=-1;
    IniFile^.Read(WinY,SizeOf(LongInt));
      if IniFile^.Status<>stOk then WinY:=-1;
  end
  else begin
    TopList:=New(PChampionList,Init(10,2));
  end;
  Dispose(IniFile,Done);
  if MargeIniName<>nil then begin
    IniFile:=New(PBufStream,Init(MargeIniName^,stOpenRead,2048));
    if IniFile^.Status=stOk then MargeTopList:=PChampionList(IniFile^.Get)
    else MargeTopList:=nil;
    Dispose(IniFile,Done);
    if MargeTopList<>nil then begin
      if TopList^.Count=0 then begin
        Dispose(TopList,Done); TopList:=MargeTopList; MargeTopList:=nil;
      end
      else if MargeTopList^.Count>0 then begin
        repeat
          C:=TopList^.At(TopList^.Count-1);
          CM:=MargeTopList^.At(0);
          if CM^.Score>C^.Score then begin
            MargeTopList^.Delete(CM);
            TopList^.Insert(CM);
            if TopList^.Count>10 then begin
              TopList^.Free(C);
              C:=TopList^.At(TopList^.Count-1);
              if MargeTopList^.Count>0 then CM:=MargeTopList^.At(0)
              else CM:=C;
            end;
          end;
        until (C^.Score>=CM^.Score)or(MargeTopList^.Count=0);
        Dispose(MargeTopList,Done);
      end;
    end;
    DisposeStr(MargeIniName);
  end;
end;

procedure TLines.StoreIni;
var
  IniFile:PBufStream;
begin
  IniFile:=New(PBufStream,Init(IniName,stCreate,2048));
  if IniFile^.Status=stOk then begin
    IniFile^.Put(PCollection(TopList));
    IniFile^.Write(ViewPath,SizeOf(ViewPath));
    IniFile^.Write(ViewNextColor,SizeOf(ViewNextColor));
    IniFile^.Write(ActiveSound,SizeOf(ActiveSound));
    IniFile^.Write(MMVolumeLevel,SizeOf(byte));
    IniFile^.Write(WinX,SizeOf(LongInt));
    IniFile^.Write(WinY,SizeOf(LongInt));
  end;
  Dispose(IniFile,Done);
end;

destructor TLines.Done;
var
  i:byte;
  PC:ULong;
begin
  {$IfDef UsesMM}
  if MMPresent then begin
    DosResetEventSem(WaveEndSem,PC);
    DosPostEventSem(WaveExitSem);
    DosWaitEventSem(WaveEndSem,8888);
    DosCloseEventSem(WaveBeginSem);
    DosCloseEventSem(WaveEndSem);
    DosCloseEventSem(WaveVolSem);
    DosCloseEventSem(WaveExitSem);
    DosCloseMutexSem(WaveUseSem);
  end;
  if MDM<>NUllHandle then DosFreeModule(MDM);
  if MMIO<>NUllHandle then DosFreeModule(MMIO);
  {$EndIf}
  StoreIni;
  if LastGamerName<>nil then StrDispose(LastGamerName);
  Dispose(TopList,Done);
  inherited Done;
end;

var
  Lines:TLines;
begin
  Randomize;
  Lines.Init;
  Lines.Run;
  Lines.Done;
end.
