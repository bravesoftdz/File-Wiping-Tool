unit wiping_tools;

{$mode objfpc}{$H+}



interface

//TODO: before release, create all files as hidden.

type

  TRand = class
    private class var
      x: DWORD;// = 123456789;
      y: DWORD;// = 362436069;
      z: DWORD;// = 521288629;
      w: DWORD;// = 88675123;
    private
      class constructor Create;
  end;

  TDeleteMode = (dmDelete, dmWipeZeroes, dmWipeRandom);
  TWipeMode = (wmZeroes, wmRandom);

  function FillRandom(var Buffer: array of byte; Length: Integer): Boolean;
  function WipeFreeSpace(const DriveLetter: Char; WipeMode: TWipeMode): Boolean;
  function WipePath(const Path: String; DeleteMode: TDeleteMode): Boolean;
  function WipeNameAndDelete(const Path: String): Boolean;
  function GetFileSizeEx(hFile: THandle; var FileSize: Int64): boolean; stdcall; external 'kernel32';
  function SetFileValidData(hFile: THandle; ValidDataLength: Int64): boolean; stdcall; external 'kernel32';

  const PhysicalSectorSize = 4096; //TODO: msdn.microsoft.com/en-us/library/windows/desktop/cc644950(v=vs.85).aspx
  const DefaultDir = 'TempWipeFreeSpace';



implementation



uses
  Classes, SysUtils, Dialogs, Windows, DateUtils, contnrs;


class constructor TRand.Create;
begin
  x := 123456789;
  y := 362436069;
  z := 521288629;
  w := 88675123;
end;

//cache result (static?)
function GetClusterSize(Drive: Char): Integer;
var
  RootPath: array[0..4] of Char;
  RootPtr: PChar;
  SectorsPerCluster: DWORD;
  BytesPerSector: DWORD;
  FreeClusters: DWORD;
  TotalClusters: DWORD;
begin

  SectorsPerCluster := 0; //supress warnings.
  BytesPerSector := 0;
  FreeClusters := 0;
  TotalClusters := 0;

  Drive := UpCase(Drive);
  if not (Drive in ['A'..'Z']) then
  begin
    raise Exception.Create('Invalid drive letter passed to GetClusterSize');
    Result := -1;
    Exit;
  end;
  RootPath[0] := Drive;
  RootPath[1] := ':';
  RootPath[2] := '\';
  RootPath[3] := #0;
  RootPtr := RootPath;

  if GetDiskFreeSpace(RootPtr, SectorsPerCluster, BytesPerSector, FreeClusters, TotalClusters) then
  begin
    Result := SectorsPerCluster * BytesPerSector;
  end
  else
  begin
    //raise Exception.Create('Call to GetDiskFreeSpace failed.');
    RaiseLastOSError;
    Result := -1;
  end;
end;

function FillRandom(var Buffer: array of byte; Length: Integer): Boolean;
var
  t, i: DWORD;
  toMove: Integer;
begin

  i := 0;
  toMove := 4;
  while i < Length do
  begin
    with TRand do
    begin
      t := x xor (x shl 11);
      x := y; y := z; z := w;
      w := w xor (w shr 19) xor (t xor (t shr 8));
      if (i + 4) > Length then
        toMove := Length - i;
      Move(w, Buffer[i], toMove);
    end;
    Inc(i, 4);
  end;

  Result := True;

end;

function RandomName(Len: Integer): String;
var
  PossibleChars: String;
begin
  if RandSeed = 0 then Randomize;
  PossibleChars := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  Result := '';
  repeat
    Result += PossibleChars[Random(Length(PossibleChars)) + 1];
  until (Length(Result) = Len);
end;

function WipeNameAndDelete(const Path: String): Boolean;
var
  NewPath: String;
begin

  NewPath := ConcatPaths([ExtractFileDir(Path), RandomName(MaxPathLen)]);
  while not RenameFile(Path, NewPath) do
  begin
    if GetLastError = ERROR_ALREADY_EXISTS then
    begin
      ShowMessage('Error 183. Path = ' + Path + #13#10 + 'NewPath = ' + NewPath);
    end;
    if ((GetLastError = ERROR_PATH_NOT_FOUND) or (GetLastError = ERROR_INVALID_NAME)) and (Length(ExtractFileName(NewPath)) > 1) then
      NewPath := Copy(NewPath, 0, Length(NewPath) - 1)
    else
    begin
      if GetLastError = ERROR_DISK_FULL then
      begin
        NewPath := Copy(NewPath, 0, Length(Path) - 1);
        Continue;
      end;
      showmessage('wiping name: ' + inttostr(getlasterror));
      Result := False;
      Exit;
    end;
  end;

  if FileExists(NewPath) then
    Result := SysUtils.DeleteFile(NewPath)
  else
    Result := RemoveDir(NewPath);

  if not Result then RenameFile(NewPath, Path);

end;

function GetFileSize(hFile: THandle): Int64; overload;
begin
  if not GetFileSizeEx(hFile, Result) then
    RaiseLastOSError;
end;


function WipeFile(const Path: String; DeleteMode: TDeleteMode): Boolean;
var
  BytesToWriteNow: LongWord;
  BytesWritten: Int64;
  BytesWrittenNow: LongWord;
  Handle: THandle;
  pBuffer: PByte;
  BufferSize: Integer;
  FileSize: Int64;
  F: File of Byte;
begin

  BufferSize := 65536;

  FileSetAttr(Path, 0);

  if DeleteMode = dmDelete then
  begin
    WipeNameAndDelete(Path);
    Exit;
  end;

  //VA to align for non-buffered IO
  pBuffer := VirtualAlloc(nil, BufferSize, MEM_COMMIT, PAGE_READWRITE);

  if DeleteMode = dmWipeZeroes then
  begin
    FillByte(pBuffer^, BufferSize, 0);
  end;

  Assign(F, Path);
  Reset(F);
  FileSize := System.FileSize(F);
  Close(F);
  if FileSize < 1024 then
  begin
    Handle := CreateFile(PChar(Path), GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
    if Handle = feInvalidHandle then
    begin
      ShowMessage('CreateFile() for <1024 failed. Last Error: ' + IntToStr(GetLastError));
      Exit;
    end;
    if DeleteMode = dmWipeRandom then
      FillRandom(pBuffer^, 1024);
    BytesToWriteNow := 100;
    while BytesToWriteNow < 700 do
    begin
      if not WriteFile(Handle, pBuffer^, BytesToWriteNow, BytesWrittenNow, nil) then
      begin
        showmessage('wiping <1024 failed writefile');
        Result := False;
        Exit;
      end;
      Inc(BytesToWriteNow);
      SetFilePointer(Handle, 0, nil, FILE_BEGIN);
    end;
    CloseHandle(Handle);
    WipeNameAndDelete(Path);
    Result := True;
    Exit;
  end;

  Handle := CreateFile(PChar(Path), GENERIC_WRITE, 0, nil, OPEN_EXISTING,
                         FILE_FLAG_NO_BUFFERING or FILE_FLAG_WRITE_THROUGH, 0);
  if Handle = feInvalidHandle then
  begin
    ShowMessage('CreateFile() failed. Last Error: ' + IntToStr(GetLastError));
    Exit;
  end;

  FileSize := GetFileSize(Handle);
  BytesWritten := 0;
  while BytesWritten < FileSize do
  begin
    if FileSize < (BytesWritten + BufferSize) then
      BytesToWriteNow := FileSize - BytesWritten
    else
      BytesToWriteNow := BufferSize;
    BytesWrittenNow := 0;

    //align for non-buffered IO
    if BytesToWriteNow mod PhysicalSectorSize <> 0 then
    begin
      BytesToWriteNow += PhysicalSectorSize - (BytesToWriteNow mod PhysicalSectorSize);
    end;

    if DeleteMode = dmWipeRandom then
    begin
      //since we'll always be writing multiples of 4k, doesn't really need to
      //adjust the size, but just to be safe for future changes
      FillRandom(pBuffer^, BytesToWriteNow - (BytesToWriteNow mod 4));
    end;
    if not WriteFile(Handle, pBuffer^, BytesToWriteNow, BytesWrittenNow, nil) then
    begin
      showmessage('writefile retnd 0. last error: ' + inttostr(GetLastError));
      CloseHandle(Handle);
      Exit;
    end;
    if BytesWrittenNow <> BytesToWriteNow then
    begin
      if BytesWritten < FileSize then
        ShowMessage('Could not write all bytes to ' + Path)
      else
        ShowMessage('debug. full disk?');
      Exit;
    end;
    BytesWritten += BytesWrittenNow;
  end;
  //attempt to overwrite possible cluster tip //does this job belong here?
  //WriteFile(Handle, pBuffer^, GetClusterSize(Path[1]), BytesWrittenNow, nil);
  CloseHandle(Handle);

  Result := WipeNameAndDelete(Path);

end;

function WipeDir(const Path: String; DeleteMode: TDeleteMode): Boolean;
var
  Search: TSearchRec;
  CurrentPath: String;
begin
  if FindFirst(ConcatPaths([Path, '*.*']), faAnyFile, Search) = 0 then
  begin
    repeat
      if (Search.Name = '.') or (Search.Name = '..') then Continue;
      CurrentPath := ConcatPaths([Path, Search.Name]);
      if FileGetAttr(CurrentPath) and faDirectory <> 0 then
        WipeDir(CurrentPath, DeleteMode)
      else
        WipeFile(CurrentPath, DeleteMode);
    until FindNext(Search) <> 0;
  end;

  SysUtils.FindClose(Search);
  //actually wipe the dir
  if GetDriveType(PChar(Path)) = DRIVE_NO_ROOT_DIR then
  begin
    WipeNameAndDelete(Path);
  end;

end;

function WipePath(const Path: String; DeleteMode: TDeleteMode): Boolean;
begin
  if FileExists(Path) then
    Result := WipeFile(Path, DeleteMode)
  else if DirectoryExists(Path) then
    Result := WipeDir(Path, DeleteMode)
  else
    ShowMessage('Debug: Neither file nor dir: ' + Path);

end;


//TODO: gotta be sure the disk is full before calling this. otherwise mft will grow.
//this wipes names (not guaranteed to wipe all)
//and wipes resident data of deleted files (should be guaranteed to wipe all)
function WipeMFT(const DriveLetter: Char): Boolean;
var
  Dir: String;
  Path: String;
  OpenHandles: TFPObjectList;
  Handle: THandle;
  i: Integer;
  PathLen: Integer;
  Buffer: array[0..900] of byte;
  BytesWritten, BytesToWrite: LongWord;
begin

  OpenHandles := TFPObjectList.Create;

  Dir := DriveLetter + ':\';
  PathLen := MaxPathLen;
  FillByte(Buffer, SizeOf(Buffer), 0);
  while True do
  begin
    Path := ConcatPaths([Dir, RandomName(PathLen)]);
    Handle := CreateFile(PChar(Path), GENERIC_WRITE, 0, nil, CREATE_NEW,
        FILE_FLAG_DELETE_ON_CLOSE, 0);
    if Handle = feInvalidHandle then
    begin
      if (GetLastError = ERROR_PATH_NOT_FOUND) or (GetLastError = ERROR_INVALID_NAME) then
      begin
        if PathLen > 1 then
        begin
          Dec(PathLen);
          Continue;
        end
        else
        begin
          ShowMessage('DEBUG. PathLen down to 1.');
          Result := False;
          Exit;
        end;
      end;
      if GetLastError = ERROR_DISK_FULL then break;
      RaiseLastOSError;
    end
    else
    begin
      BytesToWrite := SizeOf(Buffer);
      while True do
      begin
        if not WriteFile(Handle, Buffer, BytesToWrite, BytesWritten, nil) then
        begin
          if BytesToWrite = 1 then
            break;
          Dec(BytesToWrite);
        end;
      end;
      FlushFileBuffers(Handle);
      OpenHandles.Add(TObject(Handle));
    end;
  end;

  for i := 0 to (OpenHandles.Count - 1) do
  begin
    CloseHandle(DWORD(OpenHandles.Items[i]));
  end;

  Result := True;

  //OpenHandles.Destroy; //TODO: SIGSEGV ERROR

end;

function WipeFreeSpace(const DriveLetter: Char; WipeMode: TWipeMode): Boolean;
var
  BytesToWriteNow: LongWord;
  BytesWritten: Int64;
  BytesWrittenNow: LongWord;
  Handle: THandle;
  pBuffer: PByte;
  BufferSize: Integer;
  Dir: String;
  Path1: String;
  Path2: String;
begin

  BufferSize := 65536;

  //Dir := DriveLetter + ':\' + DefaultDir;
  Dir := DriveLetter + ':\';
  {if not DirectoryExists(Dir) then
  begin
    if not CreateDir(Dir) then
    begin
      ShowMessage('coulnt create default dir: ' + Dir);
      Result := False;
      Exit
    end;
  end
  else
    WipePath(Dir, dmDelete);}

  Path1 := ConcatPaths([Dir, RandomName(32)]);

  Handle := CreateFile(PChar(Path1), GENERIC_WRITE, 0, nil, CREATE_ALWAYS,
      FILE_FLAG_NO_BUFFERING or FILE_FLAG_WRITE_THROUGH, 0);

  if Handle = feInvalidHandle then
  begin
    ShowMessage('CreateFile() failed. Last Error: ' + IntToStr(GetLastError));
    Exit;
  end;

  //VA to align for non-buffered IO
  pBuffer := VirtualAlloc(nil, BufferSize, MEM_COMMIT, PAGE_READWRITE);

  if WipeMode = wmZeroes then
  begin
    FillByte(pBuffer^, BufferSize, 44);
  end;

  BytesWritten := 0;
  BytesToWriteNow := BufferSize;

  //write first file
  while True do
  begin
    BytesWrittenNow := 0;
    if WipeMode = wmRandom then
      FillRandom(pBuffer^, BytesToWriteNow);
    if not WriteFile(Handle, pBuffer^, BytesToWriteNow, BytesWrittenNow, nil) then
    begin
      if GetLastError = ERROR_DISK_FULL then
      begin
        if BytesToWriteNow > PhysicalSectorSize then
        begin
          BytesToWriteNow := BytesToWriteNow div 2;
          Continue;
        end
        else
        begin
          Break;
        end;
      end;
      showmessage('writefile retnd 0. last error: ' + inttostr(GetLastError));
      Break;
    end;
    if BytesWrittenNow <> BytesToWriteNow then
    begin
      showmessage('BytesWrittenNow <> BytesToWriteNow. last error: ' + inttostr(GetLastError));
      Break;
    end;
    BytesWritten += BytesWrittenNow;
  end;
  CloseHandle(Handle);


  //write second file
  Path2 := ConcatPaths([Dir, RandomName(32)]);
  Handle := CreateFile(PChar(Path2), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, 0, 0);
  if Handle = feInvalidHandle then
  begin
    ShowMessage('CreateFile() failed. Last Error: ' + IntToStr(GetLastError));
    Exit;
  end;

  BytesWritten := 0;
  BytesToWriteNow := BufferSize;
  while True do
  begin
    BytesWrittenNow := 0;
    if WipeMode = wmRandom then
      FillRandom(pBuffer^, BytesToWriteNow);
    if not WriteFile(Handle, pBuffer^, BytesToWriteNow, BytesWrittenNow, nil) then
    begin
      if GetLastError = ERROR_DISK_FULL then
      begin
        if BytesToWriteNow > 1 then
        begin
          BytesToWriteNow := BytesToWriteNow div 2;
          Continue;
        end
        else
        begin
          Break;
        end;
      end;
      showmessage('writefile 2 retnd 0. last error: ' + inttostr(GetLastError));
      Break;
    end;
    if BytesWrittenNow <> BytesToWriteNow then
    begin
      showmessage('BytesWrittenNow <> BytesToWriteNow. 2. last error: ' + inttostr(GetLastError));
      Break;
    end;
    BytesWritten += BytesWrittenNow;
  end;
  CloseHandle(Handle);

  WipeMFT(DriveLetter);

  //WipePath(Dir, dmDelete);
  WipeNameAndDelete(Path1);
  WipeNameAndDelete(Path2);
  //SysUtils.DeleteFile(Path1); //FILE_FLAG_DELETE_ON_CLOSE? better if app killed
  //SysUtils.DeleteFile(Path2);

  Result := True;
end;




end.
