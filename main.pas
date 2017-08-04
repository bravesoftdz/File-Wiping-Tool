unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, ListViewFilterEdit, Forms, Controls, Graphics,
  Dialogs, StdCtrls, FileCtrl, ComCtrls, wiping_tools, Windows;

type

  { TMainForm }

  TMainForm = class(TForm)
    uxWipeFreeSpace: TButton;
    FilesDialog: TOpenDialog;
    DirDialog: TSelectDirectoryDialog;
    uxAddFiles: TButton;
    uxAddDir: TButton;
    uxView: TListView;
    uxRemove: TButton;
    uxRandom: TCheckBox;
    uxOnTop: TCheckBox;
    uxClear: TButton;
    uxWipe: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FilesDialogClose(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure uxAddDirClick(Sender: TObject);
    procedure uxAddFilesClick(Sender: TObject);
    procedure uxClearClick(Sender: TObject);
    procedure uxOnTopChange(Sender: TObject);
    procedure uxRemoveClick(Sender: TObject);
    procedure uxWipeClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }
function RandomName(Len: Integer): String;
var
  PossibleChars: String;
begin
  Randomize;
  PossibleChars := '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  Result := '';
  repeat
    Result += PossibleChars[Random(Length(PossibleChars)) + 1];
  until (Length(Result) = Len);
end;
procedure TMainForm.Button1Click(Sender: TObject);
begin
  //WipePath('C:\tmp\popo.pas', dmWipeZeroes);
  //WipePath('X:\oi.txt', dmWipeZeroes);
  //WipeFreeSpace('G', wmZeroes);
  //WipeNameAndDelete('C:\x');
end;

procedure TMainForm.FilesDialogClose(Sender: TObject);
var
  i : integer;
begin
     for i := 0 to FilesDialog.Files.Count-1 do
     begin
          uxView.AddItem(FilesDialog.Files[i] , nil);
     end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MainForm.uxOnTopChange(nil);
  FilesDialog.IntfSetOption(ofAllowMultiSelect, True);
end;

procedure TMainForm.FormDropFiles(Sender: TObject;
  const FileNames: array of String);
var
F: String;
i:integer;
JahContem: boolean;
begin
     for F in FileNames do begin
         JahContem := false;
         for i := 0 to uxView.Items.Count-1 do
         begin
              if uxView.Items.Item[i].ToString = F then
              begin
                   JahContem := true;
              end;
         end;
         if JahContem = false then
         begin
              uxView.AddItem(F, nil);
         end;

     end;
end;

procedure TMainForm.uxAddDirClick(Sender: TObject);
begin
  if DirDialog.Execute then
  begin
       uxView.AddItem(DirDialog.FileName, nil);
  end;
end;

procedure TMainForm.uxAddFilesClick(Sender: TObject);
begin
  FilesDialog.Execute;

end;

procedure TMainForm.uxClearClick(Sender: TObject);
begin
  uxView.Clear;
end;

procedure TMainForm.uxOnTopChange(Sender: TObject);
begin
  if uxOnTop.Checked then SetWindowPos(MainForm.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE)
        else SetWindowPos(MainForm.Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE);
  //if uxOnTop.Checked then
  //      MainForm.FormStyle := fsStayOnTop
  //else
  //      MainForm.FormStyle := fsNormal;
end;

procedure TMainForm.uxRemoveClick(Sender: TObject);
var
i : integer;
begin
  while uxView.Selected <> nil do
  begin
       uxView.Selected.Delete;
    end;
  end;



procedure TMainForm.uxWipeClick(Sender: TObject);
var
i : integer;
Mode : TDeleteMode;
begin
  if uxRandom.Checked then Mode := dmWipeRandom else Mode := dmWipeZeroes;
  for i := 0 to uxView.Items.Count-1 do
  begin
       WipePath(uxView.Items[i].ToString, Mode);
  end;
  uxView.Clear;
end;



end.

