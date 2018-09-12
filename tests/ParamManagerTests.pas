unit ParamManagerTests;

interface

uses
  DUnitX.TestFramework,
  ParamManagerTestsData,
  CustomDataSetParams,
  ParamManager,
  System.Generics.Collections,
  System.Classes,
  ParamManagerThread;

type
  [TestFixture]
  TParamManagerTests = class(TObject)
    const ThreadIterations = 500;
  private
    FSUT: TParamManager;
    procedure RecreateParamManager;
    procedure StartAndWaitFor(Threads: TObjectList<TParamManagerThread>);
    procedure AssertTesteOk(Threads: TObjectList<TParamManagerThread>);
    function GetParams(Quantity:Integer; Identifier:String):TDictionary<string, string>;
  public
    [Setup]
    procedure Setup;
    [Teardown]
    procedure Teardown;
  published
    procedure AppDataFolder_AppDataCompanyFolderNotEmpty_CompanyFolderAddedToAppFolderPath;
    procedure AppDataFolder_DefaultParams_AppDataPlusExeNameWithoutExt;
    procedure AppDataFolder_FolderDoesNotExists_FolderCreatedWhenPropertyRead;
    procedure DataSalvandoComoInteiro;
    procedure EncriptedParam;
    procedure ValueByCompany_LoggedOnAnotherCompany_CorrectValueReturned;
    procedure BlobAsStringByCompany_LoggedOnAnotherCompany_CorrectValueReturned;
    procedure BlobAsString_DefaultValueNull_EmptyStringReturned;
    procedure SetValueByCompany_OtherCompany_CorrectValueSet;
    procedure SetBlobAsStringByCompany_OtherCompany_CorrectValueSet;
    procedure GetSetParamValue_CustomizedCipher_EncryptedStoredValues;
    procedure GetSetParamValue_EncriptedParamWithDefaultValue_DefaultReturned;
    procedure TestCompanyRemoteParam;
    procedure TestGlobalRemoteParam;
    procedure TestParamAlreadyRegistered;
    procedure TestParamNotFound;
    procedure TestReadCompanyNotSet;
    procedure TestRegisterParam;
    procedure TestSessionParam;
    procedure TestUserCompanyRemoteParam;
    procedure TestUserRemoteParam;
    procedure TestWriteCompanyNotSet;
    procedure Valor_TamanhoExcedeLimite_LevantarException;
    procedure RegisterRemoteParam_RemoteParamsClassNotSet_EAssertionFailed;
    procedure BlobAsString_ParamNotInDataSet_ValueSet;
    procedure SetBlobNull_BlobParamWithValue_NullSet;
    procedure SaveLoadFromStream_StreamValue_ValueSaved;
    procedure BlobAsString_ValueNotSet_DefaultValueReturned;
    procedure HasParam_ParamRegistered_ResultTrue;
    procedure HasParam_ParamNotRegistered_ResultFalse;
    procedure GetDefaultParamValue_WithMultipleThreads_ShouldReturnTheCorrectValues;
    procedure GetParamValue_WithMultipleThreads_ShouldReturnTheCorrectValues;
    procedure ValueByCompany_WithMultipleThreads_ShouldReturnTheCorrectValues;
    procedure SetParamValue_WithMultipleThreads_ShouldSaveTheCorrectValues;
    procedure GetBlobAsString_WithMultipleThreads_ShouldReturnTheCorrectValues;
    procedure SetBlobAsString_WithMultipleThreads_ShouldSaveTheCorrectValues;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  ReverseCipher,
  System.StrUtils,
  Data.DB,
  DBClient,
  System.Variants,
  ParamManagerCipher;

const
  DefaultValue = 'DefaultValue';

var
  ParamData: TDmParamManagerTests;

type
  TCompanyUserNotSetDataSetParams = class(TCustomDataSetParams)
  public
    function NameField: TField; override;
    function ValueField: TField; override;
    function BlobField: TBlobField; override;
    function DataSet: TClientDataSet; override;
  end;

  TDataSetParams = class(TCompanyUserNotSetDataSetParams)
    function CompanyField: TField; override;
    function UserField: TField; override;
  public
    procedure Open; override;
  end;

procedure TParamManagerTests.AppDataFolder_AppDataCompanyFolderNotEmpty_CompanyFolderAddedToAppFolderPath;
begin
  FSUT.AppDataCompanyFolder := 'Acme';

  Assert.AreEqual(GetEnvironmentVariable('APPDATA') + '\Acme\Tests\', FSUT.AppDataFolder);
end;

procedure TParamManagerTests.AppDataFolder_DefaultParams_AppDataPlusExeNameWithoutExt;
begin
  Assert.AreEqual(GetEnvironmentVariable('APPDATA') + '\Tests\', FSUT.AppDataFolder);
end;

procedure TParamManagerTests.AppDataFolder_FolderDoesNotExists_FolderCreatedWhenPropertyRead;
var
  GUID: TGuid;
begin
  CreateGuid(GUID);
  FSUT.AppDataCompanyFolder := GuidToString(GUID);

  Assert.IsTrue(DirectoryExists(FSUT.AppDataFolder));
end;

procedure TParamManagerTests.AssertTesteOk(Threads: TObjectList<TParamManagerThread>);
var
  Thread: TParamManagerThread;
begin
  for Thread in Threads do
    Assert.IsTrue(Thread.TesteOk, Thread.ErrorMessage);
end;

procedure TParamManagerTests.DataSalvandoComoInteiro;
var
  DataHora: TDateTime;
begin
  DataHora := Now;

  FSUT.RegisterParam('DATA1', '', ssGlobal, psRemote);
  FSUT['DATA1'] := DataHora;
  Assert.IsTrue(SameDateTime(Trunc(Date) + Frac(DataHora), ParamData.cdsVALOR.AsVariant));
  Assert.IsTrue(SameDateTime(DataHora, FSUT['DATA1']));

  FSUT.RegisterParam('DATA2', '', ssGlobal, psLocal);
  FSUT['DATA2'] := DataHora;
  Assert.IsTrue(SameDateTime(DataHora, FSUT['DATA2']));

  FSUT.RegisterParam('DATA3', '', ssGlobal, psSession);
  FSUT['DATA3'] := DataHora;
  Assert.IsTrue(SameDateTime(DataHora, FSUT['DATA3']));
end;

procedure TParamManagerTests.EncriptedParam;
begin
  FSUT.RegisterParam('ENCRIPTADO', '', ssGlobal, psRemote, peEncryptionOn);

  FSUT.ParamByName('ENCRIPTADO').Value := 'SBRABOUS';

  Assert.AreEqual<string>('SBRABOUS', FSUT.ParamByName('ENCRIPTADO').Value);
  Assert.AreEqual('À„…•{“Œƒy|', ParamData.cdsNOME.AsString);
  Assert.AreEqual('Îx”„t’'#$008D'•', ParamData.cdsVALOR.AsString);
end;

procedure TParamManagerTests.ValueByCompany_LoggedOnAnotherCompany_CorrectValueReturned;
const
  Param = 'Param';
  Company1 = 1;
  Company2 = 2;
begin
  FSUT.RegisterParam(Param, DefaultValue, ssCompany, psRemote, peEncryptionOff);

  FSUT.CompanyID := Company1;
  FSUT.ParamByName(Param).Value := Company1;

  FSUT.CompanyID := Company2;
  FSUT.ParamByName(Param).Value := Company2;

  FSUT.CompanyID := Company1;
  Assert.AreEqual<integer>(Company1, FSUT.ParamByName(Param).ValueByCompany(Company1), 'Invalid Company1 value');
  Assert.AreEqual<integer>(Company2, FSUT.ParamByName(Param).ValueByCompany(Company2), 'Invalid Company2 value');
end;

function TParamManagerTests.GetParams(Quantity: Integer; Identifier:String): TDictionary<string, string>;
var
  I: Integer;
begin
  Result := TDictionary<string, string>.Create;

  for I := 1 to Quantity do
    Result.Add(Identifier + IntToStr(I), Identifier + IntToStr(I) + 'Value');
end;

procedure TParamManagerTests.GetParamValue_WithMultipleThreads_ShouldReturnTheCorrectValues;
const
  NoThreads = 10;
var
  Threads: TObjectList<TParamManagerThread>;
  Params: TDictionary<string, string>;
  Param: TPair<string, string>;
begin
  Params := nil;
  Threads := nil;

  try
    Threads := TObjectList<TParamManagerThread>.Create;
    Params := GetParams(NoThreads, 'ThreadGet');

    for Param in Params do
    begin
      FSUT.RegisterParam(Param.Key, '', ssGlobal, psRemote);
      FSUT[Param.key] := Param.Value;

      Threads.Add(TParamManagerGetValueThread.Create(FSUT, Param.Key, Param.Value, ThreadIterations));
    end;

    StartAndWaitFor(Threads);
    AssertTesteOk(Threads);
  finally
    Params.Free;
    Threads.Free;
  end;
end;

procedure TParamManagerTests.GetBlobAsString_WithMultipleThreads_ShouldReturnTheCorrectValues;
const
  NoThreads = 10;
  QtdeIteracoes = 5000; // Menos que isso o teste passa quase sempre
var
  Threads: TObjectList<TParamManagerThread>;
  Params: TDictionary<string, string>;
  Param: TPair<string, string>;
begin
  Params := nil;
  Threads := nil;
  try
    Threads := TObjectList<TParamManagerThread>.Create;
    Params := GetParams(NoThreads, 'ThreadGetBlobAsString');

    for Param in Params do
    begin
      FSUT.RegisterParam(Param.Key, '', ssGlobal, psRemote);
      FSUT.ParamByName(Param.key).BlobAsString := Param.Value;

      Threads.Add(TParamManagerGetBlobAsStringThread.Create(FSUT, Param.Key, Param.Value, QtdeIteracoes));
    end;

    StartAndWaitFor(Threads);
    AssertTesteOk(Threads);
  finally
    Params.Free;
    Threads.Free;
  end;
end;

procedure
    TParamManagerTests.GetDefaultParamValue_WithMultipleThreads_ShouldReturnTheCorrectValues;
const
  NoThreads = 10;
var
  Threads: TObjectList<TParamManagerThread>;
  Params: TDictionary<string, string>;
  Param: TPair<string, string>;
begin
  Params := nil;
  Threads := nil;

  try
    Threads := TObjectList<TParamManagerThread>.Create;
    Params := GetParams(NoThreads, 'ThreadGetDefault');

    for Param in Params do
    begin
      FSUT.RegisterParam(Param.Key, Param.Value, ssGlobal, psRemote);

      Threads.Add(TParamManagerGetValueThread.Create(FSUT, Param.Key, Param.Value, ThreadIterations));
    end;

    StartAndWaitFor(Threads);
    AssertTesteOk(Threads);
  finally
    Params.Free;
    Threads.Free;
  end;
end;

procedure TParamManagerTests.GetSetParamValue_CustomizedCipher_EncryptedStoredValues;
begin
  FSUT.Cipher := TReverseCipher;
  FSUT.RegisterParam('FOO', '', ssGlobal, psRemote, peEncryptionOn);

  FSUT['FOO'] := 'BAR';

  Assert.AreEqual<string>('BAR', FSUT['FOO']);
  Assert.AreEqual('OOF', ParamData.cdsNOME.AsString);
  Assert.AreEqual('RAB', ParamData.cdsVALOR.AsString);
end;

procedure TParamManagerTests.GetSetParamValue_EncriptedParamWithDefaultValue_DefaultReturned;
begin
  FSUT.RegisterParam('FOO', DefaultValue, ssGlobal, psRemote, peEncryptionOn);

  FSUT.ParamByName('FOO').Value := Null;

  Assert.AreEqual<string>(DefaultValue, FSUT.ParamByName('FOO').Value);
end;

procedure TParamManagerTests.SaveLoadFromStream_StreamValue_ValueSaved;
var
  Stream: TStringStream;
begin
  FSUT.RegisterParam('Blob', '', ssGlobal, psRemote, peEncryptionOff);

  Stream := TStringStream.Create;
  try
    Stream.WriteString('Value');
    FSUT.ParamByName('Blob').LoadFromStream(Stream);
  finally;
    Stream.Free;
  end;

  Assert.AreEqual('Value', ParamData.cdsDADOS.AsString, 'Value not saved to dataset');

  Stream := TStringStream.Create;
  try
    FSUT.ParamByName('Blob').SaveToStream(Stream);
    Assert.AreEqual('Value', Stream.DataString, 'Value not saved to stream');
  finally;
    Stream.Free;
  end;
end;

procedure TParamManagerTests.HasParam_ParamNotRegistered_ResultFalse;
const
  Param = 'test';
begin
  Assert.IsFalse(FSUT.HasParam(Param));
end;

procedure TParamManagerTests.HasParam_ParamRegistered_ResultTrue;
const
  Param = 'test';
begin
  FSUT.RegisterParam(Param, '', ssGlobal, psSession);

  Assert.IsTrue(FSUT.HasParam(Param));
end;

procedure TParamManagerTests.RecreateParamManager;
begin
  FSUT.Free;
  FSUT := TParamManager.Create;
end;

procedure TParamManagerTests.RegisterRemoteParam_RemoteParamsClassNotSet_EAssertionFailed;
begin
  TParamManager.RemoteParamsClass := nil;
  RecreateParamManager;

  Assert.WillRaise(
    procedure
    begin
      FSUT.RegisterParam('test', '', ssGlobal, psRemote);
    end, EAssertionFailed);
end;

procedure TParamManagerTests.BlobAsStringByCompany_LoggedOnAnotherCompany_CorrectValueReturned;
const
  Param = 'Param';
  Company1 = 'Company1';
  Company2 = 'Company2';
  Value1 = 'Value1';
  Value2 = 'Value2';
begin
  FSUT.RegisterParam(Param, DefaultValue, ssCompany, psRemote);

  FSUT.CompanyID := Company1;
  FSUT.ParamByName(Param).BlobAsString := Value1;

  FSUT.CompanyID := Company2;
  FSUT.ParamByName(Param).BlobAsString := Value2;

  FSUT.CompanyID := Company1;
  Assert.AreEqual<string>(Value1, FSUT.ParamByName(Param).BlobAsStringByCompany(Company1), 'Invalid Company1 value');
  Assert.AreEqual<string>(Value2, FSUT.ParamByName(Param).BlobAsStringByCompany(Company2), 'Invalid Company2 value');
end;

procedure TParamManagerTests.BlobAsString_DefaultValueNull_EmptyStringReturned;
begin
  FSUT.RegisterParam('Param', Null, ssCompany, psRemote);
  FSUT.CompanyID := 'Company1';

  Assert.IsEmpty(FSUT.ParamByName('Param').BlobAsString);
end;

procedure TParamManagerTests.BlobAsString_ParamNotInDataSet_ValueSet;
begin
  FSUT.RegisterParam('Blob', '', ssGlobal, psRemote, peEncryptionOff);

  FSUT.ParamByName('Blob').BlobAsString := 'Value';

  Assert.AreEqual('Blob', ParamData.cdsNOME.AsString, 'ParamName not set in dataset');
  Assert.AreEqual('Value', ParamData.cdsDADOS.AsString, 'Value not save in dataset');

  Assert.AreEqual('Value', FSUT.ParamByName('Blob').BlobAsString, 'BlobAsString should return the value');
end;

procedure TParamManagerTests.BlobAsString_ValueNotSet_DefaultValueReturned;
begin
  FSUT.RegisterParam('Blob', 'Default', ssGlobal, psRemote, peEncryptionOff);

  Assert.AreEqual('Default', FSUT.ParamByName('Blob').BlobAsString);
end;

procedure TParamManagerTests.SetBlobNull_BlobParamWithValue_NullSet;
begin
  FSUT.RegisterParam('Blob', '', ssGlobal, psRemote, peEncryptionOff);
  FSUT.ParamByName('Blob').BlobAsString := 'Valor';

  FSUT.ParamByName('Blob').SetBlobNull;

  Assert.AreEqual('Blob', ParamData.cdsNOME.AsString, 'ParamName not set in dataset');
  Assert.IsTrue(ParamData.cdsDADOS.IsNull, 'Value not cleared in dataset');
  Assert.AreEqual('', FSUT.ParamByName('Blob').BlobAsString, 'BlobAsString should return a blank string');
end;

procedure TParamManagerTests.SetBlobAsStringByCompany_OtherCompany_CorrectValueSet;
const
  Param = 'Parametro';
  Company1 = 'Company1';
  Company2 = 'Company2';
  Value1 = 'Value1';
  Value2 = 'Value2';
begin
  FSUT.RegisterParam(Param, DefaultValue, ssCompany, psRemote);

  FSUT.CompanyID := Company1;
  FSUT.ParamByName(Param).SetBlobAsStringByCompany(Company2, Value2);

  FSUT.CompanyID := Company2;
  Assert.AreEqual<string>(Value2, FSUT.ParamByName(Param).BlobAsString);
end;

procedure TParamManagerTests.SetBlobAsString_WithMultipleThreads_ShouldSaveTheCorrectValues;
const
  NoThreads = 10;
var
  Threads: TObjectList<TParamManagerThread>;
  Params: TDictionary<string, string>;
  Param: TPair<string, string>;
begin
  Params := nil;
  Threads := nil;

  try
    Threads := TObjectList<TParamManagerThread>.Create;
    Params := GetParams(NoThreads, 'ThreadBlogAsStringSet');

    for Param in Params do
    begin
      FSUT.RegisterParam(Param.Key, '', ssGlobal, psRemote);

      Threads.Add(TParamManagerSetBlogAsStringThread.Create(FSUT, Param.Key, Param.Value, ThreadIterations));
    end;

    StartAndWaitFor(Threads);
    AssertTesteOk(Threads);

    for Param in Params do
      Assert.AreEqual(FSUT.ParamByName(Param.key).BlobAsString, Param.Value, False, 'Param not saved properly');
  finally
    Params.Free;
    Threads.Free;
  end;
end;

procedure TParamManagerTests.SetParamValue_WithMultipleThreads_ShouldSaveTheCorrectValues;
const
  NoThreads = 20;
var
  Threads: TObjectList<TParamManagerThread>;
  Params: TDictionary<string, string>;
  Param: TPair<string, string>;
begin
  Params := nil;
  Threads := nil;

  try
    Threads := TObjectList<TParamManagerThread>.Create;
    Params := GetParams(NoThreads, 'ThreadSet');

    for Param in Params do
    begin
      FSUT.RegisterParam(Param.Key, '', ssGlobal, psRemote);

      Threads.Add(TParamManagerSetValueThread.Create(FSUT, Param.Key, Param.Value, ThreadIterations));
    end;

    StartAndWaitFor(Threads);
    AssertTesteOk(Threads);

    for Param in Params do
      Assert.AreEqual(FSUT[Param.key], Param.Value, false, 'Param not saved properly');
  finally
    Params.Free;
    Threads.Free;
  end;
end;

procedure TParamManagerTests.Setup;
begin
  TParamManager.RemoteParamsClass := TDataSetParams;
  TDefaultCipher.Key := '{6BC2C8B5-9248-468E-B800-540AD8805BA7}';
  FSUT := TParamManager.Create;
end;

procedure TParamManagerTests.SetValueByCompany_OtherCompany_CorrectValueSet;
const
  Param = 'Parametro';
  Company1 = 1;
  Company2 = 2;
begin
  FSUT.RegisterParam(Param, DefaultValue, ssCompany, psRemote, peEncryptionOff);

  FSUT.CompanyID := Company1;
  FSUT.ParamByName(Param).SetValueByCompany(Company2, Company2);

  FSUT.CompanyID := Company2;
  Assert.AreEqual<integer>(Company2, FSUT[Param]);
end;

procedure TParamManagerTests.StartAndWaitFor(Threads: TObjectList<TParamManagerThread>);
var
  Thread: TThread;
begin
  for Thread in Threads do
    Thread.Start;

  for Thread in Threads do
    Thread.WaitFor;
end;

procedure TParamManagerTests.Teardown;
begin
  FreeAndNil(ParamData);
  FSUT.Free;
end;

procedure TParamManagerTests.TestCompanyRemoteParam;
begin
  FSUT.RegisterParam('Test', DefaultValue, ssCompany, psRemote, peEncryptionOff);

  FSUT.CompanyID := 1;
  FSUT.ParamByName('Test').Value := 1;

  FSUT.CompanyID := 2;
  FSUT.ParamByName('Test').Value := 2;

  RecreateParamManager;

  FSUT.RegisterParam('Test', 'DefaultValue', ssCompany, psRemote, peEncryptionOff);

  FSUT.CompanyID := 1;
  Assert.AreEqual<integer>(1, FSUT.ParamByName('Test').AsInteger);

  FSUT.CompanyID := 2;
  Assert.AreEqual<integer>(2, FSUT.ParamByName('Test').AsInteger);

  FSUT.CompanyID := 3;
  Assert.AreEqual<string>(DefaultValue, FSUT.ParamByName('Test').Value);
end;

procedure TParamManagerTests.TestGlobalRemoteParam;
begin
  FSUT.RegisterParam('Test', 'DefaultValue', ssGlobal, psRemote, peEncryptionOff);
  FSUT.ParamByName('Test').Value := 1;

  RecreateParamManager;
  FSUT.RegisterParam('Test', 'DefaultValue', ssGlobal, psRemote, peEncryptionOff);

  Assert.AreEqual<integer>(FSUT.ParamByName('Test').Value, 1);
end;

procedure TParamManagerTests.TestParamAlreadyRegistered;
begin
  Assert.WillRaise(
    procedure
    begin
      FSUT.RegisterParam('Test', 'DefaultValue', ssGlobal, psRemote, peEncryptionOff);
      FSUT.RegisterParam('Test1', 'DefaultValue', ssGlobal, psRemote, peEncryptionOff);
      FSUT.RegisterParam('Test2', 'DefaultValue', ssGlobal, psRemote, peEncryptionOff);
      FSUT.RegisterParam('Test', 'DefaultValue', ssGlobal, psRemote, peEncryptionOff);
    end, EParamAlreadyRegistered);
end;

procedure TParamManagerTests.TestParamNotFound;
begin
  Assert.WillRaise(
    procedure
    begin
      FSUT.ParamByName('Test');
    end, EParamNotFound);
end;

procedure TParamManagerTests.TestReadCompanyNotSet;
var
  Temp: string;
begin
  FreeAndNil(FSUT);
  TParamManager.RemoteParamsClass := TCompanyUserNotSetDataSetParams;
  RecreateParamManager;

  Assert.WillRaise(
    procedure
    begin
      FSUT.RegisterParam('Test', DefaultValue, ssCompany, psRemote, peEncryptionOff);
      Temp := FSUT.ParamByName('Test').Value;
    end, EUserCompanyNotSet);
end;

procedure TParamManagerTests.TestRegisterParam;
begin
  FSUT.RegisterParam('Test', 'DefaultValue', ssGlobal, psRemote, peEncryptionOff);
  Assert.AreEqual(FSUT.ParamByName('Test').ParamName, 'Test');
end;

procedure TParamManagerTests.TestSessionParam;
begin
  FSUT.RegisterParam('Test', True, ssGlobal, psSession);
  Assert.IsTrue(FSUT.ParamByName('Test').Value);
end;

procedure TParamManagerTests.TestUserCompanyRemoteParam;
const
  LDefaultValue = 0;
begin
  FSUT.RegisterParam('Test', LDefaultValue, ssUserCompany, psRemote, peEncryptionOff);

  FSUT.CompanyID := 1;
  FSUT.UserID := 98;
  FSUT.ParamByName('Test').Value := 1;

  FSUT.CompanyID := 2;
  FSUT.UserID := 99;
  FSUT.ParamByName('Test').Value := 2;

  RecreateParamManager;

  FSUT.RegisterParam('Test', LDefaultValue, ssUserCompany, psRemote, peEncryptionOff);

  FSUT.CompanyID := 1;
  FSUT.UserID := 98;
  Assert.AreEqual(1, FSUT.ParamByName('Test').AsInteger);

  FSUT.CompanyID := 2;
  FSUT.UserID := 99;
  Assert.AreEqual(2, FSUT.ParamByName('Test').AsInteger);

  FSUT.CompanyID := 3;
  FSUT.UserID := 97;
  Assert.AreEqual<integer>(LDefaultValue, FSUT.ParamByName('Test').Value);
end;

procedure TParamManagerTests.TestUserRemoteParam;
const
  LDefaultValue = 'DefaultValue';
begin
  FSUT.RegisterParam('Test', LDefaultValue, ssUser, psRemote);

  FSUT.UserID := 1;
  FSUT.ParamByName('Test').Value := 1;

  FSUT.UserID := 2;
  FSUT.ParamByName('Test').Value := 2;

  RecreateParamManager;

  FSUT.RegisterParam('Test', 'DefaultValue', ssUser, psRemote);

  FSUT.UserID := 1;
  Assert.AreEqual(1, FSUT.ParamByName('Test').AsInteger);

  FSUT.UserID := 2;
  Assert.AreEqual(2, FSUT.ParamByName('Test').AsInteger);

  FSUT.UserID := 3;
  Assert.AreEqual<string>(LDefaultValue, FSUT.ParamByName('Test').Value);
end;

procedure TParamManagerTests.TestWriteCompanyNotSet;
begin
  FreeAndNil(FSUT);
  TParamManager.RemoteParamsClass := TCompanyUserNotSetDataSetParams;
  RecreateParamManager;

  Assert.WillRaise(
    procedure
    begin
      FSUT.RegisterParam('Test', DefaultValue, ssCompany, psRemote, peEncryptionOff);
      FSUT.ParamByName('Test').Value := 'Teste';
    end, EUserCompanyNotSet);
end;

procedure TParamManagerTests.Valor_TamanhoExcedeLimite_LevantarException;
begin
  FSUT.RegisterParam('qq_Param', '', ssGlobal, psRemote);

  Assert.WillRaise(
    procedure
    begin
      FSUT['qq_Param'] := DupeString('A', 1001);
    end, EAssertionFailed);
end;

procedure TParamManagerTests.ValueByCompany_WithMultipleThreads_ShouldReturnTheCorrectValues;
const
  NoThreads = 10;
  Parametro = 'ThreadValueByCompany';
var
  I: Integer;
  Threads: TObjectList<TParamManagerThread>;
begin
  Threads := TObjectList<TParamManagerThread>.Create;
  try
    FSUT.RegisterParam(Parametro, DefaultValue, ssCompany, psRemote, peEncryptionOff);

    for I := 1 to NoThreads do
    begin
      FSUT.CompanyID := I;
      FSUT.ParamByName(Parametro).Value := 'Value' + IntToStr(I);

      Threads.Add(TParamManagerValueByNameThread.Create(FSUT, Parametro, 'Value' + IntToStr(I), I, ThreadIterations))
    end;

    StartAndWaitFor(Threads);
    AssertTesteOk(Threads);
  finally
    Threads.Free;
  end;
end;

function TDataSetParams.CompanyField: TField;
begin
  Result := ParamData.cdsEMPRESA_ID;
end;

function TCompanyUserNotSetDataSetParams.DataSet: TClientDataSet;
begin
  Result := ParamData.cds;
end;

function TCompanyUserNotSetDataSetParams.BlobField: TBlobField;
begin
  Result := ParamData.cdsDADOS;
end;

function TCompanyUserNotSetDataSetParams.NameField: TField;
begin
  Result := ParamData.cdsNOME;
end;

function TCompanyUserNotSetDataSetParams.ValueField: TField;
begin
  Result := ParamData.cdsVALOR;
end;

procedure TDataSetParams.Open;
begin
  inherited;
  if ParamData = nil then
  begin
    ParamData := TDmParamManagerTests.Create(nil);
    ParamData.cds.CreateDataSet;
  end;
end;

function TDataSetParams.UserField: TField;
begin
  Result := ParamData.cdsUSUARIO_ID;
end;

initialization

TDUnitX.RegisterTestFixture(TParamManagerTests);

end.
