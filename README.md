# param-manager

Parameters manager library for Delphi applications.

ParamManager is class which can be used as singleton to store and read configuration params. It supports values as string and integer and can store values as blobs in a database.

It can be used with DataSets and [TMS Aurelius](http://www.tmssoftware.com/site/aurelius.asp) for database (remote) persistence.

# Features

- Global, User, Company and User/Company scopes
- Local, Remote and Session Persistence
- Supports encrypted name/value params
- Thread safe

# Usage

The usage is very straightforward, first you must register the param, informing its name, default value, system scope and persistence scope, then you can read and write values either getting the param object from the param manager instance and using its methods like `Value`, `AsInteger`, `BlobAsString`, etc or using the default acessor property: `GetParamManager['MyParamName']`.

## Register params

You must register the param in the `TParamManager` instance before reading or writing values to it.

It is usually done in the `initialization` section, but it can be anywhere you like providing that you register the param before reading or writing to it.

```Delphi
initialization
  GetParamManager.RegisterParam('MyRemoteGlobalParam', 'DefaultValue', ssGlobal, psRemote);
  GetParamManager.RegisterParam('MyLocalParam', 'DefaultValue', ssGlobal, psLocal);
  GetParamManager.RegisterParam('MySessionParam', 'DefaultValue', ssGlobal, psLocal);
  GetParamManager.RegisterParam('MyUserSpecificParam', 'DefaultValue', ssUser, psRemote);
```

### Scopes

The param scope when register will dictate how the param values are separated between users or companies.

**ssGlobal**

Every user in every company can read and write it's value. In the database the param will be stored like this:
```
Name|User|Company|Value
P1  |NULL|NULL   |A
```
**ssUser**

This scope separates the values between users using the `GetParamManager.UserID` property value. So if `UserID = '1'` and you set a value to the param, this value will only be available when the `UserID` is `1`. In the database, the param will be stored like this:
```
Name|User|Company|Value
P1  |1   |NULL   |B
```
**ssCompany**

This scope separates the values between companies using the `GetParamManager.CompanyID` property value. So if `CompanyID = 'A'` and you set a value to the param, this value will only be available when the `CompanyID` is `A`. In the database, the param will be stored like this:
```
Name|User|Company|Value
P1  |NULL|A      |B
```
**ssUserCompany**

This scope separates the values between users and company using both the `GetParamManager.UserID` and `GetParamManager.CompanyID` properties. So if `UserID = '1'` and `CompanyID = 'A'` and you set a value to the param, this value will only be available the `UserID` is `1` and the `CompanyID is `A`.In the database, the param will be stored like this:
```
Name|User|CompanyID|Value
P1  |1   |A        |B
```
## Modify param value

To modify the value you can get the `TParamItem` object or use the default acessor property, some examples:

```Delphi
  GetParamManager['MyParamName'] := 'NewValue';
  GetParamManager.ParamByName('MyParamName').Value := 'Newvalue';
  GetParamManager.ParamByName('MyParamName').AsInteger := 1;
  
  // This value will be stored in a blob field, istead of the default string field.
  GetParamManager.ParamByName('MyParamName').BlobAsString := 'New string'; 
```

## Read param value

```Delphi
  Value := GetParamManager['MyParamName']
  Value := GetParamManager.ParamByName('MyParamName').Value;
  IntegerValue := GetParamManager.ParamByName('MyParamName').AsInteger;
  
  // This will read the value from the blob field instead of the default string field
  Value := GetParamManager.ParamByName('MyParamName').BlobAsString; 
```

## Encripted params

To encrypt the stored param key and value in the database or ini files, just register the param with the `peEncryptionOn` option:

```Delphi
  GetParamManager.RegisterParam('Encrypted', 'DefaultValue', ssGlobal, psRemote, peEncryptionOn);
```

The read/write to these params is transparent to the application so when you read its value in the application it will be returned unencrypted, use it like any other param.

The stored encrypted param would look like this in an ini file:

```Ini
[Params]
Çª®”¥‘³‹«›šš=Ü©®›¡
```

There is a `TDefaultCipher` class which implements a basic encryption algorithm, to use it, just configure the encryption key:

```Delphi
TDefaultCipher.Key := '{3B29BFAB-CC64-4963-B089-626640AA8EF2}'; // The key can be any string
```

If you want to use your own encryption algorithm, just implement a class decending from `TParamManagerCipher` and configure the Param Manager instance to use it, like this:

`GetParamManager.Cipher := 'TMyCipherClass';`

# Database (Remote) persistence

Before using remote params you must config the remote persistence, it can be either using Datasets or TMS Aurelius. You can map the fields to your database schema in the `RemoteParamsClass` that you must implemente.

Bellow an example of a recommended database schema:

```SQL
/* Firebird syntax */
CREATE TABLE PARAM (
    NAME        VARCHAR(30) NOT NULL,
    VALUE       VARCHAR(1000),
    COMPANY_ID  GUID,
    USER_ID  GUID,
    DATA       BLOB SUB_TYPE 0 SEGMENT SIZE 80
);
ALTER TABLE PARAM ADD CONSTRAINT UNQ_PARAM_NOME_EMPRESA_USUARIO UNIQUE (NAME, COMPANY_ID, USER_ID);
```

## DataSets

To use the remote persistence with datasets, you must override the `TCustomDataSetParams` class and implement its `virtual; abstract;` methods to setup the fields for persistence. Then configure the `RemoteParamsClass` in the ParamManager instance.

 **Note**: You must configure the RemoteParamsClass before registering any params, so it is recommended to add the unit in the top of the `.dpr` project file.

Bellow an example implementation:

```Delphi
unit DataSetParams;

interface

uses
  CustomDataSetParams,
  ParamDataClient,
  ParamManager,
  Data.DB,
  Datasnap.DBClient;

type
  TDataSetParams = class(TCustomDataSetParams)
  private
    FParams: TDmParamClient; // DataModule where the dataset is located
  public
    destructor Destroy; override;
    function DataSet: TClientDataSet; override;
    function CompanyField: TField; override;
    function UserField: TField; override;
    function BlobField: TBlobField; override;
    function NameField: TField; override;
    function ValueField: TField; override;
    procedure Open; override;
  end;

implementation

destructor TDataSetParams.Destroy;
begin
  FParams.Free;
  inherited;
end;

function TDataSetParams.BlobField: TBlobField;
begin
  Result := FParams.cdsParamDATA;
end;

function TDataSetParams.CompanyField: TField;
begin
  Result := FParams.cdsParamCOMPANY_ID; // Required for company scoped params
end;

function TDataSetParams.DataSet: TClientDataSet;
begin
  Result := FParams.cdsParam;
end;

function TDataSetParams.NameField: TField;
begin
  Result := FParams.cdsParamNAME;
end;

procedure TDataSetParams.Open;
begin
  inherited;
  if FParams = nil then
    FParams := TDmParamClient.Create(nil);

  FParams.cdsParam.Open;
end;

function TDataSetParams.UserField: TField;
begin
  Result := FParams.cdsParamUSER_ID; //Required for company scoped params
end;

function TDataSetParams.ValueField: TField;
begin
  Result := FParams.cdsParamVALUE;
end;

initialization
  // Configures which class to use for persistence 
  TParamManager.RemoteParamsClass := TDataSetParams;

end.
```
