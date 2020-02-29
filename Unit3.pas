unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Gauges, jpeg;

type
  TForm3 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Gauge1: TGauge;
    Gauge2: TGauge;
    Gauge3: TGauge;
    Gauge4: TGauge;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Image1: TImage;
    Shape1: TShape;
    Label1: TLabel;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button2Enter(Sender: TObject);
    procedure Button2MouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure FormCreate(Sender: TObject);
  private
    procedure Move;
  public
    c: Boolean;
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

procedure TForm3.Move;
begin
  Button2.Left := Random(Width - 5 - Button2.Width) + 5;
  Button2.Top := Random(Height - 5 - 2 * Button2.Height) + 5;
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  Gauge1.Progress := Random(100);
  c := false;
end;

procedure TForm3.Button2MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  Move;
end;

procedure TForm3.Button2Enter(Sender: TObject);
begin
  Button1.SetFocus;
end;

procedure TForm3.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  ModalResult := mrOk;
  CanClose := true;
end;

procedure TForm3.Button1Click(Sender: TObject);
begin
  c := true;
end;

procedure Pause(const nDuree: Cardinal);
var
  Tc: Cardinal;
begin
  Tc := GetTickCount;
  repeat
    Application.ProcessMessages;
    Sleep(1);
  until Cardinal(GetTickCount - Tc) > nDuree;
end;

procedure TForm3.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  Perform(WM_SysCommand, SC_MOVE, 0);
end;

end.
