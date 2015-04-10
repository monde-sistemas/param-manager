unit CustomAureliusParamsTests;

interface

uses
  DUnitX.TestFramework,
  ParamManager,
  Aurelius.Drivers.SQLite,
  Aurelius.Engine.DatabaseManager;

type
  {$M+}
  [TestFixture]
  TCustomAureliusParamsTests = class(TObject)
  private
    FSUT: TParamManager;
    procedure CreateDatabase;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TeardownFixture]
    procedure TeardownFixture;
  published
    procedure RegisterParam_NoDatabase_NoExceptions;
    procedure GetSetValue_RemoteParam_ValueStoredInDB;
  end;

implementation

uses
  CustomAureliusParams,
  Aurelius.Engine.ObjectManager,
  SysUtils,
  System.Variants,
  Aurelius.Drivers.Interfaces;

const
  Databasename = 'data.db';

type
  TAureliusParams = class(TCustomAureliusParams)
  protected
    function CreateObjectManager: TObjectManager; override;
  end;

procedure TCustomAureliusParamsTests.CreateDatabase;
var
  DBManager: TDatabaseManager;
begin
  DBManager := TDatabaseManager.Create(TSQLiteNativeConnectionAdapter.Create(DatabaseName));
  try
      DBManager.BuildDatabase;
  finally
    DBManager.Free;
  end;
end;

procedure TCustomAureliusParamsTests.Setup;
begin
  FSUT.RemoteParamsClass := TAureliusParams;
  FSUT := TParamManager.Create;
end;

procedure TCustomAureliusParamsTests.GetSetValue_RemoteParam_ValueStoredInDB;
begin
  FSUT.RegisterParam('SetValue', Null, ssGlobal, psRemote);

  CreateDatabase;

  FSUT['SetValue'] := 'NewValue';

  Assert.AreEqual<string>('NewValue', FSUT['SetValue']);
end;

procedure TCustomAureliusParamsTests.TearDown;
begin
  FSUT.Free;
end;

procedure TCustomAureliusParamsTests.RegisterParam_NoDatabase_NoExceptions;
begin
  FSUT.RegisterParam('Global', Null, ssGlobal, psRemote);
end;

procedure TCustomAureliusParamsTests.TeardownFixture;
begin
  DeleteFile(DatabaseName);
end;

function TAureliusParams.CreateObjectManager: TObjectManager;
begin
  Result := TObjectManager.Create(TSQLiteNativeConnectionAdapter.Create(DatabaseName));
end;

initialization
  TDUnitX.RegisterTestFixture(TCustomAureliusParamsTests);
end.
