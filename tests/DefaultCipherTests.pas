unit DefaultCipherTests;

interface

uses
  DUnitX.TestFramework,
  ParamManagerCipher;

type
  [TestFixture]
  TDefaultCipherTests = class(TObject)
  private
  public
  published
    procedure EncodeString_KeyNotSet_EParamManagerCipherKeyNotSet;
    procedure DecodeString_KeyNotSet_EParamManagerCipherKeyNotSet;
    procedure EncodeString_KeySet_StringEncoded;
    procedure DecodeString_KeySet_StringDecoded;
  end;

implementation

const
  EncryptionKey = '{6BF54BAF-7FF2-4785-808C-98664C687E26}';

procedure TDefaultCipherTests.DecodeString_KeyNotSet_EParamManagerCipherKeyNotSet;
begin
  TDefaultCipher.Key := '';

  Assert.WillRaise(
    procedure
    begin
      TDefaultCipher.EncodeString('foo');
    end, EParamManagerCipherKeyNotSet);
end;

procedure TDefaultCipherTests.DecodeString_KeySet_StringDecoded;
begin
  TDefaultCipher.Key := EncryptionKey;

  Assert.AreEqual<string>('foo', TDefaultCipher.DecodeString('ᥱ'));
end;

procedure TDefaultCipherTests.EncodeString_KeyNotSet_EParamManagerCipherKeyNotSet;
begin
  TDefaultCipher.Key := '';

  Assert.WillRaise(
    procedure
    begin
      TDefaultCipher.DecodeString('foo');
    end, EParamManagerCipherKeyNotSet);
end;

procedure TDefaultCipherTests.EncodeString_KeySet_StringEncoded;
begin
  TDefaultCipher.Key := EncryptionKey;

  Assert.AreEqual<string>('ᥱ', TDefaultCipher.EncodeString('foo'));
end;

initialization
  TDUnitX.RegisterTestFixture(TDefaultCipherTests);
end.
