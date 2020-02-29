unit Unit2;

interface

uses
  Windows, Classes, Controls, ExtActns, StrUtils, Dialogs, SysUtils, ComCtrls,
  Gauges, Graphics;

type
  DLThread = class(TThread)
  private
    dw: TDownLoadURL;
  protected
    procedure Execute; override;
    procedure URL_OnDownloadProgress(Sender: TDownLoadURL;
      Progress, ProgressMax: cardinal; StatusCode: TURLDownloadStatus;
      StatusText: string; var Cancel: boolean);
    procedure UpdateText;
    procedure Fin;
    procedure FixName;
    procedure Error;
    procedure Arret;
    procedure CheckExist;
  public
    uri: string;
    fichier, tmp: string;
    value, n, index, last_o, last_t, hand: cardinal;
    vit: extended;
    stop: boolean;
  end;

implementation

uses Unit1;

function TailleFichier(fichier: string): longint;
var
  SearchRec: TSearchRec;
  Resultat: integer;
begin
  Result := 0;
  Resultat := FindFirst(fichier, FaAnyFile, SearchRec);
  if Resultat = 0 then
    Result := SearchRec.Size;
  FindClose(SearchRec);
end;

procedure myRepaint(i: TListItem);
begin
  i.SubItems[0] := '';
  i.SubItems[1] := '';
end;

procedure DLThread.CheckExist;
begin
  if (FileExists(tmp)) then
  begin
    tmp := LeftStr(fichier, length(fichier) - 4) + '(' + IntToStr(n) + ')' +
      RightStr(fichier, 4);
    inc(n);
    CheckExist;
  end;
end;

procedure DLThread.FixName;
var
  ext: string;
begin
  ext := LowerCase(RightStr(fichier, 3));
  if (ext = 'rbs') then
  begin
    fichier := LeftStr(fichier, length(fichier) - 4);
    FixName;
  end
  else
  begin
    if ((ext <> 'mp3') and (ext <> 'wma') and (ext <> 'swf')) then
      fichier := fichier + '.mp3';
  end;
end;

procedure DLThread.Fin;
var
  list: TListView;
begin
  list := TListView(FindControl(hand));
  Form1.nb_dl := Form1.nb_dl - 1;
  Form1.nb_fini := Form1.nb_fini + 1;
  Form1.StatusBar1.Panels[1].Text := IntToStr(Form1.nb_attente) + '/' +
    IntToStr(Form1.nb_dl) + '/' + IntToStr(Form1.nb_fini);
  if (TailleFichier(fichier) < 10000) then
  begin
    PData(list.Items[index].Data)^.etat := 4;
    myRepaint(list.Items[index]);
    DeleteFile(fichier);
    Form1.StatusBar1.Panels[0].Text := '"' + ExtractFileName(fichier) +
      '" n''existe plus';
  end
  else
  begin
    PData(list.Items[index].Data)^.etat := 3;
    myRepaint(list.Items[index]);
    Form1.StatusBar1.Panels[0].Text := '"' + ExtractFileName(fichier) +
      '" terminé';
  end;
end;

procedure DLThread.UpdateText;
var
  list: TListView;
begin
  if not stop then
  begin
    list := TListView(FindControl(hand));
    PData(list.Items[index].Data)^.progression := value;
    PData(list.Items[index].Data)^.vitesse := vit;
    list.Items[index].SubItems[0] := FormatFloat('##,##', vit);
    list.Items[index].SubItems[1] := '';
  end;
end;

procedure DLThread.Arret;
begin
  DeleteFile(fichier);
end;

procedure DLThread.Error;
var
  list: TListView;
begin
  Form1.nb_fini := Form1.nb_fini + 1;
  Form1.StatusBar1.Panels[1].Text := IntToStr(Form1.nb_attente) + '/' +
    IntToStr(Form1.nb_dl) + '/' + IntToStr(Form1.nb_fini);
  list := TListView(FindControl(hand));
  PData(list.Items[index].Data)^.etat := 5;
  myRepaint(list.Items[index]);
  Form1.StatusBar1.Panels[0].Text := 'Erreur pendant le téléchargement de "' +
    ExtractFileName(fichier) + '"';
end;

procedure DLThread.URL_OnDownloadProgress(Sender: TDownLoadURL;
  Progress, ProgressMax: cardinal; StatusCode: TURLDownloadStatus;
  StatusText: string; var Cancel: boolean);
var
  s, o: extended;
begin
  if ProgressMax > 0 then
  begin
    value := (100 * Progress) div ProgressMax;
    s := (GetTickCount - last_t) / 1000;
    o := (Progress - last_o) / 1024;
    if (s > 1) then
    begin
      vit := o / s;
      last_t := GetTickCount;
      last_o := Progress;
      Synchronize(UpdateText);
    end;
  end;
  if stop then
  begin
    raise EExternalException.Create('Stoppez le navire !!!');
  end;
end;

procedure DLThread.Execute;
begin
  value := 0;
  n := 1;
  last_o := 0;
  vit := 0;
  last_t := GetTickCount;
  stop := false;
  dw := TDownLoadURL.Create(nil);
  dw.URL := uri;
  FixName;
  tmp := fichier;
  CheckExist;
  fichier := tmp;
  dw.Filename := fichier;
  dw.OnDownloadProgress := URL_OnDownloadProgress;
  try
    dw.ExecuteTarget(nil);
    Synchronize(Fin);
  except
    on EExternalException do
      Synchronize(Arret);
    on Exception do
      Synchronize(Error);
  end;
  dw.Free;
end;

end.
