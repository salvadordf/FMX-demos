unit uWorkerThreadDemo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ScrollBox,
  FMX.Memo, FMX.Edit, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts,
  uWorkerThreadTypes, uWorkerThread;

type
  TWorkerThreadForm = class(TMessageReceiverForm)
    Layout1: TLayout;
    Button1: TButton;
    Edit1: TEdit;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  protected
    FThread : TWorkerThread;
    FReceiverID : integer;
    function  GetReceiverID : integer; override;
    procedure EnqueueThreadMessage(aMsg : integer; aValue : integer = 0);
  public
    procedure HandleThreadResult(aMessageID, aData1, aData2: integer); override;
  end;

var
  WorkerThreadForm: TWorkerThreadForm;

implementation

{$R *.fmx}

procedure TWorkerThreadForm.Button1Click(Sender: TObject);
begin
  EnqueueThreadMessage(FMXTHREADMSG_PROCESS, Edit1.Text.ToInteger);
end;

procedure TWorkerThreadForm.FormCreate(Sender: TObject);
begin
  FReceiverID := 1234;
  FThread     := TWorkerThread.Create(self);
  FThread.Start;
end;

procedure TWorkerThreadForm.FormDestroy(Sender: TObject);
begin
  FThread.Terminate;
  EnqueueThreadMessage(FMXTHREADMSG_QUIT);
  FThread.WaitFor;
  FreeAndNil(FThread);
end;

procedure TWorkerThreadForm.HandleThreadResult(aMessageID, aData1, aData2: integer);
begin
  case aMessageID of
    FMXFORMMSG_RESULT :
      Memo1.Lines.Add('Received value : ' + quotedstr(aData1.ToString) + ' - Processed value : ' + quotedstr(aData2.ToString));
  end;
end;

function TWorkerThreadForm.GetReceiverID : integer;
begin
  Result := FReceiverID;
end;

procedure TWorkerThreadForm.EnqueueThreadMessage(aMsg, aValue : integer);
var
  TempMessage : TCustomMessage;
  TempInfo : TMsgInfo;
begin
  TempInfo.Msg        := aMsg;
  TempInfo.ReceiverID := GetReceiverID;
  TempInfo.Value      := aValue;

  TempMessage := TCustomMessage.Create(TempInfo);

  FThread.EnqueueMessage(TempMessage);
end;

end.
