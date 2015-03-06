unit LocalParamItemTests;

interface

uses
  DUnitX.TestFramework,
  LocalParamItem,
  ParamManager;

type
  [TestFixture]
  TLocalParamItemTests = class(TObject)
  private
    FSUT: TLocalParamItem;
    FParamManager: TParamManager;
    function CompanyFolderPath: string;
    function ParamsDirectory: string;
    procedure RemoverPastas;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  published
    procedure WriteParam_AppDataCompanyFolderSpecified_IniCreatedOnCorrectFolder;
  end;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.IOUtils,
  System.Types;

const
  CompanyFolder = 'TestCompany';

function TLocalParamItemTests.CompanyFolderPath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) +
   IncludeTrailingPathDelimiter(CompanyFolder);
end;

function TLocalParamItemTests.ParamsDirectory: string;
begin
  Result := CompanyFolderPath +
    IncludeTrailingPathDelimiter(ChangeFileExt(ExtractFileName(ParamStr(0)), ''));
end;

procedure TLocalParamItemTests.RemoverPastas;
var
  Dir: string;
  IniFile: string;
begin
  if TDirectory.Exists(CompanyFolderPath) then
  begin
    for dir in TDirectory.GetDirectories(CompanyFolderPath) do
    begin
      for IniFile in TDirectory.GetFiles(dir, '*.ini') do
        DeleteFile(IniFile);
      TDirectory.Delete(dir);
    end;
    TDirectory.Delete(CompanyFolderPath);
  end;
end;

procedure TLocalParamItemTests.Setup;
begin
  FParamManager := TParamManager.Create;
  FSUT := TLocalParamItem.Create(FParamManager);
end;

procedure TLocalParamItemTests.TearDown;
begin
  RemoverPastas;

  FParamManager.Free;
  FSUT.Free;
end;

procedure TLocalParamItemTests.WriteParam_AppDataCompanyFolderSpecified_IniCreatedOnCorrectFolder;
begin
  FParamManager.AppDataCompanyFolder := CompanyFolder;

  FSUT.ParamName := 'Test';
  FSUT.Value := 'Value';

  Assert.IsTrue(DirectoryExists(CompanyFolderPath));
  Assert.IsTrue(DirectoryExists(ParamsDirectory));
  Assert.IsTrue(FileExists(ParamsDirectory + 'Params.ini'));
end;

initialization
  TDUnitX.RegisterTestFixture(TLocalParamItemTests);
end.
