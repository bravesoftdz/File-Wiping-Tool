unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, wiping_tools, Windows;

type

  { TMainForm }

  TMainForm = class(TForm)
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
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

procedure TMainForm.Button2Click(Sender: TObject);
var
Path: String;
begin

  WipePath('Z:\aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.txt', dmWipeZeroes);

  (*Path := 'X:\' + RandomName(32);

  Handle := CreateFile(PChar(Path), GENERIC_WRITE, 0, nil, CREATE_ALWAYS,
                         FILE_FLAG_NO_BUFFERING or FILE_FLAG_WRITE_THROUGH, 0);
  if Handle = feInvalidHandle then
  begin
    ShowMessage('CreateFile() failed. Last Error: ' + IntToStr(GetLastError));
    CloseHandle(Handle);
    Exit;
  end;
  CloseHandle(Handle);*)



end;

end.

