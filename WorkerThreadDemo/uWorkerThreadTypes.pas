unit uWorkerThreadTypes;

interface

uses
  FMX.Forms, System.Messaging;

const
  FMXTHREADMSG_QUIT    = 1;
  FMXTHREADMSG_PROCESS = 2;

  FMXFORMMSG_RESULT    = 1;

type
  TMsgInfo = record
    Msg        : integer;
    ReceiverID : integer;
    Value      : integer;
  end;

  TCustomMessage = TMessage<TMsgInfo>;

  IMessageReceiverForm = interface
    function  GetReceiverID : integer;
    procedure HandleThreadResult(aMessageID, aData1, aData2: integer);
  end;

  TMessageReceiverForm = class(TForm, IMessageReceiverForm)
    protected
      function  GetReceiverID : integer; virtual; abstract;
    public
      procedure HandleThreadResult(aMessageID, aData1, aData2: integer); virtual; abstract;
      property ReceiverID : integer read GetReceiverID;
  end;

implementation

end.
