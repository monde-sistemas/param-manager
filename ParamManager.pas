unit ParamManager;

interface

uses
  SysUtils,
  DBClient,
  Classes,
  DB,
  Windows,
  ParamManagerCipher,
  System.IniFiles;

type
  TParamSystemScope = (ssGlobal, ssCompany, ssUser, ssUserCompany);
  TParamPersistenceScope = (psLocal, psRemote, psSession);
  TParamEncryption = (peEncryptionOff, peEncryptionOn);

  TParamItem = class;
  TCustomRemoteParams = class;
  TRemoteParamsClass = class of TCustomRemoteParams;

  TParamManager = class
  private
    FAppDataCompanyFolder: string;
    FCipher: TParamManagerCipherClass;
    FCompanyID: Variant;
    FParams: THashedStringList;
    FUserID: Variant;
    FRemoteParams: TCustomRemoteParams;
    function CreateRemoteParamItem: TParamItem;
    function ExeNameWithoutExt: string;
    function GetParam(const ParamName: string): TParamItem;
    function GetParamValue(const ParamName: string): Variant;
    function InstanciarItemParametro(PersistenceScope: TParamPersistenceScope): TParamItem;
    procedure SetParamValue(const ParamName: string; const Value: Variant);
  public
    class var RemoteParamsClass: TRemoteParamsClass;
    constructor Create;
    destructor Destroy; override;
    function AppDataFolder: string;
    procedure RegisterParam(const ParamName: string; DefaultValue: Variant;
      SystemScope: TParamSystemScope; PersistenceScope: TParamPersistenceScope; Encryption:
      TParamEncryption = peEncryptionOff);
    function ParamByName(const ParamName: string): TParamItem;
    function HasParam(const ParamName: string): Boolean;
    procedure Refresh;
    property AppDataCompanyFolder: string read FAppDataCompanyFolder write FAppDataCompanyFolder;
    property ParamValue[const ParamName: string]: Variant read GetParamValue write SetParamValue; default;
    property Cipher: TParamManagerCipherClass read FCipher write FCipher;
    property CompanyID: Variant read FCompanyID write FCompanyID;
    property UserID: Variant read FUserID write FUserID;
  end;

  TParamItem = class
  private
    FDefaultValue: Variant;
    FEncryption: TParamEncryption;
    FParamManager: TParamManager;
    FParamName: string;
    FSystemScope: TParamSystemScope;
    function GetAsInteger: Integer;
    function GetBlobAsString: string;
    function GetValue: Variant;
    procedure SetAsInteger(const Value: Integer);
    procedure SetValue(const Value: Variant);
    function IsDefault(Value: Variant): Boolean;
    procedure SetBlobAsString(const Value: string);
  protected
    FValue: Variant;
    function DecodeString(const Value: string): string;
    function EncodeString(const Value: string): string;
    function CustomGetBlobAsString(CompanyID: Variant): string; virtual;
    function CustomGetValue(const ParamName: string; CompanyID: Variant): Variant; virtual;
    procedure CustomSetValue(const ParamName: string; Value: Variant); virtual;
    procedure CustomSetBlobAsString(CompanyID: Variant; const Value: string); virtual;
  public
    constructor Create(ParamManager: TParamManager); virtual;
    property Encryption: TParamEncryption read FEncryption write FEncryption;
    property ParamManager: TParamManager read FParamManager write FParamManager;
    property ParamName: string read FParamName write FParamName;
    property SystemScope: TParamSystemScope read FSystemScope write FSystemScope;
    property Value: Variant read GetValue write SetValue;
    function ValueByCompany(CompanyID: Variant): Variant;
    function BlobAsStringByCompany(CompanyID: Variant): string;
    procedure SetValueByCompany(CompanyID: Variant; Value: Variant);
    procedure SetBlobAsStringByCompany(CompanyID, Value: Variant);
    property DefaultValue: Variant read FDefaultValue write FDefaultValue;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property BlobAsString: string read GetBlobAsString write SetBlobAsString;
    procedure SaveToStream(Stream: TStream); virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure SetBlobNull; virtual;
  end;

  TCustomRemoteParams = class
  private
    FParamManager: TParamManager;
  public
    constructor Create(ParamManager: TParamManager); virtual;
    procedure Refresh; virtual;
    procedure Open; virtual;
    function CreateParamItem: TParamItem; virtual; abstract;
    property ParamManager: TParamManager read FParamManager;
  end;

  EParamNotFound = class(Exception);
  EParamAlreadyRegistered = class(Exception);
  EUserCompanyNotSet = class(Exception);

function GetParamManager: TParamManager;
procedure FreeAndNilParamManager;

implementation

uses
  DataSetParamItem,
  TypInfo,
  Variants,
  LocalParamItem;

var
  Instance: TParamManager;

function GetParamManager: TParamManager;
begin
  if Instance = nil then
    Instance := TParamManager.Create;
  Result := Instance;
end;

procedure FreeAndNilParamManager;
begin
  FreeAndNil(Instance);
end;

constructor TParamManager.Create;
begin
  inherited;
  FParams := THashedStringList.Create(True);
  Cipher := TDefaultCipher;
end;

destructor TParamManager.Destroy;
begin
  FRemoteParams.Free;
  FParams.Free;
  inherited;
end;

function TParamManager.CreateRemoteParamItem: TParamItem;
begin
  if FRemoteParams = nil then
  begin
    Assert(RemoteParamsClass <> nil, 'Remote params class not set');
    FRemoteParams := RemoteParamsClass.Create(Self);
  end;

  Result := FRemoteParams.CreateParamItem;
end;

function TParamManager.ExeNameWithoutExt: string;
begin
  Result := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
end;

function TParamManager.AppDataFolder: string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA'));
  if AppDataCompanyFolder <> '' then
    Result := Result + IncludeTrailingPathDelimiter(AppDataCompanyFolder);
  Result := Result + IncludeTrailingPathDelimiter(ExeNameWithoutExt);

  ForceDirectories(Result);
end;

function TParamManager.GetParam(const ParamName: string): TParamItem;
var
  ParamIndex: Integer;
begin
  ParamIndex := FParams.IndexOf(ParamName);

  if ParamIndex > -1 then
    Result := FParams.Objects[ParamIndex] as TParamItem
  else
    Result:= nil;
end;

function TParamManager.GetParamValue(const ParamName: string): Variant;
begin
  Result := ParamByName(ParamName).Value;
end;

function TParamManager.HasParam(const ParamName: string): Boolean;
begin
  Result := GetParam(ParamName) <> nil;
end;

function TParamManager.InstanciarItemParametro(PersistenceScope: TParamPersistenceScope): TParamItem;
const
  EscopoNaoSuportado = 'Escopo de parâmetro não suportado.';
begin
  case PersistenceScope of
    psRemote: Result := CreateRemoteParamItem;
    psSession: Result := TParamItem.Create(Self);
    psLocal: Result := TLocalParamItem.Create(Self);
  else
    raise Exception.Create(EscopoNaoSuportado);
  end;
end;

function TParamManager.ParamByName(const ParamName: string): TParamItem;
begin
  Result:= GetParam(ParamName);
  if Result = nil then
    raise EParamNotFound.CreateFmt('Parameter ''%s'' not found.', [ParamName]);
end;

procedure TParamManager.Refresh;
begin
  FRemoteParams.Refresh;
end;

procedure TParamManager.RegisterParam(const ParamName: string; DefaultValue:
  Variant; SystemScope: TParamSystemScope; PersistenceScope:
  TParamPersistenceScope; Encryption: TParamEncryption = peEncryptionOff);
var
  P: TParamItem;
begin
  if Length(ParamName) > 30 then
    raise Exception.CreateFmt('Nome de parâmetro não pode ser maior que 30 caracteres: %s', [ParamName]);

  if FParams.IndexOf(ParamName) <> -1 then
    raise EParamAlreadyRegistered.CreateFmt('Parameter ''%s'' already registered.', [ParamName]);

  P := InstanciarItemParametro(PersistenceScope);

  P.ParamManager := Self;
  P.ParamName := ParamName;
  P.DefaultValue := DefaultValue;
  P.SystemScope := SystemScope;
  P.Encryption := Encryption;

  FParams.AddObject(ParamName, P);
end;

procedure TParamManager.SetParamValue(const ParamName: string; const Value: Variant);
begin
  ParamByName(ParamName).Value := Value;
end;

constructor TCustomRemoteParams.Create(ParamManager: TParamManager);
begin
  FParamManager := ParamManager;
end;

procedure TCustomRemoteParams.Open;
begin
end;

procedure TCustomRemoteParams.Refresh;
begin
end;

function TParamItem.BlobAsStringByCompany(CompanyID: Variant): string;
begin
  TMonitor.Enter(ParamManager);
  try
    Result := CustomGetBlobAsString(CompanyID)
  finally
    TMonitor.Exit(ParamManager);
  end;
end;

constructor TParamItem.Create(ParamManager: TParamManager);
begin
  FParamManager := ParamManager;
  FValue := Null;
end;

function TParamItem.DecodeString(const Value: string): string;
begin
  Result := ParamManager.Cipher.DecodeString(Value);
end;

function TParamItem.EncodeString(const Value: string): string;
begin
  Result := ParamManager.Cipher.EncodeString(Value);
end;

function TParamItem.GetAsInteger: Integer;
begin
  Result := GetValue;
end;

function TParamItem.GetBlobAsString: string;
begin
  TMonitor.Enter(ParamManager);
  try
    Result := CustomGetBlobAsString(FParamManager.CompanyID);
  finally
    TMonitor.Exit(ParamManager);
  end;
end;

function TParamItem.GetValue: Variant;
begin
  TMonitor.Enter(ParamManager);
  try
    Result := ValueByCompany(ParamManager.CompanyID);
  finally
    TMonitor.Exit(ParamManager);
  end;
end;

procedure TParamItem.CustomSetBlobAsString(CompanyID: Variant; const Value: string);
begin
end;

function TParamItem.CustomGetBlobAsString(CompanyID: Variant): string;
begin
end;

function TParamItem.CustomGetValue(const ParamName: string; CompanyID: Variant): Variant;
begin
  if VarIsNull(FValue) then
    Result := FDefaultValue
  else
    Result := FValue;
end;

procedure TParamItem.CustomSetValue(const ParamName: string; Value: Variant);
begin
end;

procedure TParamItem.LoadFromStream(Stream: TStream);
begin
end;

procedure TParamItem.SaveToStream(Stream: TStream);
begin
end;

procedure TParamItem.SetAsInteger(const Value: Integer);
begin
  SetValue(Value);
end;

procedure TParamItem.SetBlobNull;
begin
end;

procedure TParamItem.SetBlobAsString(const Value: string);
begin
  TMonitor.Enter(ParamManager);
  try
    CustomSetBlobAsString(FParamManager.CompanyID, Value);
  finally
    TMonitor.Exit(ParamManager);
  end;
end;

procedure TParamItem.SetBlobAsStringByCompany(CompanyID, Value: Variant);
begin
  TMonitor.Enter(ParamManager);
  try
    CustomSetBlobAsString(CompanyID, Value);
  finally
    TMonitor.Exit(ParamManager);
  end;
end;

procedure TParamItem.SetValue(const Value: Variant);
begin
  TMonitor.Enter(ParamManager);
  try
    if VarType(Value) = varDate then
      FValue := Trunc(Value) + Frac(Value)
    else
      FValue := Value;

    case Encryption of
      peEncryptionOn:
      begin
        if FValue <> Null then
          Fvalue := EncodeString(VarToStr(FValue));

        CustomSetValue(EncodeString(ParamName), FValue);
      end;
      peEncryptionOff:
        CustomSetValue(ParamName, FValue);
    end;
  finally
    TMonitor.Exit(ParamManager);
  end;
end;

procedure TParamItem.SetValueByCompany(CompanyID, Value: Variant);
var
  OldCompanyID: Variant;
begin
  TMonitor.Enter(ParamManager);
  try
    OldCompanyID := ParamManager.CompanyID;
    ParamManager.CompanyID := CompanyID;
    try
      SetValue(Value);
    finally
      ParamManager.CompanyID := OldCompanyID;
    end;
  finally
    TMonitor.Exit(ParamManager);
  end;
end;

function TParamItem.ValueByCompany(CompanyID: Variant): Variant;
begin
  TMonitor.Enter(ParamManager);
  try
    case Encryption of
      peEncryptionOn:
        begin
          Result := CustomGetValue(EncodeString(ParamName), CompanyID);
          if (Result <> Null) and (not IsDefault(Result)) then
            Result := DecodeString(VarToStr(Result));
        end;
      peEncryptionOff:
        Result := CustomGetValue(ParamName, CompanyID);
    end;
  finally
    TMonitor.Exit(ParamManager);
  end;
end;

function TParamItem.IsDefault(Value: Variant): Boolean;
begin
  try
    Result := Value = DefaultValue;
  except
    on E: EVariantTypeCastError do
      Exit(False);
  end;
end;

initialization

finalization
  Instance.Free;

end.
