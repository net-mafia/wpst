unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, LCLType, StdCtrls, ComCtrls,
  Menus, Grids, ExtCtrls, FPHTTPClient, OpenSSL, RegExpr, ShellCommandRunner;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    CheckBox1: TCheckBox;
    CheckBox10: TCheckBox;
    CheckBox11: TCheckBox;
    CheckBox12: TCheckBox;
    CheckBox13: TCheckBox;
    CheckBox14: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    CheckBox7: TCheckBox;
    CheckBox8: TCheckBox;
    CheckBox9: TCheckBox;
    Edit1: TEdit;
    Edit2: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    StringGrid1: TStringGrid;
    Timer1: TTimer;
    ToggleBox1: TToggleBox;
    TrackBar1: TTrackBar;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ToggleBox1Click(Sender: TObject);
    procedure ToggleBox1Change(Sender: TObject);
  private
    procedure OnOutputAvailable(const bytes: PByteArray; const return: integer);
  public

  end;
const
  Token = 'ntaBpoRda7GYvTKkEin2arEmcWWAHg1YYHu5szfxsJA';
  Socks4Source = 'https://www.socks-proxy.net';
  Socks5Source = 'https://www.gatherproxy.com/sockslist';
  HTTPsSource = 'https://www.free-proxy-list.net';
  ProxyConf = '\dep\proxychains\proxychains.conf';
  Sqlmap = '\dep\sqlmap\sqlmap.py';
  Wpscan = '\dep\wpscan\lib\wpscan.rb';
  ProxychainsPath = '\dep\proxychains\proxychains_win32_x64.exe';
var
  Form1: TForm1;
  Client: TFPHttpClient;
  RegEx: TRegExpr;
  ProxyFile: TextFile;
  IPAddress: String;
  Port: String;
  CountryCode: String;
  Country: String;
  Version: String;
  Rating: String;
  Output: String;
  URL: String;
  Verbose: String;
  DatabaseUpdate: String;
  Source: String;
  Proxychains: String;
  RandomAgent: String;
  MySQL: String;
  Quiet: String;
  Command: String;
  Execution: TShellCommandRunnerThread;
  OutputLines: TStringList;
  Row: TStrings;
  I, Reply, BoxStyle: Integer;
  CurrentDir: String;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
     if (CheckBox2.Checked) then Source := Socks4Source;
     try
     I := 1;
     Client := TFPHttpClient.Create(nil);
     Client.AllowRedirect := True;
     Client.AddHeader('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246');
     begin
          RegEx := TRegExpr.Create;
          RegEx.Expression := RegExprString('(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)(<\/td><td>)(\d{2,5})\2(\D{2})(<\/td><td class=''\D{2}''>)(\b\w*\b)\2(Socks\d{1})\5(\b\w*\b)');
          if RegEx.Exec(Client.Get(Source))
             then begin
                  repeat
                  IPAddress := RegEx.Match[1];
                  Port := RegEx.Match[3];
                  CountryCode := Regex.Match[4];
                  Country := RegEx.Match[6];
                  Version := RegEx.Match[7];
                  Rating := Regex.Match[8];
                  StringGrid1.InsertRowWithValues(I,[Version, IPAddress, Port, Country, Rating, CountryCode]);
                  I := I + 1;
                  until not RegEx.ExecNext;
             end;
        end;
     finally
            Client.Free;
            RegEx.Free;
     end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Memo1.Clear;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin

end;

procedure TForm1.MenuItem2Click(Sender: TObject);
begin
     CurrentDir := GetCurrentDir();
     BoxStyle := MB_ICONQUESTION + MB_YESNO;
     Reply := Application.MessageBox('Append this proxy list to proxychains?', 'Network Proxies', BoxStyle);
     if Reply = IDYES then begin
     AssignFile(ProxyFile, CurrentDir + ProxyConf);
     Append(ProxyFile);
          if StringGrid1.RowCount > 1 then begin
           try
              I := 1;
              repeat
              Row := StringGrid1.Rows[I];
              Row[0] := 'socks5'; //Temporary socks5 assignment
              WriteLn(ProxyFile, LowerCase(Row[0] + '   ' + Row[1] + '   ' + Row[2]));
              Memo1.Append(Row[1] + ':' + Row[2]);
              I := I + 1;
              until (I) = StringGrid1.RowCount;
           finally
           Application.MessageBox('Import is completed.', 'Done');
           end;
           CloseFile(ProxyFile);
        end;
     end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if (ToggleBox1.Checked and Execution.Finished) then begin
   ToggleBox1.Checked := False;
   Edit2.Text := '';
   Memo1.Append('Done');
  end;
end;

procedure TForm1.ToggleBox1Change(Sender: TObject);
begin
     if (ToggleBox1.Checked) then
        ToggleBox1.Caption := 'Abort';
     if (not ToggleBox1.Checked) then
        ToggleBox1.Caption := 'Attack';
end;

procedure TForm1.ToggleBox1Click(Sender: TObject);
begin
     CurrentDir := GetCurrentDir();
     if (CheckBox13.Checked) then Quiet := '-q';
     if (not CheckBox13.Checked) then Quiet := '';
     if (CheckBox5.Checked) then RandomAgent := '--random-agent';
     if (not CheckBox5.Checked) then RandomAgent := '';
     if (CheckBox6.Checked) then MySQL := '--dbms=MySQL';
     if (not CheckBox6.Checked) then MySQL := '';
     if (Checkbox4.Checked) then Proxychains := CurrentDir + ProxychainsPath + ' ' + Quiet + ' -f ' + CurrentDir + ProxyConf + ' ';
     if (not Checkbox4.Checked) then Proxychains := '';
     if (not ToggleBox1.Checked) then begin
        Edit2.Text := 'aborted';
        Execution.Abort;
     end;
     if (ToggleBox1.Checked) then begin
     Execution := TShellCommandRunnerThread.Create;
     if (RadioButton1.Checked) then begin
        Command := Proxychains + 'python.exe ' + CurrentDir + Sqlmap + ' --eta --beep ' + MySQL + ' -u ' + Edit1.Text + ' --threads=' + IntToStr(TrackBar1.Position) + ' --forms --crawl=2 ' + RandomAgent;
        Execution.CommandLine := Command;
        Execution.OnOutputAvailable := @OnOutputAvailable;
        Edit2.Text := (Command.TrimLeft(' ').TrimRight(' '));
        Execution.Start;
     end;
     if (RadioButton2.Checked) then begin
        if (CheckBox12.Checked) then Verbose := '--verbose';
        if (not CheckBox12.Checked) then Verbose := '';
        if (CheckBox14.Checked) then DatabaseUpdate := '--update';
        if (not CheckBox14.Checked) then DatabaseUpdate := '--no-update';
        if (CheckBox5.Checked) then RandomAgent := '--random-user-agent';
        if (CheckBox11.Checked) then RandomAgent := '--stealthy';
        Command := Proxychains + 'ruby.exe ' + CurrentDir + Wpscan + ' --no-banner ' + Verbose + ' ' + DatabaseUpdate + ' --enumerate vp --format cli-no-colour --url ' + Edit1.Text + ' --max-threads ' + IntToStr(TrackBar1.Position) + ' --request-timeout 120 --connect-timeout 60 --api-token ' + Token + ' ' + RandomAgent;
        Execution.CommandLine := Command;
        Execution.OnOutputAvailable := @OnOutputAvailable;
        Edit2.Text := (Command.TrimLeft(' ').TrimRight(' '));
        Execution.Start;
     end;
end;
end;

procedure TForm1.OnOutputAvailable(const bytes: PByteArray; const return: integer);
begin
     Memo1.Append(Execution.ToString(bytes, return));
end;

end.

