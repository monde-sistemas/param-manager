unit AureliusParamItem;

interface

uses
  ParamManager,
  Aurelius.Engine.ObjectManager,
  ParamModel;

type
  TAureliusParamItem = class(TParamItem)
  private
    FObjectManager: TObjectManager;
    function GetCompanyParam(const ParamName: string; CompanyID: Variant): TParam;
    function GetGlobalParam(const ParamName: string): TParam;
    function GetUserCompanyParam(const ParamName: string; CompanyID, UserID: Variant): TParam;
    function GetUserParam(const ParamName: string; UserID: Variant): TParam;
    procedure Insert(const ParamName: string; CompanyID, UserID, Value: Variant);
    procedure SetCompanyParam(const ParamName, CompanyID: string; Value: Variant);
    procedure SetGlobalParam(const ParamName: string; Value: Variant);
    procedure SetUserCompanyParam(const ParamName, UserID, CompanyID: string; Value: Variant);
    procedure SetUserParam(const ParamName, UserID: string; Value: Variant);
    procedure SetValue(Param: TParam; const ParamName: string; CompanyID, UserID, Value: Variant);
    procedure Update(Param: TParam; Value: Variant);
  protected
    function CustomGetValue(const ParamName: string; CompanyID: Variant): Variant; override;
    procedure CustomSetValue(const ParamName: string; Value: Variant); override;
  public
    constructor Create(ParamManager: TParamManager; ObjectManager: TObjectManager); reintroduce;
  end;

implementation

uses
  Aurelius.Criteria.Base,
  Aurelius.Criteria.Linq,
  System.Variants,
  Aurelius.Types.Nullable;

constructor TAureliusParamItem.Create(ParamManager: TParamManager; ObjectManager: TObjectManager);
begin
  inherited Create(ParamManager);
  FObjectManager := ObjectManager;
end;

function TAureliusParamItem.CustomGetValue(const ParamName: string; CompanyID: Variant): Variant;
var
  Param: TParam;
begin
  Param := nil;

  FObjectManager.Clear;

  case SystemScope of
    ssGlobal:
      Param := GetGlobalParam(ParamName);
    ssCompany:
      Param := GetCompanyParam(ParamName, CompanyID);
    ssUser:
      Param := GetUserParam(ParamName, ParamManager.UserID);
    ssUserCompany:
      Param := GetUserCompanyParam(ParamName, CompanyID, ParamManager.UserID);
  end;

  if Param = nil then
    Result := DefaultValue
  else
  begin
    if Param.Valor.HasValue then
      Result := Param.Valor
    else
      Result := Null;
  end;
end;

procedure TAureliusParamItem.CustomSetValue(const ParamName: string; Value: Variant);
begin
  FObjectManager.Clear;
  case SystemScope of
    ssGlobal:
      SetGlobalParam(ParamName, Value);
    ssCompany:
      SetCompanyParam(ParamName, ParamManager.CompanyID, Value);
    ssUser:
      SetUserParam(ParamName, ParamManager.UserID, Value);
    ssUserCompany:
      SetUserCompanyParam(ParamName, ParamManager.UserID, ParamManager.CompanyID, Value);
  end;
end;

function TAureliusParamItem.GetCompanyParam(const ParamName: string; CompanyID: Variant): TParam;
begin
  Result := FObjectManager.Find<TParam>.Add(
    TLinq.Eq('Nome', ParamName) and TLinq.Eq('Empresa', CompanyID) and TLinq.IsNull('Usuario')
  ).UniqueResult
end;

function TAureliusParamItem.GetGlobalParam(const ParamName: string): TParam;
begin
  Result := FObjectManager.Find<TParam>.Add(
    TLinq.Eq('Nome', ParamName) and TLinq.IsNull('Empresa') and TLinq.IsNull('Usuario')
  ).UniqueResult;
end;

function TAureliusParamItem.GetUserCompanyParam(const ParamName: string; CompanyID, UserID: Variant): TParam;
begin
  Result := FObjectManager.Find<TParam>.Add(
    TLinq.Eq('Nome', ParamName) and TLinq.Eq('Empresa', CompanyID) and TLinq.Eq('Usuario', UserID)
  ).UniqueResult;
end;

function TAureliusParamItem.GetUserParam(const ParamName: string; UserID: Variant): TParam;
begin
  Result := FObjectManager.Find<TParam>.Add(
    TLinq.Eq('Nome', ParamName) and TLinq.Eq('Usuario', UserID) and TLinq.IsNull('Empresa')
  ).UniqueResult
end;

procedure TAureliusParamItem.Insert(const ParamName: string; CompanyID, UserID, Value: Variant);
var
  Param: TParam;
begin
  Param := TParam.Create;
  try
    Param.Nome := ParamName;
    if Value <> Null then
      Param.Valor := Value;

    if CompanyID <> Null then
      Param.Empresa := CompanyID;

    if UserID <> Null then
      Param.Usuario := UserID;
  except
    Param.Free;
    raise;
  end;

  FObjectManager.Save(Param);
end;

procedure TAureliusParamItem.SetCompanyParam(const ParamName, CompanyID: string; Value: Variant);
var
  Param: TParam;
begin
  Param := GetCompanyParam(ParamName, CompanyID);
  SetValue(Param, ParamName, CompanyID, Null, Value);
end;

procedure TAureliusParamItem.SetGlobalParam(const ParamName: string; Value: Variant);
var
  Param: TParam;
begin
  Param := GetGlobalParam(ParamName);
  SetValue(Param, ParamName, Null, Null, Value)
end;

procedure TAureliusParamItem.SetUserCompanyParam(const ParamName, UserID, CompanyID: string; Value: Variant);
var
  Param: TParam;
begin
  Param := GetUserCompanyParam(ParamName, CompanyID, UserID);
  SetValue(Param, ParamName, CompanyID, UserID, Value);
end;

procedure TAureliusParamItem.SetUserParam(const ParamName, UserID: string; Value: Variant);
var
  Param: TParam;
begin
  Param := GetUserParam(ParamName, UserID);
  SetValue(Param, ParamName, Null, UserID, Value);
end;

procedure TAureliusParamItem.SetValue(Param: TParam; const ParamName: string; CompanyID, UserID, Value: Variant);
begin
  if Param <> nil then
    Update(Param, Value)
  else
    Insert(ParamName, CompanyID, UserID, Value);

  FObjectManager.Flush;
end;

procedure TAureliusParamItem.Update(Param: TParam; Value: Variant);
begin
  if Value = Null then
    Param.Valor := SNull
  else
    Param.Valor := Value;
end;

end.

