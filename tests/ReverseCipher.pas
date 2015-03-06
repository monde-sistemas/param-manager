unit ReverseCipher;

interface

uses
  ParamManagerCipher;

type
  TReverseCipher = class(TParamManagerCipher)
  public
    class function EncodeString(const Value: AnsiString): AnsiString; override;
    class function DecodeString(const Value: AnsiString): AnsiString; override;
  end;

implementation

uses
  System.StrUtils;

{ TReverseCipher }

class function TReverseCipher.DecodeString(
  const Value: AnsiString): AnsiString;
begin
  Result := ReverseString(Value);
end;

class function TReverseCipher.EncodeString(
  const Value: AnsiString): AnsiString;
begin
  Result := ReverseString(Value);
end;

end.
