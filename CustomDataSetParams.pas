unit CustomDataSetParams;

interface

uses
  ParamManager,
  Data.DB,
  Datasnap.DBClient;

type
  TCustomDataSetParams = class(TCustomRemoteParams)
  public
    function CreateParamItem: TParamItem; override;
    procedure Refresh; override;
    function DataSet: TClientDataSet; virtual; abstract;
    function CompanyField: TField; virtual;
    function UserField: TField; virtual;
    function BlobField: TBlobField; virtual; abstract;
    function NameField: TField; virtual; abstract;
    function ValueField: TField; virtual; abstract;
  end;

implementation

uses
  DataSetParamItem,
  System.SysUtils;

function TCustomDataSetParams.CompanyField: TField;
begin
  Result := nil;
end;

function TCustomDataSetParams.CreateParamItem: TParamItem;
begin
  Result := TDataSetParamItem.Create(Self);
end;

procedure TCustomDataSetParams.Refresh;
begin
  if (DataSet <> nil) and DataSet.Active and (DataSet.ChangeCount = 0) then
    DataSet.Refresh;
end;

function TCustomDataSetParams.UserField: TField;
begin
  Result := nil;
end;

end.
