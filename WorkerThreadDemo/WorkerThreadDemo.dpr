program WorkerThreadDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  uWorkerThreadDemo in 'uWorkerThreadDemo.pas' {WorkerThreadForm},
  uWorkerThreadTypes in 'uWorkerThreadTypes.pas',
  uWorkerThread in 'uWorkerThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TWorkerThreadForm, WorkerThreadForm);
  Application.Run;
end.
