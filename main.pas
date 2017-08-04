unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, wiping_tools, Windows;

type

  { TMainForm }

  TMainForm = class(TForm)
    uxOnTop: TCheckBox;
    uxClear: TButton;
    uxWipe: TButton;
    uxLista: TListBox;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure uxOnTopChange(Sender: TObject);
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

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MainForm.uxOnTopChange(nil);
end;

procedure TMainForm.FormDropFiles(Sender: TObject;
  const FileNames: array of String);
var
F: String;
i:integer;
JahContem: boolean;
begin
     JahContem := false;
     for F in FileNames do begin
         for i := 0 to uxLista.Items.Count-1 do
         begin
              JahContem := false;
              if uxLista.Items[i] = F then
              begin
                   JahContem := true;
              end;
         end;
         if JahContem = false then
         begin
              uxLista.AddItem(F, nil);
         end;

     end;
end;

procedure TMainForm.uxOnTopChange(Sender: TObject);
begin
  (*if uxOnTop.Checked then SetWindowPos(MainForm.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE)
        else SetWindowPos(MainForm.Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE)*)
  if uxOnTop.Checked then
        MainForm.FormStyle := fsStayOnTop
  else
        MainForm.FormStyle := fsNormal;


end;



end.

