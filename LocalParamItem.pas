unit LocalParamItem;

interface

uses
  ParamManager,
  IniFiles,
  Windows;

type
  TLocalParamItem = class(TParamItem)
  private
    function IniFilePath: string;
    procedure WriteParam(const Name, Value: string);
    function ReadParam(const Name: string): string;
  protected
    procedure CustomSetValue(const ParamName: string; Value: Variant); override;
    function CustomGetValue(const ParamName: string; CompanyID: Variant): Variant; override;
  end;

implementation

uses
  System.Variants,
  System.SysUtils;

const
  IniFileName = 'Params.ini';
  IniSectionParam = 'Params';

function TLocalParamItem.CustomGetValue(const ParamName: string; CompanyID: Variant): Variant;
begin
  Result := ReadParam(ParamName);
  if Result = '' then
    Result := DefaultValue;
end;

function TLocalParamItem.ReadParam(const Name: string): string;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(IniFilePath);
  try
    Result := Ini.ReadString(IniSectionParam, Name, '');
  finally
    Ini.Free;
  end;
end;

procedure TLocalParamItem.CustomSetValue(const ParamName: string; Value: Variant);
begin
  WriteParam(ParamName, VarToStr(Value));
end;

function TLocalParamItem.IniFilePath: string;
begin
  Result := ParamManager.AppDataFolder + IniFileName;
end;

procedure TLocalParamItem.WriteParam(const Name, Value: string);
var
  Ini: TIniFile;
begin
  ForceDirectories(ParamManager.AppDataFolder);
  Ini := TIniFile.Create(IniFilePath);
  try
    Ini.WriteString(IniSectionParam, Name, Value);
  finally
    Ini.Free;
  end;
end;

end.
