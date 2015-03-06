unit ParamModel;

interface

uses
  Aurelius.Mapping.Attributes,
  Aurelius.Types.Nullable,
  Aurelius.Types.Blob,
  Aurelius.Id.IdentifierGenerator;

type
  [Entity]
  [Automapping]
  [ID('FNome', TIdGenerator.None)]
  [ID('FUsuario', TIdGenerator.None)]
  [ID('FEmpresa', TIdGenerator.None)]
  TParam = class
  private
    FDados: Nullable<TBlob>;
    [Column('EMPRESA_ID')]
    FEmpresa: Nullable<string>;
    FNome: string;
    [Column('USUARIO_ID')]
    FUsuario: Nullable<string>;
    FValor: Nullable<string>;
  public
    property Dados: Nullable<TBlob> read FDados write FDados;
    property Empresa: Nullable<string> read FEmpresa write FEmpresa;
    property Nome: string read FNome write FNome;
    property Usuario: Nullable<string> read FUsuario write FUsuario;
    property Valor: Nullable<string> read FValor write FValor;
  end;

implementation

end.
