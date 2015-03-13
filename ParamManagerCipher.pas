unit ParamManagerCipher;

interface

uses
  System.SysUtils;

resourcestring
  StrFmtDefaultCipherKeyNotSet = 'Encription key for %s not set. Set a key value before using encripted params.';

type
  TParamManagerCipherClass = class of TParamManagerCipher;

  TParamManagerCipher = class
  public
    class function DecodeString(const Value: AnsiString): AnsiString; virtual; abstract;
    class function EncodeString(const Value: AnsiString): AnsiString; virtual; abstract;
  end;

  TDefaultCipher = class(TParamManagerCipher)
  private
    class procedure CheckKey;
  public
    class var Key: string;
    class function DecodeString(const Value: AnsiString): AnsiString; override;
    class function EncodeString(const Value: AnsiString): AnsiString; override;
  end;

  EParamManagerCipherKeyNotSet = class(Exception);

implementation

uses
  AnsiStrings;

function Trans(Ch: AnsiChar; K: Byte): AnsiChar;
begin
  Result := AnsiChar((256 + Ord(Ch) + K) mod 256);
end;

class procedure TDefaultCipher.CheckKey;
begin
  if Key = '' then
    raise EParamManagerCipherKeyNotSet.CreateFmt(StrFmtDefaultCipherKeyNotSet, [Self.ClassName]);
end;

class function TDefaultCipher.DecodeString(const Value: AnsiString): AnsiString;
var
  Tmp: PAnsiChar;

  procedure Decode(const Key: AnsiString; Buf: PAnsiChar; Size: Cardinal);
  var
    I: Cardinal;
    J: Cardinal;
  begin
    if (Key <> '') and (Size > 0) then
    begin
      J := 1;
      for I := 0 to Size - 1 do
      begin
        Buf[I] := Trans(Buf[I], -Ord(Key[J]));
        J := (J mod Cardinal(Length(Key))) + 1;
      end;
    end;
  end;

begin
  CheckKey;

  GetMem(Tmp, Length(Value) + 1);
  try
    AnsiStrings.StrPCopy(Tmp, Value);
    Decode(Key, Tmp, Length(Value));
    SetString(Result, Tmp, Length(Value));
  finally
    FreeMem(Tmp);
  end;
end;

class function TDefaultCipher.EncodeString(const Value: AnsiString): AnsiString;
var
  Tmp: PAnsiChar;

  procedure Encode(const Key: AnsiString; Buf: PAnsiChar; Size: Cardinal);
  var
    I: Cardinal;
    J: Cardinal;
  begin
    if (Key <> '') and (Size > 0) then
    begin
      J := 1;
      for I := 0 to Size - 1 do
      begin
        Buf[I] := Trans(Buf[I], Ord(Key[J]));
        J := (J mod Cardinal(Length(Key))) + 1;
      end;
    end;
  end;

begin
  CheckKey;

  GetMem(Tmp, Length(Value) + 1);
  try
    AnsiStrings.StrPCopy(Tmp, Value);
    Encode(Key, Tmp, Length(Value));
    SetString(Result, Tmp, Length(Value));
  finally
    FreeMem(Tmp);
  end;
end;

end.
