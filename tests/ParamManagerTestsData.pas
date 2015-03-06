unit ParamManagerTestsData;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  Datasnap.DBClient;

type
  TDmParamManagerTests = class(TDataModule)
    cds: TClientDataSet;
    cdsNOME: TWideStringField;
    cdsEMPRESA_ID: TWideStringField;
    cdsUSUARIO_ID: TWideStringField;
    cdsVALOR: TWideStringField;
    cdsDADOS: TBlobField;
  end;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

end.
