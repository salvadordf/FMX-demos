unit uWorkerThread;

interface

uses
  System.Classes, System.SyncObjs, System.Generics.Collections, System.Messaging,
  uWorkerThreadTypes;

type
  TWorkerThread = class(TThread)
    protected
      FCritSect        : TCriticalSection;
      FEvent           : TEvent;
      FWaiting         : boolean;
      FStop            : boolean;
      FMsgQueue        : TQueue<TCustomMessage>;

      function  Lock : boolean;
      procedure Unlock;
      function  CanContinue : boolean;
      procedure ReadAllPendingMessages;
      procedure ProcessValue(const aInfo : TMsgInfo);
      function  ReadPendingMessage(var aMsgInfo : TMsgInfo) : boolean;
      procedure StopThread;
      procedure DestroyQueue;

      procedure Execute; override;

    public
      constructor Create(const aForm : IMessageReceiverForm);
      destructor  Destroy; override;
      procedure   AfterConstruction; override;
      procedure   EnqueueMessage(const aMessage : TCustomMessage);
  end;

implementation

uses
  FMX.Forms, System.SysUtils;

constructor TWorkerThread.Create(const aForm : IMessageReceiverForm);
begin
  FCritSect        := nil;
  FWaiting         := False;
  FStop            := False;
  FEvent           := nil;
  FMsgQueue        := nil;

  inherited Create(True);

  FreeOnTerminate := False;
end;

destructor TWorkerThread.Destroy;
begin
  if (FEvent    <> nil) then FreeAndNil(FEvent);
  if (FCritSect <> nil) then FreeAndNil(FCritSect);

  DestroyQueue;

  inherited Destroy;
end;

procedure TWorkerThread.DestroyQueue;
begin
  if (FMsgQueue <> nil) then
    begin
      while (FMsgQueue.Count > 0) do
        FMsgQueue.Dequeue.Free;

      FMsgQueue.Clear;
      FreeAndNil(FMsgQueue);
    end;
end;

procedure TWorkerThread.AfterConstruction;
begin
  inherited AfterConstruction;

  FEvent    := TEvent.Create(nil, False, False, '');
  FCritSect := TCriticalSection.Create;
  FMsgQueue := TQueue<TCustomMessage>.Create;
end;

function TWorkerThread.Lock : boolean;
begin
  if (FCritSect <> nil) then
    begin
      FCritSect.Acquire;
      Result := True;
    end
   else
    Result := False;
end;

procedure TWorkerThread.Unlock;
begin
  if (FCritSect <> nil) then FCritSect.Release;
end;

procedure TWorkerThread.StopThread;
begin
  if Lock then
    begin
      FStop := True;
      Unlock;
    end;
end;

procedure TWorkerThread.EnqueueMessage(const aMessage : TCustomMessage);
begin
  if Lock then
    try
      if (FMsgQueue <> nil) then FMsgQueue.Enqueue(aMessage);

      if FWaiting then
        begin
          FWaiting := False;
          FEvent.SetEvent;
        end;
    finally
      Unlock;
    end;
end;

function TWorkerThread.ReadPendingMessage(var aMsgInfo : TMsgInfo) : boolean;
var
  TempMessage : TCustomMessage;
begin
  Result := False;

  if Lock then
    try
      FWaiting := False;

      if (FMsgQueue <> nil) and (FMsgQueue.Count > 0) then
        begin
          TempMessage := FMsgQueue.Dequeue;
          aMsgInfo    := TempMessage.Value;
          Result      := True;
          TempMessage.Free;
        end;
    finally
      Unlock;
    end;
end;

procedure TWorkerThread.ReadAllPendingMessages;
var
  TempInfo : TMsgInfo;
begin
  while ReadPendingMessage(TempInfo) do
    case TempInfo.Msg of
      FMXTHREADMSG_QUIT :
        begin
          StopThread;
          exit;
        end;

      FMXTHREADMSG_PROCESS : ProcessValue(TempInfo);
    end;
end;

procedure TWorkerThread.ProcessValue(const aInfo : TMsgInfo);
begin
  Queue(nil, procedure
             var
               i, j : integer;
               TempForm : TMessageReceiverForm;
             begin
               i := 0;
               j := screen.FormCount;

               while (i < j) do
                 begin
                   if (screen.Forms[i] is TMessageReceiverForm) then
                     begin
                       TempForm := TMessageReceiverForm(screen.Forms[i]);
                       if (TempForm.ReceiverID = aInfo.ReceiverID) then
                         begin
                           TempForm.HandleThreadResult(FMXFORMMSG_RESULT, aInfo.Value, aInfo.Value * 2);
                           break;
                         end;
                     end;

                   inc(i);
                 end;
             end);
end;

function TWorkerThread.CanContinue : boolean;
begin
  Result := False;

  if Lock then
    try
      if not(Terminated) and not(FStop) then
        begin
          Result   := True;
          FWaiting := True;
          FEvent.ResetEvent;
        end;
    finally
      Unlock;
    end;
end;

procedure TWorkerThread.Execute;
begin
  while CanContinue do
    begin
      FEvent.WaitFor(INFINITE);
      ReadAllPendingMessages;
    end;
end;

end.
