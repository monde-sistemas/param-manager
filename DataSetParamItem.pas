unit DataSetParamItem;

interface

uses
  DB,
  Classes,
  CustomDatasetParams,
  ParamManager;

type
  TDataSetParamItem = class(TParamItem)
  private
    FDataSetParams: TCustomDataSetParams;
    procedure CheckCompanyAndUser;
    function DataSet: TDataSet;
    function LocalizarParametroEmDataSet: Boolean; overload;
    function LocalizarParametroEmDataSet(const ParamName: string; CompanyID: Variant): Boolean; overload;
    procedure InsertOrEdit(const ParamName: string; CompanyID: Variant);
  protected
    procedure CustomSetValue(const ParamName: string; Value: Variant); override;
    function CustomGetValue(const ParamName: string; CompanyID: Variant): Variant; override;
    function CustomGetBlobAsString(CompanyID: Variant): string; override;
    procedure CustomSetBlobAsString(CompanyID: Variant; const Value: string); override;
  public
    procedure SaveToStream(Stream: TStream); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SetBlobNull; override;
    constructor Create(DataSetParams: TCustomDataSetParams); reintroduce;
  end;

implementation

uses
  SysUtils,
  Variants;

constructor TDataSetParamItem.Create(DataSetParams: TCustomDataSetParams);
begin
  inherited Create(DataSetParams.ParamManager);
  FDataSetParams := DataSetParams;
end;

procedure TDataSetParamItem.CheckCompanyAndUser;
begin
  case SystemScope of
    ssCompany:
      if (FDataSetParams.CompanyField = nil) then
        raise EUserCompanyNotSet.Create('Company Field not set. You can''t use company parameters.');
    ssUser:
      if (FDataSetParams.UserField = nil) then
        raise EUserCompanyNotSet.Create('User not set. You can''t use user parameters!');
    ssUserCompany:
      if (FDataSetParams.UserField = nil) or (FDataSetParams.CompanyField = nil) then
        raise EUserCompanyNotSet.Create('User or Company not set.');
  end;
end;

function TDataSetParamItem.DataSet: TDataSet;
begin
  Result := FDataSetParams.DataSet;

  Assert(Result <> nil);
end;

function TDataSetParamItem.CustomGetBlobAsString(CompanyID: Variant): string;
begin
  Assert(Encryption = peEncryptionOff);

  FDataSetParams.Open;
  if LocalizarParametroEmDataSet(ParamName, CompanyID) then
    Result := FDataSetParams.BlobField.AsString
  else
    Result := VarToStr(DefaultValue);
end;

function TDataSetParamItem.CustomGetValue(const ParamName: string; CompanyID: Variant): Variant;
begin
  FDataSetParams.Open;
  CheckCompanyAndUser;

  if (not LocalizarParametroEmDataSet(ParamName, CompanyID)) or (FDataSetParams.ValueField.IsNull) then
    Result := DefaultValue
  else
    Result := FDataSetParams.ValueField.Value;
end;

function TDataSetParamItem.LocalizarParametroEmDataSet(const ParamName: string; CompanyID: Variant): Boolean;
begin
  case SystemScope of
    ssGlobal:
      Result := DataSet.Locate(FDataSetParams.NameField.FieldName, ParamName, []);

    ssCompany:
      Result := DataSet.Locate(Format('%s; %s', [FDataSetParams.CompanyField.FieldName,
        FDataSetParams.NameField.FieldName]), VarArrayOf([CompanyID, ParamName]), []);

    ssUser:
      Result := DataSet.Locate(Format('%s; %s', [FDataSetParams.UserField.FieldName,
        FDataSetParams.NameField.FieldName]), VarArrayOf([ParamManager.UserID, ParamName]), []);

    ssUserCompany:
      Result := DataSet.Locate(Format('%s;%s;%s', [FDataSetParams.UserField.FieldName,
        FDataSetParams.CompanyField.FieldName, FDataSetParams.NameField.FieldName]),
        VarArrayOf([ParamManager.UserID, CompanyID, ParamName]), []);
  else
    raise Exception.Create('Not implemented');
  end;
end;

procedure TDataSetParamItem.InsertOrEdit(const ParamName: string; CompanyID: Variant);
begin
  if LocalizarParametroEmDataSet(ParamName, CompanyID) then
    DataSet.Edit
  else
    DataSet.Insert;

  FDataSetParams.NameField.Value := ParamName;
  case SystemScope of
    ssCompany:
      FDataSetParams.CompanyField.Value := CompanyID;
    ssUser:
      FDataSetParams.UserField.Value := ParamManager.UserID;
    ssUserCompany:
    begin
      FDataSetParams.CompanyField.Value := CompanyID;
      FDataSetParams.UserField.Value := ParamManager.UserID;
    end;
  end;
end;

procedure TDataSetParamItem.CustomSetValue(const ParamName: string; Value: Variant);
begin
  FDataSetParams.Open;
  CheckCompanyAndUser;
  Assert(Length(VarToStr(Value)) < FDataSetParams.ValueField.Size, 'O valor excede o tamanho permitido');

  InsertOrEdit(ParamName, ParamManager.CompanyID);
  FDataSetParams.ValueField.Value := Value;
  DataSet.Post;
end;

procedure TDataSetParamItem.SaveToStream(Stream: TStream);
begin
  FDataSetParams.Open;
  if LocalizarParametroEmDataSet then
    FDataSetParams.BlobField.SaveToStream(Stream);
end;

procedure TDataSetParamItem.LoadFromStream(Stream: TStream);
begin
  FDataSetParams.Open;
  InsertOrEdit(ParamName, ParamManager.CompanyID);
  FDataSetParams.BlobField.LoadFromStream(Stream);
  DataSet.Post;
end;

function TDataSetParamItem.LocalizarParametroEmDataSet: Boolean;
begin
  Result := LocalizarParametroEmDataSet(ParamName, ParamManager.CompanyID);
end;

procedure TDataSetParamItem.SetBlobNull;
begin
  FDataSetParams.Open;
  InsertOrEdit(ParamName, ParamManager.CompanyID);
  FDataSetParams.BlobField.AsVariant := NULL;
  DataSet.Post;
end;

procedure TDataSetParamItem.CustomSetBlobAsString(CompanyID: Variant; const Value: string);
begin
  FDataSetParams.Open;
  InsertOrEdit(ParamName, CompanyID);
  FDataSetParams.BlobField.AsString := Value;
  DataSet.Post;
end;

end.
