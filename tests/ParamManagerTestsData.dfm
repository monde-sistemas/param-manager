object DmParamManagerTests: TDmParamManagerTests
  OldCreateOrder = False
  Height = 103
  Width = 95
  object cds: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 32
    Top = 32
    object cdsNOME: TWideStringField
      FieldName = 'NOME'
      Size = 30
    end
    object cdsEMPRESA_ID: TWideStringField
      FieldName = 'EMPRESA_ID'
      FixedChar = True
      Size = 38
    end
    object cdsUSUARIO_ID: TWideStringField
      FieldName = 'USUARIO_ID'
      FixedChar = True
      Size = 38
    end
    object cdsVALOR: TWideStringField
      FieldName = 'VALOR'
      Size = 1000
    end
    object cdsDADOS: TBlobField
      FieldName = 'DADOS'
    end
  end
end
