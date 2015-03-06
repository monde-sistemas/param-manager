unit ParamManagerThread;

interface

uses
  System.Classes,
  ParamManager;

type

  TParamManagerThread = class(TThread)
  private
    FParamKey: string;
    FParamValue: string;
    FParamManager: TParamManager;
    FIterations: Integer;
  public
    TesteOk: Boolean;
    ErrorMessage: string;
    constructor Create(ParamManager: TParamManager; ParamKey, ParamValue: string; Iterations: Integer); reintroduce;
  end;

  TParamManagerGetValueThread = class(TParamManagerThread)
  protected
    function GetActualValue: string; virtual;
    procedure Execute; override;
  end;

  TParamManagerGetBlobAsStringThread = class(TParamManagerGetValueThread)
  protected
    function GetActualValue: string; override;
  end;

  TParamManagerValueByNameThread = class(TParamManagerGetValueThread)
  protected
    FEmpresaID: Integer;
    function GetActualValue: string; override;
  public
    constructor Create(ParamManager: TParamManager; ParamKey, ParamValue: string; EmpresaID, Iterations: Integer); reintroduce;
  end;

  TParamManagerSetValueThread = class(TParamManagerThread)
  protected
    procedure Execute; override;
    procedure SetValue; virtual;
  end;

  TParamManagerSetBlogAsStringThread = class(TParamManagerSetValueThread)
  protected
    procedure SetValue; override;
  end;

implementation

uses
  System.SysUtils;

{ TParamManagerThread }

constructor TParamManagerThread.Create(ParamManager: TParamManager; ParamKey, ParamValue: string; Iterations: Integer);
begin
  inherited Create(true);
  FParamManager := ParamManager;
  FParamKey := ParamKey;
  FParamValue := ParamValue;
  FIterations := Iterations;
end;

{ TParamManagerGetValueThread }

procedure TParamManagerGetValueThread.Execute;
var
  ActualValue: string;
  I: Integer;
begin
  try
    for I := 1 to FIterations do
    begin
      ActualValue := GetActualValue;

      if ActualValue <> FParamValue then
      begin
        TesteOk := False;
        ErrorMessage := 'Expected:' + FParamValue + ' Actual:' + ActualValue;
        Exit;
      end;
    end;

    TesteOk := true;
  except
    on E: Exception do
    begin
      TesteOk := False;
      ErrorMessage := E.Message;
    end;
  end;
end;

function TParamManagerGetValueThread.GetActualValue: String;
begin
  Result := FParamManager[FParamKey];
end;

{ TParamManagerSetValueThread }

procedure TParamManagerSetValueThread.Execute;
var
  I: Integer;
begin
  try
    for I := 1 to FIterations do
      SetValue;

    TesteOk := true;
  except
    on E: Exception do
    begin
      TesteOk := False;
      ErrorMessage := E.Message;
    end;
  end;
end;

procedure TParamManagerSetValueThread.SetValue;
begin
  FParamManager[FParamKey] := FParamValue;
end;

{ TParamManagerValueByNameThread }

constructor TParamManagerValueByNameThread.Create(ParamManager: TParamManager; ParamKey, ParamValue: string; EmpresaID,
  Iterations: Integer);
begin
  inherited Create(ParamManager, ParamKey, ParamValue, Iterations);
  FEmpresaID := EmpresaID;
end;

function TParamManagerValueByNameThread.GetActualValue: String;
begin
  Result := FParamManager.ParamByName(FParamKey).ValueByCompany(FEmpresaID);
end;

function TParamManagerGetBlobAsStringThread.GetActualValue: string;
begin
  Result := FParamManager.ParamByName(FParamKey).BlobAsString
end;

{ TParamManagerSetBlogAsStringThread }

procedure TParamManagerSetBlogAsStringThread.SetValue;
begin
  FParamManager.ParamByName(FParamKey).BlobAsString := FParamValue;
end;

end.
