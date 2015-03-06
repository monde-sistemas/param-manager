# param-manager

Parameters manager library for Delphi applications.

ParamManager is class which can be used as singleton to store and read configuration params. It supports values as string and integer and can store values as blobs in a database.

It can be used with DataSets and [TMS Aurelius](http://www.tmssoftware.com/site/aurelius.asp) for database (remote) persistence.

# Features

- Global, User, Company and User/Company scopes
- Local, Remote and Session Persistence
- Supports encrypted name/value params

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

