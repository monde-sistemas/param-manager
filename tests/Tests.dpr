program Tests;

{$APPTYPE CONSOLE}
uses
  SysUtils,
  DUnitX.AutoDetect.Console,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestRunner,
  DUnitX.TestFramework,
  Aurelius.Sql.SQLite,
  Aurelius.Schema.SQLite,
  ParamManagerTestsData in 'ParamManagerTestsData.pas' {DmParamManagerTests: TDataModule},
  ReverseCipher in 'ReverseCipher.pas',
  LocalParamItem in '..\LocalParamItem.pas',
  CustomDataSetParams in '..\CustomDataSetParams.pas',
  ParamManagerTests in 'ParamManagerTests.pas',
  ParamModel in '..\aurelius\ParamModel.pas',
  AureliusParamItem in '..\aurelius\AureliusParamItem.pas',
  AureliusParamItemTests in 'AureliusParamItemTests.pas',
  ParamManager in '..\ParamManager.pas',
  CustomAureliusParamsTests in 'CustomAureliusParamsTests.pas',
  CustomAureliusParams in '..\aurelius\CustomAureliusParams.pas',
  ParamManagerThread in 'ParamManagerThread.pas',
  LocalParamItemTests in 'LocalParamItemTests.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
  try
    ReportMemoryLeaksOnShutdown := True;

    //Create the runner
    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;
    //tell the runner how we will log things
    logger := TDUnitXConsoleLogger.Create(true);
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create;
    runner.AddLogger(logger);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;

    {$IFNDEF CI}
      //We don't want this happening when running under CI.
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    {$ENDIF}
  except
    on E: Exception do
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      {$IFNDEF CI}
      System.Readln;
      {$ENDIF}
    end;
  end;
end.
