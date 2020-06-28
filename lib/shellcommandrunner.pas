{
  TShellCommandRunner: class to run external programs threaded to capture the output created.

  Copyright (C) 2012 G.A. Nijland - lemjeu@gmail.com

  This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public
  License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License for more details.

  You should have received a copy of the GNU Library General Public License along with this library; if not, write to the Free
  Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}
unit ShellCommandRunner;

{$mode objfpc}{$H+}

interface

uses
  StrUtils,
  Classes, SysUtils, Process;

const
  READ_BLOKCSIZE = 4096; // Default buffer size when reading process output data

type
  { Notify procedure when there is data available }
  TNotifyOutputAvailable = procedure(const pBuffer: PByteArray; const pCount: integer) of object;

  { TShellCommandRunner }
  TShellCommandRunner = class
  private
    FCommandline: string;
    FBlockSize: longint;
    FSize: longint;
    FDirectory: string;
    FExitStatus: integer;
    FShowWindow: TShowWindowOptions;
    FOnOutputAvailable: TNotifyOutputAvailable;
    FProcess: TProcess;

    // Signal that a termination was requested from outside
    FTerminationRequested: boolean;

    property Process: TProcess read FProcess write FProcess;
    property TerminationRequested: boolean read FTerminationRequested write FTerminationRequested;

  public
    constructor Create; reintroduce;
    function Execute(const pStream: TStream = nil; const pWaitForProcess: boolean = true): integer;
    class function BufferToString(const pBuffer: PByteArray; const pCount: integer): string;
    procedure Abort;

    property Commandline: string read FCommandline write FCommandline;
    property Directory: string read FDirectory write FDirectory;
    property BlockSize: longint read FBlockSize write FBlockSize;
    property Size: longint read FSize write FSize;
    property ExitStatus: integer read FExitStatus;
    property ShowWindow: TShowWindowOptions write FShowWindow;
    property OnOutputAvailable: TNotifyOutputAvailable read FOnOutputAvailable write FOnOutputAvailable;
  end;

  { TShellCommandRunnerThread }

  TShellCommandRunnerThread = class(TThread)
  private
    FRunner: TShellCommandRunner;
    FOnOutputAvailable: TNotifyOutputAvailable;
    FBuffer: PByteArray;
    FBufferCount: integer;
    FLocalEcho: boolean;

    procedure SetCommand(const AValue: string);
    procedure SynchronizeOutput;

  protected
    procedure Execute; override;
    procedure OnOutput(const pBuffer: PByteArray; const pCount: integer);

  public
    constructor Create;
    procedure Abort;

    procedure Write(const pInfo: string);
    function ToString(const pBuffer: PByteArray; const pCount: integer): string; reintroduce;

    property Runner: TShellCommandRunner read FRunner;
    property OnOutputAvailable: TNotifyOutputAvailable read FOnOutputAvailable write FOnOutputAvailable;
    property LocalEcho: boolean read FLocalEcho write FLocalEcho;
    property CommandLine: string write SetCommand;
  end;

implementation

{ TShellCommandRunner }

constructor TShellCommandRunner.Create;
begin
  inherited Create;
  BlockSize := READ_BLOKCSIZE;
  FShowWindow := swoHide;
  TerminationRequested := false;
end;

function TShellCommandRunner.Execute(const pStream: TStream; const pWaitForProcess: boolean): integer;
var nread  : longint;
    Buffer : PByteArray;
    OutputStream: TStream;

  // Local procedure to process bytes read; to prevent duplicated code.
  // 'Global' variables are used i.e. the local variables of the Execute procedure above.
  procedure ProcessNewData(const pNumBytes: longint);
  begin
    if pNumBytes > 0 then
    begin
      // Increase counter for total size of data read
      Inc(FSize, pNumBytes);

      // Write data to output stream
      if assigned(OutputStream) then
        OutputStream.Write(Buffer^, pNumBytes);

      // Signal other processes that data is available
      if assigned(FOnOutputAvailable) then
        FOnOutputAvailable(Buffer, pNumBytes);
    end;
  end;

begin
  // Init
  Size := 0;

  // Create process to handle the command
  Process := TProcess.Create(nil);
  Process.CommandLine := CommandLine;
  Process.Options := [poUsePipes, poStderrToOutPut];
  Process.ShowWindow := FShowWindow;

  // If the directory is entered, use it, 'escaping' all backslashes for windows only.
  if Directory <> '' then
    Process.CurrentDirectory := AnsiReplaceStr(Directory,'\','\\');

  // Buffer for data; use the given output size
  Buffer := GetMem(BlockSize);

  // Output stream; when provided use it.
  if assigned(pStream) then
    OutputStream := pStream
  else
    OutputStream := nil;

  // Execute
  Process.Execute;

  // Grab the output when required
  if not pWaitForProcess then
    FExitStatus := 0
  else
    begin
      // While the process is running, wait until it is finished or
      // a terminatio was requested.
      while Process.Running and (not TerminationRequested) do
      begin
        if Process.Output.NumBytesAvailable = 0 then
          sleep(50) // No data avaible; wait some time
        else
          begin
            // Get next available data from the process and process it
            nread := Process.Output.Read(Buffer^, BlockSize);
            ProcessNewData(nread);
          end;
      end; // while...

      // If termination was requested, abort the process else process the remaining output.
      if TerminationRequested then
          Process.Terminate(-1)
      else
        begin
          // Process ended by itself; grab the remainder of the output data
          repeat
            // Get remainder of the process data
            nread := Process.Output.Read(Buffer^, BlockSize);
            ProcessNewData(nread);
          until nread = 0;

          // Signal end of processing; no data to process anymore.
          if assigned(FOnOutputAvailable) then
            FOnOutputAvailable(Buffer,0);

        end;

      // Keep exit status to report back
      FExitStatus := Process.ExitStatus;
    end;

  // Clean up
  Freemem(Buffer);
  FreeAndNil(FProcess);

  // Return result of the process
  result := ExitStatus
end;

class function TShellCommandRunner.BufferToString(const pBuffer: PByteArray; const pCount: integer): string;
var i: integer;
begin
  setlength(result,pCount);
  for i := 0 to pCount-1 do
    result[i+1] := chr(pBuffer^[i]);
end;

procedure TShellCommandRunner.Abort;
begin
  TerminationRequested := true;
end;

{ TShellCommandRunnerThread }

procedure TShellCommandRunnerThread.SynchronizeOutput;
begin
  if assigned(FOnOutputAvailable) then
    FOnOutputAvailable(FBuffer,FBufferCount);
end;

procedure TShellCommandRunnerThread.SetCommand(const AValue: string);
begin
  FRunner.Commandline := AValue
end;

procedure TShellCommandRunnerThread.Execute;
begin
  FRunner.Execute;
  FRunner.Free;
end;

constructor TShellCommandRunnerThread.Create;
begin
  FreeOnTerminate := true;   // Default: free after end
  inherited Create(true);    // Create suspended so more parms can be set
  FLocalEcho := true;        // Give local echo of data that is written; default yes

  // Create the runner class that executes the process in the thread
  FRunner := TShellCommandRunner.Create;
  FRunner.OnOutputAvailable := @OnOutput;
end;

procedure TShellCommandRunnerThread.Write(const pInfo: string);
begin
  if pInfo <> '' then
  begin
    if FLocalEcho then
      OnOutput(@pInfo[1], length(pInfo));
    FRunner.Process.Input.Write(pInfo[1], length(pInfo));
  end;
end;

function TShellCommandRunnerThread.ToString(const pBuffer: PByteArray; const pCount: integer): string;
begin
  result := TShellCommandRunner.BufferToString(pBuffer,pCount);
end;

procedure TShellCommandRunnerThread.Abort;
begin
  // Signal the running process to abort.
  FRunner.Abort;
end;

procedure TShellCommandRunnerThread.OnOutput(const pBuffer: PByteArray; const pCount: integer);
begin
  if assigned(FOnOutputAvailable) then
  begin
    FBuffer := pBuffer;
    FBufferCount := pCount;
    Synchronize(@SynchronizeOutput);
  end;
end;

end.

