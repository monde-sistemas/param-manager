program Tests;

{$APPTYPE CONSOLE}
uses
  SysUtils,
  ParamManagerTestsData in 'ParamManagerTestsData.pas' {DmParamManagerTests: TDataModule},
  ReverseCipher in 'ReverseCipher.pas',
  LocalParamItem in '..\LocalParamItem.pas',
  CustomDataSetParams in '..\CustomDataSetParams.pas',
  ParamManagerTests in 'ParamManagerTests.pas',
  ParamManager in '..\ParamManager.pas',
  ParamManagerThread in 'ParamManagerThread.pas',
  LocalParamItemTests in 'LocalParamItemTests.pas',
  DefaultCipherTests in 'DefaultCipherTests.pas',
  DUnitXTestRunner in 'DUnitXTestRunner.pas';

begin
  TDUnitXTestRunner.RunTests;
end.
