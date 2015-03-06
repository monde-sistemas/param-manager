unit CustomAureliusParams;

interface

uses
  ParamManager,
  AureliusParamItem,
  Aurelius.Engine.ObjectManager;

type
  TCustomAureliusParams = class(TCustomRemoteParams)
  private
    FObjectManager: TObjectManager;
  protected
    function CreateObjectManager: TObjectManager; virtual; abstract;
  public
    function CreateParamItem: TParamItem; override;
    destructor Destroy; override;
    constructor Create(ParamManager: TParamManager); override;
  end;

implementation

constructor TCustomAureliusParams.Create(ParamManager: TParamManager);
begin
  inherited;
  FObjectManager := CreateObjectManager;
end;

function TCustomAureliusParams.CreateParamItem: TParamItem;
begin
  Result := TAureliusParamItem.Create(ParamManager, FObjectManager);
end;

destructor TCustomAureliusParams.Destroy;
begin
  FObjectManager.Free;
  inherited;
end;

end.
