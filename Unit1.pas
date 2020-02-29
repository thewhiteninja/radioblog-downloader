unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, XPMan, ExtCtrls, StdCtrls, ComCtrls, StrUtils, WinInet,
  Menus, FileCtrl, Unit2, Unit3, Spin, ShellApi, HTTPGet;

const
  wm_AppelMessage = wm_user + 1;

type
  PData = ^TData;

  TData = record
    etat: integer;
    progression: integer;
    vitesse: extended;
  end;

type
  TForm1 = class(TForm)
    XPManifest1: TXPManifest;
    GroupBox1: TGroupBox;
    StatusBar1: TStatusBar;
    LabeledEdit1: TLabeledEdit;
    Button1: TButton;
    Panel1: TPanel;
    GroupBox2: TGroupBox;
    PageControl1: TPageControl;
    GroupBox3: TGroupBox;
    Button2: TButton;
    Button5: TButton;
    PopupMenu1: TPopupMenu;
    Fermer1: TMenuItem;
    outfermer1: TMenuItem;
    LabeledEdit2: TLabeledEdit;
    Button4: TButton;
    Timer1: TTimer;
    Image1: TImage;
    Label1: TLabel;
    Button3: TButton;
    Panel2: TPanel;
    Panel3: TPanel;
    UpDown1: TUpDown;
    Edit1: TEdit;
    HTTPGet1: THTTPGet;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: integer;
      var Resize: Boolean);
    procedure Button3Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure outfermer1Click(Sender: TObject);
    procedure Fermer1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure HTTPGet1DoneString(Sender: TObject; Result: string);
    procedure Button1Click(Sender: TObject);
    procedure LabeledEdit1KeyPress(Sender: TObject; var Key: Char);
    procedure Button5Click(Sender: TObject);
    procedure UpDown1Changing(Sender: TObject; var AllowChange: Boolean);
  private
    resultat: string;
    ok: Boolean;
    max: integer;
    liens: TList;
    thread: TList;
    procedure myWait;
    procedure parseResultat(list: TListView; liens: TStringList);
    procedure WMAppelMessage(var msg: TMessage); message wm_AppelMessage;
    procedure Draw(Sender: TCustomListView; Item: TListItem; Rect: TRect;
      State: TOwnerDrawState);
    procedure OnMinimize(Sender: TObject);
  public
    nb_dl: integer;
    nb_fini: integer;
    nb_attente: integer;
    c0, c1, bar, barOK, bar404, barErr: TBitmap;
  end;

var
  Form1: TForm1;
  Tray: TNotifyIconData;

implementation

const
  rb_Search_Url = 'http://www.radioblogclub.fr/search/';

const
  Key = '657ecb3231ac0b275497d4d6f00b61a1';

const
  url_Marker = 'BlogThisTrack.start';

{$R *.dfm}
{$R Ressources.res}

function DetectionConnexion: Boolean;
var
  dwFlags: DWord;
begin
  dwFlags := INTERNET_CONNECTION_MODEM or INTERNET_CONNECTION_LAN or
    INTERNET_CONNECTION_PROXY;
  Result := InternetGetConnectedState(@dwFlags, 0);
end;

function droite(substr: string; s: string): string;
begin
  if pos(substr, s) = 0 then
    Result := ''
  else
    Result := copy(s, pos(substr, s) + length(substr),
      length(s) - pos(substr, s) + length(substr));
end;

function droiteDroite(substr: string; s: string): string;
begin
  repeat
    s := droite(substr, s);
  until pos(substr, s) = 0;
  Result := s;
end;

procedure myRepaint(i: TListItem);
begin
  i.SubItems[0] := '';
  i.SubItems[1] := '';
end;

procedure TForm1.OnMinimize(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
  if Application.MainForm <> nil then
    Application.MainForm.Visible := false
  else
    Application.ShowMainForm := false;;
end;

procedure TForm1.WMAppelMessage(var msg: TMessage);
begin
  if ((msg.LParam = Wm_LButtonDown) or (msg.LParam = WM_LButtonDblClk)) then
  begin
    Form1.Visible := not Form1.Visible;
    if Form1.Visible then
    begin
      Application.Restore;
      SetForegroundWindow(Handle);
    end;
  end;
end;

procedure TForm1.parseResultat(list: TListView; liens: TStringList);
var
  p, f, prev_p: integer;
  s, t: string;
  Item: TListItem;
  data: PData;
begin
  prev_p := 1;
  repeat
  begin
    p := PosEx(url_Marker, resultat, prev_p);
    if (p > 0) then
    begin
      f := PosEx(''')', resultat, p);
      s := copy(resultat, p + 21, f - p - 21);
      liens.Add(s);
      t := droiteDroite('/', s);
      t := ReplaceText(t, '%2520', ' ');
      t := ReplaceText(t, '%2528', '(');
      t := ReplaceText(t, '%2529', ')');
      t := ReplaceText(t, '%255B', '[');
      t := ReplaceText(t, '%255D', ']');
      t := ReplaceText(t, '%2527', '''');
      t := ReplaceText(t, '%253E', '>');
      t := ReplaceText(t, '%25E8', 'è');
      t := ReplaceText(t, '%252C', ',');
      t := ReplaceText(t, '%257E', '~');
      t := ReplaceText(t, '%2526', '&');
      t := ReplaceText(t, '%25E9', 'é');
      Item := list.Items.Add;
      Item.data := nil;
      Item.StateIndex := 0;
      Item.Caption := t;
      Item.SubItems.Add('');
      Item.SubItems.Add('');
      new(data);
      with data^ do
      begin
        Item.data := Pointer(data);
        etat := 0;
        progression := 0;
        vitesse := 0;
      end;
      prev_p := f;
    end;
  end;
  until (p = 0);
end;

procedure TForm1.myWait;
begin
  while (not ok) do
    Application.ProcessMessages;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  with TForm3.Create(nil) do
  begin
    case ShowModal of
      mrCancel:
        MessageBox(Handle, pchar('Bien joué ! (je crois :))'), pchar('Infos'),
          MB_ICONINFORMATION);
    end;
    Free;
  end;
end;

procedure TForm1.LabeledEdit1KeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then
  begin
    Key := #0;
    Button1Click(nil);
  end;
end;

procedure TForm1.Draw(Sender: TCustomListView; Item: TListItem; Rect: TRect;
  State: TOwnerDrawState);
var
  r1, r2, r3, p: TRect;
begin
  r1 := Rect;
  r1.Right := r1.Left + Sender.Column[0].Width;
  r2 := Rect;
  r2.Left := r1.Right;
  r2.Right := r1.Right + Sender.Column[1].Width;
  r3 := Rect;
  r3.Left := r2.Right;

  if Item.Selected then
  begin
    Sender.Canvas.Brush.Color := clGreen;
    Sender.Canvas.Font.Color := clWhite;
  end
  else
  begin
    Sender.Canvas.Brush.Color := clWhite;
    Sender.Canvas.Font.Color := clBlack;
  end;

  Sender.Canvas.Brush.Style := bsSolid;
  Sender.Canvas.TextRect(r1, r1.Left + 17, r1.Top, Item.Caption);

  if Item.Selected then
  begin
    Sender.Canvas.Draw(r1.Left + 1, r1.Top, c1);
  end
  else
  begin
    Sender.Canvas.Draw(r1.Left + 1, r1.Top, c0);
  end;

  if (Item.data <> nil) then
  begin
    p := r3;
    p.Right := r3.Left + PData(Item.data)^.progression *
      (r3.Right - r3.Left) div 100;

    case PData(Item.data)^.etat of
      1:
        begin
          DrawText(Sender.Canvas.Handle, pchar('En attente'),
            StrLen(pchar('En attente')), r3, DT_CENTER or DT_SINGLELINE);
        end;
      2:
        begin
          Sender.Canvas.StretchDraw(p, bar);
          Sender.Canvas.Brush.Style := bsClear;
          Sender.Canvas.Font.Color := clBlack;
          DrawText(Sender.Canvas.Handle,
            pchar(IntToStr(PData(Item.data)^.progression) + ' %'),
            StrLen(pchar(IntToStr(PData(Item.data)^.progression) + ' %')), r3,
            DT_CENTER or DT_SINGLELINE);
          DrawText(Sender.Canvas.Handle,
            pchar(FormatFloat('##.##', PData(Item.data)^.vitesse)),
            StrLen(pchar(FormatFloat('##.##', PData(Item.data)^.vitesse))), r2,
            DT_CENTER or DT_SINGLELINE);
        end;
      3:
        begin
          Sender.Canvas.StretchDraw(r3, barOK);
        end;
      4:
        begin
          Sender.Canvas.StretchDraw(r3, bar404);;
        end;
      5:
        begin
          Sender.Canvas.StretchDraw(r3, barErr);
        end;
    end;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  req: string;
  depart, prev_item: integer;
  tbs: TTabSheet;
  list: TListView;
  col: TListColumn;
begin
  HTTPGet1.Abort;
  if LabeledEdit1.Text = '' then
    LabeledEdit1.SetFocus;
  if ((LabeledEdit1.Text <> '') and (DetectionConnexion)) then
  begin
    tbs := TTabSheet.Create(Self);
    with tbs do
    begin
      Caption := LabeledEdit1.Text;
      PageControl := PageControl1;
      Parent := PageControl1;
    end;
    list := TListView.Create(Self);
    with list do
    begin
      Align := alClient;
      Parent := tbs;
      MultiSelect := true;
      GridLines := true;
      ViewStyle := vsReport;
      col := Columns.Add;
      col.Caption := 'Titre';
      col.AutoSize := false;
      col.MinWidth := 10;
      col.MaxWidth := 1000;
      col.Width := 62 * Width div 100 - 20;
      col := Columns.Add;
      col.Caption := 'Vitesse (Ko/s)';
      col.AutoSize := false;
      col.Width := 15 * Width div 100;
      col.MinWidth := col.Width;
      col.MaxWidth := col.Width;
      col.Alignment := taCenter;
      col := Columns.Add;
      col.Caption := 'Progression';
      col.AutoSize := false;
      col.Width := 20 * Width div 100;
      col.MinWidth := col.Width;
      col.MaxWidth := col.Width;
      col.Alignment := taCenter;
      OwnerDraw := true;
      OnDrawItem := Draw;
    end;
    PageControl1.ActivePageIndex := PageControl1.PageCount - 1;
    tbs.Tag := list.Handle;

    liens.Add(TStringList.Create);

    depart := 0;
    StatusBar1.Panels[0].Text := 'Recherche de "' + LabeledEdit1.Text + '" ...';
    repeat
    begin
      prev_item := list.Items.Count;
      req := rb_Search_Url + IntToStr(depart) + '/' +
        ReplaceText(LabeledEdit1.Text, ' ', '_');
      with HTTPGet1 do
      begin
        URL := req;
        BinaryData := false;
        ok := false;
        GetString;
      end;
      myWait;
      parseResultat(list, liens[liens.Count - 1]);
      tbs.Caption := LabeledEdit1.Text + ' (' + IntToStr(list.Items.Count) +
        ' résultats)';
      depart := depart + 50;
    end;
    until list.Items.Count = prev_item;
    LabeledEdit1.Text := '';
    StatusBar1.Panels[0].Text := '';
  end;
end;

procedure TForm1.HTTPGet1DoneString(Sender: TObject; Result: string);
begin
  resultat := Result;
  ok := true;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Width := Screen.WorkAreaWidth div 2;
  Height := Screen.WorkAreaHeight div 2;
  DoubleBuffered := true;
  liens := TList.Create;
  thread := TList.Create;
  c0 := TBitmap.Create;
  c1 := TBitmap.Create;
  bar := TBitmap.Create;
  barOK := TBitmap.Create;
  bar404 := TBitmap.Create;
  barErr := TBitmap.Create;
  c0.LoadFromResourceName(hInstance, 'nocheck');
  c1.LoadFromResourceName(hInstance, 'check');
  bar.LoadFromResourceName(hInstance, 'progress');
  barOK.LoadFromResourceName(hInstance, 'ok');
  bar404.LoadFromResourceName(hInstance, 'notfound');
  barErr.LoadFromResourceName(hInstance, 'error');
  LabeledEdit2.Text := ExtractFileDir(Application.ExeName);
  Tray.cbSize := SizeOf(Tray);
  Tray.wnd := Handle;
  Tray.uID := 1;
  Tray.UCallbackMessage := wm_AppelMessage;
  Tray.hIcon := Application.Icon.Handle;
  Tray.szTip := 'RadioBlog Downloader';
  Tray.uFlags := nif_message or nif_icon or nif_tip;
  Shell_NotifyIcon(Nim_ADD, @Tray);
  Application.OnMinimize := OnMinimize;
  resultat := '';
  ok := true;
  nb_dl := 0;
  nb_fini := 0;
  nb_attente := 0;
  Form1.Icon := Application.Icon;
  Randomize;
  max := 4;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  liens.Clear;
  liens.Free;
  thread.Clear;
  thread.Free;
  Shell_NotifyIcon(Nim_DELETE, @Tray);
  CanClose := true;
end;

{ procedure TForm1.Button3Click(Sender: TObject);
  var list: TListView;
  i: integer;
  tous: boolean;
  begin
  if PageControl1.ActivePageIndex <> -1 then
  begin
  tous := true;
  list := TListView(FindControl(PageControl1.ActivePage.Tag));
  for i := 0 to list.Items.Count - 1 do
  begin
  if not list.Items[i].Checked then tous := false;
  break;
  end;
  for i := 0 to list.Items.Count - 1 do list.Items[i].Checked := not tous;
  end;
  end; }

procedure TForm1.Fermer1Click(Sender: TObject);
var
  list: TListView;
  page: TTabSheet;
  i: integer;
  delete: Boolean;
begin
  if PageControl1.ActivePageIndex <> -1 then
  begin
    delete := true;
    list := TListView(FindControl(PageControl1.ActivePage.Tag));
    for i := 0 to list.Items.Count - 1 do
    begin
      if ((list.Items[i].StateIndex = 1) or (list.Items[i].StateIndex = 2)) then
      begin
        delete := false;
        break;
      end;
    end;
    if delete then
    begin
      list.Clear;
      list.Free;
      liens.delete(PageControl1.ActivePageIndex);
      page := PageControl1.ActivePage;
      page.Parent := nil;
      page.Free;
    end;
  end;
end;

procedure TForm1.outfermer1Click(Sender: TObject);
var
  list: TListView;
  page: TTabSheet;
  i, o: integer;
  delete: Boolean;
begin
  for i := PageControl1.PageCount - 1 downto 0 do
  begin
    delete := true;
    list := TListView(FindControl(PageControl1.Pages[i].Tag));
    for o := 0 to list.Items.Count - 1 do
    begin
      if ((list.Items[o].StateIndex = 1) or (list.Items[o].StateIndex = 2)) then
      begin
        delete := false;
        break;
      end;
    end;
    if delete then
    begin
      list.Clear;
      list.Free;
      liens.delete(i);
      page := PageControl1.Pages[i];
      page.Parent := nil;
      page.Free;
    end;
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  p: string;
begin
  if SelectDirectory('Choisir le dossier où seront téléchargés les mp3 :', '', p)
  then
    LabeledEdit2.Text := p;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  list: TListView;
  i: integer;
  dl: Boolean;
begin
  dl := false;
  if PageControl1.ActivePageIndex <> -1 then
  begin
    list := TListView(FindControl(PageControl1.ActivePage.Tag));
    for i := 0 to list.Items.Count - 1 do
    begin
      if ((list.Items[i].Selected) and (PData(list.Items[i].data)^.etat = 0))
      then
      begin
        list.Items[i].Selected := false;
        PData(list.Items[i].data)^.etat := 1;
        inc(nb_attente);
        dl := true;
      end;
    end;
    if dl then
      Timer1.Enabled := true;
    StatusBar1.Panels[1].Text := IntToStr(nb_attente) + '/' + IntToStr(nb_dl) +
      '/' + IntToStr(nb_fini);
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  list: TListView;
  i, o: integer;
begin
  if nb_dl < max then
  begin
    for o := 0 to PageControl1.PageCount - 1 do
    begin
      if nb_dl < max then
      begin
        list := TListView(FindControl(PageControl1.Pages[o].Tag));

        for i := 0 to list.Items.Count - 1 do
        begin
          if ((nb_dl < max) and (PData(list.Items[i].data)^.etat = 1)) then
          begin
            PData(list.Items[i].data)^.etat := 2;
            list.Items[i].Selected := false;
            StatusBar1.Panels[0].Text := 'Téléchargement de ' + list.Items
              [i].Caption;
            thread.Add(DLThread.Create(true));
            with DLThread(thread.Items[thread.Count - 1]) do
            begin
              FreeOnTerminate := true;
              uri := TStringList(liens.Items[o])[i] + '&k=' + Key;
              fichier := LabeledEdit2.Text + '\' + list.Items[i].Caption;
              index := i;
              hand := list.Handle;
              Resume;
            end;
            inc(nb_dl);
            dec(nb_attente);
            StatusBar1.Panels[1].Text := IntToStr(nb_attente) + '/' +
              IntToStr(nb_dl) + '/' + IntToStr(nb_fini);
          end;
        end;
      end;
    end;
  end;
end;

procedure TForm1.UpDown1Changing(Sender: TObject; var AllowChange: Boolean);
begin
  Edit1.Text := IntToStr(UpDown1.Position);
  max := UpDown1.Position;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  list: TListView;
  i: integer;
  o: integer;
begin
  if PageControl1.ActivePageIndex <> -1 then
  begin
    list := TListView(FindControl(PageControl1.ActivePage.Tag));
    for i := 0 to list.Items.Count - 1 do
    begin
      if ((list.Items[i].Selected) and (PData(list.Items[i].data)^.etat <= 2))
      then
      begin
        if (PData(list.Items[i].data)^.etat = 1) then
        begin
          list.Items[i].Selected := false;
          PData(list.Items[i].data)^.etat := 0;
        end;
        if (PData(list.Items[i].data)^.etat = 2) then
        begin
          for o := 0 to thread.Count - 1 do
          begin
            if ((DLThread(thread.Items[o]).hand = list.Handle) and
              (DLThread(thread.Items[o]).index = i)) then
            begin
              DLThread(thread.Items[o]).stop := true;
              break;
            end;
          end;
          thread.delete(o);
          list.Items[i].Selected := false;
          PData(list.Items[i].data)^.etat := 0;
          myRepaint(list.Items[i]);
        end;
      end;
    end;
    StatusBar1.Panels[1].Text := IntToStr(nb_attente) + '/' + IntToStr(nb_dl) +
      '/' + IntToStr(nb_fini);
  end;
end;

procedure TForm1.FormCanResize(Sender: TObject;
  var NewWidth, NewHeight: integer; var Resize: Boolean);
var
  i: integer;
  list: TListView;
begin
  if ((NewWidth > 301) and (NewHeight > 383)) then
  begin
    GroupBox1.Width := NewWidth - 19;
    Panel1.Width := NewWidth - 19;
    GroupBox3.Width := NewWidth - 19;
    Button1.Left := NewWidth - 93;
    LabeledEdit1.Width := NewWidth - 103;
    LabeledEdit2.Width := NewWidth - 120;
    Button4.Left := NewWidth - 58;
    Button5.Left := NewWidth - 110;
    Button3.Left := NewWidth - 204;
    Button2.Left := NewWidth - 297;
    Panel1.Height := NewHeight - 218;
    StatusBar1.Panels[0].Width := NewWidth - 80;
    Label1.Visible := NewWidth > 471;
    Edit1.Visible := Label1.Visible;
    UpDown1.Visible := Label1.Visible;
    for i := 0 to PageControl1.PageCount - 1 do
    begin
      list := TListView(FindControl(PageControl1.Pages[i].Tag));
      if list <> nil then
      begin
        list.Columns[0].MinWidth := 10;
        list.Columns[0].MaxWidth := 1000;
        list.Columns[0].Width := 62 * Width div 100 - 20;
        list.Columns[1].Width := 15 * NewWidth div 100;
        list.Columns[1].MinWidth := list.Columns[1].Width;
        list.Columns[1].MaxWidth := list.Columns[1].Width;
        list.Columns[2].Width := 20 * NewWidth div 100;
        list.Columns[2].MinWidth := list.Columns[2].Width;
        list.Columns[2].MaxWidth := list.Columns[2].Width;
      end;
    end;
  end
  else
  begin
    if NewWidth < 302 then
      NewWidth := 302;
    if NewHeight < 384 then
      NewHeight := 384;
  end;
  Resize := true;
end;

end.
