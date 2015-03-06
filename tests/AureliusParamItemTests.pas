unit AureliusParamItemTests;

interface

uses
  DUnitX.TestFramework,
  Aurelius.Engine.DatabaseManager,
  Aurelius.Drivers.Interfaces,
  Aurelius.Sql.SQLite,
  Aurelius.Engine.ObjectManager,
  AureliusParamItem,
  ParamManager;

type
  [TestFixture]
  TAureliusParamItemTests = class
  private
    FDBManager: TDatabaseManager;
    FObjectManager: TObjectManager;
    FConnection: IDBConnection;
    FSUT: TAureliusParamItem;
    FParamManager: TParamManager;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [SetupFixture]
    procedure SetupFixture;
    [TeardownFixture]
    procedure TeardownFixture;
  published
    procedure GetSetValue_EncriptionOn_EncryptedStoredValues;
    procedure AsInteger_EncriptionOn_IntegerValueReturned;
    procedure GetValue_NoValueDefined_DefaultValueReturned;
    procedure GetValue_GlobalParam_ValueReturned;
    procedure GetValue_NullValueInDB_NullReturned;
    procedure GetValue_CompanyParam_ValueReturned;
    procedure GetValue_UserParam_ValueReturned;
    procedure GetValue_UserCompanyParamSameUserWrongCompany_ValueReturned;
    procedure GetValue_ParamUpdatedDirectlyOnDatabase_ValueFromDatabaseReturned;
    procedure GetValue_ParamInsertedDirectlyOnDatabase_ValueFromDatabaseReturned;
    procedure SetValue_GlobalParam_ValueStoredInDB;
    procedure SetValue_CompanyParam_ValueStoredInDB;
    procedure SetValue_UserParam_ValueStoredInDB;
    procedure SetValue_UserCompanyParam_ValueStoredInDB;
    procedure SetValue_NullValue_ValueStoredInDB;
    procedure SetValue_ExistingParam_ValueUpdatedInDB;
  end;

implementation

uses
  System.SysUtils,
  Aurelius.Drivers.SQLite,
  ParamModel,
  System.Generics.Collections,
  System.Variants,
  Aurelius.Commands.Listeners,
  ReverseCipher,
  Aurelius.Criteria.Linq,
  ParamManagerCipher;

const
  DatabaseName = 'data.db';

procedure TAureliusParamItemTests.AsInteger_EncriptionOn_IntegerValueReturned;
var
  Param: TParam;
begin
  FSUT.ParamName := 'A';
  FSUT.SystemScope := ssGlobal;
  FSUT.Encryption := peEncryptionOn;
  FSUT.DefaultValue := 0;

  Param := TParam.Create;
  Param.Nome := '¼';
  Param.Valor := '´';
  FObjectManager.Save(Param);

  Assert.AreEqual(9, FSUT.AsInteger);
end;

procedure TAureliusParamItemTests.Setup;
begin
  FObjectManager := TObjectManager.Create(FConnection);
  FParamManager := TParamManager.Create;
  FSUT := TAureliusParamItem.Create(FParamManager, FObjectManager);
  TDefaultCipher.Key := '{8737A7FE-465D-4C01-8555-EF324368642E}';
end;

procedure TAureliusParamItemTests.SetupFixture;
begin
  DeleteFile(DatabaseName);

  FConnection := TSQLiteNativeConnectionAdapter.Create(DatabaseName);
  FDBManager := TDatabaseManager.Create(FConnection);
  FDBManager.BuildDatabase;
end;

procedure TAureliusParamItemTests.TearDown;
begin
  FParamManager.Free;
  FSUT.Free;
  FObjectManager.Free;
end;

procedure TAureliusParamItemTests.TeardownFixture;
begin
  FConnection.Disconnect;
  FDBManager.Free;
  DeleteFile(DatabaseName);
end;

procedure TAureliusParamItemTests.GetValue_CompanyParam_ValueReturned;
var
  Param: TParam;
begin
  Param := TParam.Create;
  Param.Nome := 'Test';
  Param.Valor := 'WrongValue';
  Param.Empresa := 'WrongCompany';
  FObjectManager.Save(Param);

  Param := TParam.Create;
  Param.Nome := 'Test';
  Param.Valor := 'CorrectValue';
  Param.Empresa := 'CorrectCompany';
  FObjectManager.Save(Param);

  FSUT.ParamName := 'Test';
  FSUT.SystemScope := ssCompany;
  FParamManager.CompanyID := 'CorrectCompany';

  Assert.AreEqual<string>('CorrectValue', FSUT.Value);
end;

procedure TAureliusParamItemTests.GetValue_GlobalParam_ValueReturned;
var
  Param: TParam;
begin
  Param := TParam.Create;
  Param.Nome := 'Test';
  Param.Valor := 'Value';
  FObjectManager.Save(Param);

  FSUT.ParamName := 'Test';
  FSUT.SystemScope := ssGlobal;

  Assert.AreEqual<string>('Value', FSUT.Value);
end;

procedure TAureliusParamItemTests.GetValue_NoValueDefined_DefaultValueReturned;
begin
  FSUT.ParamName := 'Test';
  FSUT.SystemScope := ssGlobal;
  FSUT.DefaultValue := 'Default';

  Assert.AreEqual<string>('Default', FSUT.Value);
end;

procedure TAureliusParamItemTests.GetValue_UserCompanyParamSameUserWrongCompany_ValueReturned;
var
  Param: TParam;
begin
  Param := TParam.Create;
  Param.Nome := 'Test';
  Param.Valor := 'WrongValue';
  Param.Usuario := 'User';
  Param.Empresa := 'WrongCompany';
  FObjectManager.Save(Param);

  Param := TParam.Create;
  Param.Nome := 'Test';
  Param.Valor := 'CorrectValue';
  Param.Usuario := 'User';
  Param.Empresa := 'CorrectCompany';
  FObjectManager.Save(Param);

  FSUT.ParamName := 'Test';
  FSUT.SystemScope := ssUserCompany;
  FParamManager.UserID := 'User';
  FParamManager.CompanyID := 'CorrectCompany';

  Assert.AreEqual<string>('CorrectValue', FSUT.Value);
end;

procedure TAureliusParamItemTests.GetValue_UserParam_ValueReturned;
var
  Param: TParam;
begin
  Param := TParam.Create;
  Param.Nome := 'Test';
  Param.Valor := 'WrongValue';
  Param.Usuario := 'AnotherUser';
  FObjectManager.Save(Param);

  Param := TParam.Create;
  Param.Nome := 'Test';
  Param.Valor := 'CorrectValue';
  Param.Usuario := 'CurrentUser';
  FObjectManager.Save(Param);

  FSUT.ParamName := 'Test';
  FSUT.SystemScope := ssUser;
  FParamManager.UserID := 'CurrentUser';

  Assert.AreEqual<string>('CorrectValue', FSUT.Value);
end;

procedure TAureliusParamItemTests.GetSetValue_EncriptionOn_EncryptedStoredValues;
const
  EncriptedParamName = 'OOF';
var
  Param: TParam;
begin
  FParamManager.Cipher := TReverseCipher;

  FSUT.ParamName := 'FOO';
  FSUT.SystemScope := ssGlobal;
  FSUT.Encryption := peEncryptionOn;

  FSUT.Value := 'BAR';

  Param := FObjectManager.Find<TParam>.Add(
     TLinq.Eq('Nome', EncriptedParamName) and TLinq.IsNull('Empresa') and TLinq.IsNull('Usuario')
    ).UniqueResult;

  Assert.AreEqual(EncriptedParamName, Param.Nome);
  Assert.AreEqual('RAB', Param.Valor.Value);
  Assert.AreEqual<string>('BAR', FSUT.Value);
end;

procedure TAureliusParamItemTests.GetValue_NullValueInDB_NullReturned;
var
  Param: TParam;
begin
  Param := TParam.Create;
  Param.Nome := 'NullValue';
  FObjectManager.Save(Param);

  FSUT.ParamName := 'NullValue';
  FSUT.SystemScope := ssGlobal;

  Assert.AreEqual<Variant>(Null, FSUT.Value);
end;

procedure TAureliusParamItemTests.GetValue_ParamInsertedDirectlyOnDatabase_ValueFromDatabaseReturned;
var
  SQLCommand: IDBStatement;
begin
  SQLCommand := FConnection.CreateStatement;
  SQLCommand.SetSQLCommand('INSERT INTO PARAM (NOME, VALOR) VALUES(''INSERTED'', ''1'')');
  SQLCommand.Execute;

  FSUT.ParamName := 'INSERTED';
  FSUT.SystemScope := ssGlobal;

  Assert.AreEqual<string>('1', FSUT.Value);

  SQLCommand := FConnection.CreateStatement;
  SQLCommand.SetSQLCommand('UPDATE PARAM SET VALOR = ''2'' where NOME = ''INSERTED''');
  SQLCommand.Execute;

  Assert.AreEqual<string>('2', FSUT.Value, 'Wrong value ');
end;

procedure TAureliusParamItemTests.GetValue_ParamUpdatedDirectlyOnDatabase_ValueFromDatabaseReturned;
var
  SQLCommand: IDBStatement;
begin
  FSUT.ParamName := 'DirectRead';
  FSUT.SystemScope := ssGlobal;

  FSUT.Value := 'GlobalValue';

  SQLCommand := FConnection.CreateStatement;
  SQLCommand.SetSQLCommand('UPDATE PARAM SET VALOR = ''UpdatedValue'' where NOME = ''DirectRead''');
  SQLCommand.Execute;

  Assert.AreEqual<string>('UpdatedValue', FSUT.Value, 'Wrong value ');
end;

procedure TAureliusParamItemTests.SetValue_CompanyParam_ValueStoredInDB;
var
  Param: TParam;
begin
  FSUT.ParamName := 'SetCompanyParam';
  FSUT.SystemScope := ssCompany;
  FParamManager.CompanyID := 'CorrectCompany';
  FSUT.Value := 'CompanyValue';

  Param := FObjectManager.Find<TParam>.Add(
      TLinq.Eq('Nome', FSUT.ParamName) and TLinq.Eq('Empresa', FParamManager.CompanyID) and TLinq.IsNull('Usuario')
    ).UniqueResult;

  Assert.AreEqual('CompanyValue', Param.Valor.Value, 'Wrong value');
  Assert.AreEqual(FSUT.ParamName, Param.Nome, 'Wrong param');
  Assert.AreEqual('CorrectCompany', Param.Empresa.Value, 'Wrong company');
  Assert.IsFalse(Param.Usuario.HasValue, 'Wrong user');
end;

procedure TAureliusParamItemTests.SetValue_ExistingParam_ValueUpdatedInDB;
var
  Param: TParam;
begin
  FSUT.ParamName := 'SetGlobalParam';
  FSUT.SystemScope := ssGlobal;

  FSUT.Value := 'GlobalValue';
  FSUT.Value := 'UpdatedValue';

  FObjectManager.Clear;
  Param := FObjectManager.Find<TParam>.Add(
      TLinq.Eq('Nome', FSUT.ParamName) and TLinq.IsNull('Empresa') and TLinq.IsNull('Usuario')
    ).UniqueResult;

  Assert.AreEqual<string>('UpdatedValue', Param.Valor);
  Assert.AreEqual<string>('UpdatedValue', FSUT.Value, 'Wrong value');
end;

procedure TAureliusParamItemTests.SetValue_GlobalParam_ValueStoredInDB;
var
  Param: TParam;
begin
  FSUT.ParamName := 'SetGlobalParam';
  FSUT.SystemScope := ssGlobal;

  FSUT.Value := 'GlobalValue';

  Param := FObjectManager.Find<TParam>.Add(
      TLinq.Eq('Nome', FSUT.ParamName) and TLinq.IsNull('Empresa') and TLinq.IsNull('Usuario')
    ).UniqueResult;

  Assert.AreEqual('GlobalValue', Param.Valor.Value, 'Wrong value ');
  Assert.AreEqual(FSUT.ParamName, Param.Nome, 'Wrong param');
  Assert.IsFalse(Param.Empresa.HasValue, 'Wrong company');
  Assert.IsFalse(Param.Usuario.HasValue, 'wrong user');
end;

procedure TAureliusParamItemTests.SetValue_NullValue_ValueStoredInDB;
var
  Param: TParam;
begin
  FSUT.ParamName := 'SetGlobalParam';
  FSUT.SystemScope := ssGlobal;

  FSUT.Value := Null;

  Param := FObjectManager.Find<TParam>.Add(
      TLinq.Eq('Nome', FSUT.ParamName) and TLinq.IsNull('Empresa') and TLinq.IsNull('Usuario')
    ).UniqueResult;

  Assert.IsFalse(Param.Valor.HasValue);
end;

procedure TAureliusParamItemTests.SetValue_UserCompanyParam_ValueStoredInDB;
var
  Param: TParam;
begin
  FSUT.ParamName := 'SetUserCompanyParam';
  FSUT.SystemScope := ssUserCompany;
  FParamManager.UserID := 'CorrectUser';
  FParamManager.CompanyID := 'CorrectCompany';
  FSUT.Value := 'UserValue';

  Param := FObjectManager.Find<TParam>.Add(
      TLinq.Eq('Nome', FSUT.ParamName) and TLinq.Eq('Empresa', FParamManager.CompanyID) and TLinq.Eq('Usuario', FParamManager.UserID )
    ).UniqueResult;

  Assert.AreEqual('UserValue', Param.Valor.Value, 'Wrong value');
  Assert.AreEqual(FSUT.ParamName, Param.Nome, 'Wrong param');
  Assert.AreEqual<string>('CorrectCompany', Param.Empresa, 'Wrong company');
  Assert.AreEqual<string>('CorrectUser', Param.Usuario, 'Wrong user');
end;

procedure TAureliusParamItemTests.SetValue_UserParam_ValueStoredInDB;
var
  Param: TParam;
begin
  FSUT.ParamName := 'SetUserParam';
  FSUT.SystemScope := ssUser;
  FParamManager.UserID := 'CorrectUser';
  FSUT.Value := 'UserValue';

  Param := FObjectManager.Find<TParam>.Add(
      TLinq.Eq('Nome', FSUT.ParamName) and TLinq.Eq('Usuario', FParamManager.UserID) and TLinq.IsNull('Empresa')
    ).UniqueResult;

  Assert.AreEqual('UserValue', Param.Valor.Value, 'Wrong value');
  Assert.AreEqual(FSUT.ParamName, Param.Nome, 'Wrong param');
  Assert.IsFalse(Param.Empresa.HasValue, 'Wrong company');
  Assert.AreEqual<string>('CorrectUser', Param.Usuario, 'Wrong user');
end;

initialization
  TDUnitX.RegisterTestFixture(TAureliusParamItemTests);
end.
