program Tests_Aurelius;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  ParamModel in '..\aurelius\ParamModel.pas',
  AureliusParamItem in '..\aurelius\AureliusParamItem.pas',
  AureliusParamItemTests in 'AureliusParamItemTests.pas',
  CustomAureliusParamsTests in 'CustomAureliusParamsTests.pas',
  CustomAureliusParams in '..\aurelius\CustomAureliusParams.pas',
  DUnitXTestRunner in 'DUnitXTestRunner.pas';

begin
  TDUnitXTestRunner.RunTests;
end.
