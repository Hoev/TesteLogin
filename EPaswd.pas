{**
*  TEvPassword
*
*  Copyright Sebastião Elivaldo Ribeiro
*  http://www.elivaldo.com.br
*  e-mail: falecom@elivaldo.com.br
*}

unit EPaswd;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Math, ComCtrls;

type
  TEvFrmPaswd = class;

  TEvPasswordError = (peInput, peRecognize);
  TEvValidateEvent = procedure (Sender: TObject; UserName, Password: string;
    var Valid: Boolean) of object;
  TEvErrorEvent = procedure (Sender: TObject; Error: TEvPasswordError) of object;

  TEvPassword = class(TComponent)
  private
    FCaption: string;
    FCharCase: TEditCharCase;
    FColor: TColor;
    FFont: TFont;
    FIndent: Byte;
    FMaxLenPassword: Integer;
    FMaxLenUserName: Integer;
    FPassword: string;
    FPasswordChar: Char;
    FPicture: TPicture;
    FRecognizeUser: Boolean;
    FShowOnCreate: Boolean;
    FText: string;
    FTimeOut: Integer;
    FTryCount: Byte;
    FUserName: string;
    FOldMsgEvent: TMessageEvent;
    FOnBeforeInput: TNotifyEvent;
    FOnAfterInput: TNotifyEvent;
    FOnValidate: TEvValidateEvent;
    FOnError: TEvErrorEvent;
    // variáveis adicionais
    FrmPaswd: TEvFrmPaswd;
    FLastPass: TDateTime;
    procedure AllowRecognizeUser;
    procedure CancelRecognizeUser;
    procedure CheckMessage(var Msg: TMsg; var Handled: Boolean);
    procedure RecognizeUser;
    procedure SetPicture(Value: TPicture);
    procedure SetFont(Value: TFont);
    procedure SetText(Value: string);
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Execute;
    property Password: string read FPassword write FPassword;
    property UserName: string read FUserName write FUserName;
  published
    property Caption: string read FCaption write FCaption;
    property CharCase: TEditCharCase read FCharCase write FCharCase default ecNormal;
    property Color: TColor read FColor write FColor default clBtnFace;
    property Font: TFont read FFont write SetFont;
    property Indent: Byte read FIndent write FIndent default 12;
    property MaxLenPassword: Integer read FMaxLenPassword write FMaxLenPassword default 0;
    property MaxLenUserName: Integer read FMaxLenUserName write FMaxLenUserName default 0;
    property PasswordChar: Char read FPasswordChar write FPasswordChar default '*';
    property Picture: TPicture read FPicture write SetPicture;
    property ShowOnCreate: Boolean read FShowOnCreate write FShowOnCreate default False;
    property Text: string read FText write SetText;
    property TimeOut: Integer read FTimeOut write FTimeOut default 180;
    property TryCount: Byte read FTryCount write FTryCount default 3;
    property OnAfterInput: TNotifyEvent read FOnAfterInput write FOnAfterInput;
    property OnBeforeInput: TNotifyEvent read FOnBeforeInput write FOnBeforeInput;
    property OnValidate: TEvValidateEvent read FOnValidate write FOnValidate;
    property OnError: TEvErrorEvent read FOnError write FOnError;
  end;

  { TEvFrmPaswd - formulário de entrada}
  TEvFrmPaswd = class(TForm)
    PanCenter: TPanel;
    LabUName: TLabel;
    LabPaswd: TLabel;
    EdtUName: TEdit;
    EdtPaswd: TEdit;
    BtnOK: TButton;
    BtnCancel: TButton;
    ImgBack: TImage;
    LabInfo: TLabel;
    PanMessage: TPanel;
    RichMessage: TRichEdit;
    ImgIcon: TImage;
    PanLine: TPanel;
    procedure FormActivate(Sender: TObject);
    procedure EdtsChange(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
  private
    procedure ActiveFocus;
    procedure DeleteIndicator(Rich: TRichEdit; Index: Integer);
    procedure RenderText(Rich: TRichEdit);
  public
    FComponent: TEvPassword;
    FLoopCount: Byte;
    FStatusForm: Byte;
    procedure ConfigureDialog;
  end;

procedure Register;

implementation

{$J+}
{$R *.DFM}
{$R *.RES}

resourcestring
  SFormCaption   = 'Senha de autorização';
  SMessage       = 'Entre com um nome de usuário e a uma senha válida para acessar o <b>sistema<b>.';
  SInfoEntry     = 'Identificação';
  SInfoReentry   = 'Confirmação';

const
  ONE_SECOND     = 0.000011574;
  SF_NONE        = 0;
  SF_INPUTING    = 1;
  SF_RECOGNIZING = 2;


//------------------------------------------------------------------------------------
//                              Formulário TEvFrmPaswd
//------------------------------------------------------------------------------------


// FormActivate
procedure TEvFrmPaswd.FormActivate(Sender: TObject);
begin
  RichMessage.Text := FComponent.Text;
  RenderText(RichMessage);

  EdtPaswd.MaxLength := FComponent.MaxLenPassword;
  EdtUName.MaxLength := FComponent.MaxLenUserName;

  EdtPaswd.Width := EdtUName.Width;
  FLoopCount := 1;
  ActiveFocus;
end;


// ActiveFocus
procedure TEvFrmPaswd.ActiveFocus;
begin
  if not EdtUName.ReadOnly and (EdtUName.Text = '') then
    begin
      EdtUName.SelectAll;
      EdtUName.SetFocus;
    end
  else
    begin
      EdtPaswd.SelectAll;
      EdtPaswd.SetFocus;
    end;
end;


// EdtsChange
procedure TEvFrmPaswd.EdtsChange(Sender: TObject);
begin
  BtnOk.Enabled := (EdtUName.Text <> '') and (EdtPaswd.Text <> '');
end;


// BtnOkClick
procedure TEvFrmPaswd.BtnOkClick(Sender: TObject);
var
  Valid: Boolean;
begin
  // faz a validação ou reconhecimento
  Valid := False;
  if FStatusForm = SF_RECOGNIZING then
    begin
      if EdtPaswd.Text = FComponent.Password then
        Valid := True
      else
        begin
          MessageBeep(0);
          EdtPaswd.Text := '';
        end;
    end
  else if Assigned(FComponent.OnValidate) then
    FComponent.OnValidate(Self, EdtUName.Text, EdtPaswd.Text, Valid);

  // controle de tentativas
  if Valid then
    ModalResult := mrOk
  else if (FLoopCount >= FComponent.TryCount) and (FComponent.TryCount <> 0) then
    ModalResult := mrCancel
  else
    begin
      ActiveFocus;
      Inc(FLoopCount);
    end;
end;


// ConfigureDialog
procedure TEvFrmPaswd.ConfigureDialog;
var
  W, I, H: Integer;
begin
  Caption := FComponent.Caption;

  // cor, fonte e tamanho do formulário
  Color := FComponent.Color;
  Font.Assign(FComponent.Font);
  W := Canvas.TextHeight('W');
  ClientWidth := 28 * W;

  // carrega imagem e posiciona
  ImgIcon.Picture.Assign(FComponent.Picture);
  ImgBack.Height := Max(54, ImgIcon.Height + FComponent.Indent);
  ImgIcon.Top := (ImgBack.Height - ImgIcon.Height) div 2;

  // label de informação
  if FStatusForm = SF_INPUTING then
    LabInfo.Caption := SInfoEntry
  else if FStatusForm = SF_RECOGNIZING then
    LabInfo.Caption := SInfoReentry;
  LabInfo.Font.Style := [fsBold];
  LabInfo.Font.Size := Font.Size + 2;
  LabInfo.Top := (ImgBack.Height - LabInfo.Height) div 2;

  // mensagem
  if FComponent.Text = '(NoText)' then
    begin
      RichMessage.Clear;
      PanMessage.Height := 0
    end
  else
    begin
      RichMessage.Text := FComponent.Text;
      RenderText(RichMessage);
      RichMessage.SetBounds(20, 15, ClientWidth - 20, 13);
      RichMessage.ScrollBars := ssVertical;
      GetScrollRange(RichMessage.Handle, SB_VERT, I, H);
      RichMessage.ScrollBars := ssNone;
      RichMessage.SetBounds(20, 15, ClientWidth - 40, H);
      PanMessage.Height := RichMessage.Top + H;
    end;

  // ajustes dos edits para login ou confirmação
  EdtUName.CharCase := FComponent.CharCase;
  EdtUName.Enabled := (FStatusForm = SF_INPUTING);
  EdtUName.Text := FComponent.UserName;
  EdtPaswd.CharCase := FComponent.CharCase;
  EdtPaswd.Text := '';
  EdtPaswd.PasswordChar := FComponent.FPasswordChar;
  EdtPaswd.Top := EdtUName.Top + EdtUName.Height + 9;
  LabPaswd.Top := EdtPaswd.Top + 3;

  // ajusta posição dos edits e botoes
  BtnOK.SetBounds(ClientWidth - (14 * W) - (FComponent.Indent * 2), EdtPaswd.Top + EdtPaswd.Height + 22, 7 * W, W + 10);
  BtnCancel.SetBounds(ClientWidth - (7 * W) - FComponent.Indent, BtnOK.Top, 7 * W, W + 10);

  // altura do formulário
  ClientHeight := ImgBack.Height + PanLine.Height + PanMessage.Height + BtnOK.Top + BtnOK.Height + FComponent.Indent;
end;


// RenderText
procedure TEvFrmPaswd.RenderText(Rich: TRichEdit);
var
  J, K, I, F: Integer;
const
  AIndicator: array[1..3] of string = ('<B>', '<I>', '<U>');
  AStyles: array[1..3] of TFontStyles = ([fsBold], [fsItalic], [fsUnderline]);
begin
  for J := 1 to 3 do
    begin
    I := Pos(AIndicator[J], UpperCase(Rich.Text));
    while I > 0 do
      begin
        DeleteIndicator(Rich, I - 1);
        F := Pos(AIndicator[J], UpperCase(Rich.Text));
        if F = 0 then
          F := Length(Rich.Text)
        else
          DeleteIndicator(Rich, F - 1);
        // adiciona o estilo da fonte para cada caractere
        // a fim de evitar do estilo anterior
        for K := I to F-1 do
          begin
            Rich.SelStart := K - 1;
            Rich.SelLength := 1;
            Rich.SelAttributes.Style := Rich.SelAttributes.Style + AStyles[J];
          end;
        I := Pos(AIndicator[J], UpperCase(Rich.Text));
      end;
  end;
end;


// DeleteIndicator
procedure TEvFrmPaswd.DeleteIndicator(Rich: TRichEdit; Index: Integer);
begin
  Rich.SelStart := Index;
  Rich.SelLength := 3;
  Rich.SelText := '';
end;


//------------------------------------------------------------------------------------
//                                    TEvPassword
//------------------------------------------------------------------------------------

// Create
constructor TEvPassword.Create(AOwner:TComponent);
const
  bShareware: AnsiString = ':tcf:';
begin
  inherited Create(AOwner);
  FCaption := SFormCaption;
  FCharCase := ecNormal;
  FFont := TFont.Create;
  FIndent := 12;
  FPasswordChar := '*';
  FPicture := TPicture.Create;
  FPicture.Bitmap.Handle := LoadBitmap(HInstance, 'LOGIN_ICON');
  FRecognizeUser := False;
  FShowOnCreate := False;
  FText := SMessage;
  FTimeOut := 180;
  FTryCount := 3;
  FOldMsgEvent := nil;

  // ajusta propriedades com base no formulário proprietário
  if AOwner is TCustomForm then
    begin
      FColor := TForm(AOwner).Color;
      FFont.Assign(TForm(AOwner).Font);
    end
  else
    FColor := clBtnFace;
    
  // mensagem shareware
  if (Trim(string(bShareware)) = '') and not (csDesigning in ComponentState) then
    begin
      MessageBeep(MB_ICONASTERISK);
      MessageDlg('O componente ' + ClassName + ' é shareware, e para ' +
        'utiliza-lo livremente você deve adquiri-lo.' + #13#13 +
        'www.elivaldo.com.br' + #13 +
        'falecom@elivaldo.com.br', mtInformation, [mbOk], 0);
      bShareware := '';
    end;
end;


// Destroy
destructor TEvPassword.Destroy;
begin
  CancelRecognizeUser;
  if not (csDesigning in ComponentState) and (FrmPaswd <> nil) and
    not (csDestroying in FrmPaswd.ComponentState) then
    FreeAndNil(FrmPaswd);
  FFont.Free;
  FPicture.Free;
  inherited Destroy;
end;


// SetFont
procedure TEvPassword.SetFont(Value: TFont);
begin
  FFont.Assign(Value);
end;


// SetPicture
procedure TEvPassword.SetPicture(Value: TPicture);
begin
  if Value.Graphic <> nil then
    FPicture.Assign(Value)
  else
    FPicture.Bitmap.Handle := LoadBitmap(HInstance, 'LOGIN_ICON');
end;


// SetText
procedure TEvPassword.SetText(Value: string);
begin
  if (Value = '') then
    FText := '(NoText)'
  else
    FText := Value;
end;


// Loaded
procedure TEvPassword.Loaded;
begin
  inherited;
  if not (csDesigning in ComponentState) and FShowOnCreate then
    Execute;
end;


// Execute
procedure TEvPassword.Execute;
begin
  // cria formulário e ajusta
  if FrmPaswd = nil then
    Application.CreateForm(TEvFrmPaswd, FrmPaswd);
  FrmPaswd.FComponent := Self;
  FrmPaswd.FStatusForm := SF_INPUTING;
  FrmPaswd.ConfigureDialog;

  // evento antes
  if Assigned(FOnBeforeInput) then
    FOnBeforeInput(FrmPaswd);

  // apresenta formulário
  if FrmPaswd.ShowModal = mrOk then
    begin
      FUserName := FrmPaswd.EdtUName.Text;
      FPassword := FrmPaswd.EdtPaswd.Text;
    end
  else if Assigned(FOnError) then
    FOnError(Self, peInput);

  // evento depois
  if Assigned(FOnAfterInput) then
    FOnAfterInput(FrmPaswd);

  // habilita reconhecimento do usuário
  AllowRecognizeUser;

  FrmPaswd.Close;
end;


// AllowRecognizeUser
procedure TEvPassword.AllowRecognizeUser;
begin
  FLastPass := Now;
  if not FRecognizeUser then
    begin
      FRecognizeUser := True;
      FOldMsgEvent := Application.OnMessage;
      Application.OnMessage := CheckMessage;
    end;
end;


// CancelRecognizeUser
procedure TEvPassword.CancelRecognizeUser;
begin
  if FRecognizeUser then
    begin
      FRecognizeUser := False;
      Application.OnMessage := FOldMsgEvent;
      FOldMsgEvent := nil;
    end;
end;


// CheckMessage
procedure TEvPassword.CheckMessage(var Msg: TMsg; var Handled: Boolean);
begin
  // desvio original
  if Assigned(FOldMsgEvent) then
    FOldMsgEvent(Msg, Handled);
  // monitoramento do mouse e do teclado
  if (Msg.message = WM_MOUSEMOVE) or (Msg.message = WM_KEYDOWN) then
    begin
      // verifica tempo de espera
      if (FTimeOut > 0) and (Now > (FLastPass + (FTimeOut * ONE_SECOND))) and
        ((FrmPaswd = nil) or not FrmPaswd.Visible) then
        begin
          FLastPass := Now;
          RecognizeUser;
        end;
      FLastPass := Now;
    end;
end;


// RecognizeUser
procedure TEvPassword.RecognizeUser;
begin
  // cria formulário e ajusta
  if FrmPaswd = nil then
    Application.CreateForm(TEvFrmPaswd, FrmPaswd);
  FrmPaswd.FComponent := Self;
  FrmPaswd.FStatusForm := SF_RECOGNIZING;
  FrmPaswd.EdtUName.Enabled := False;
  FrmPaswd.EdtPaswd.Text := '';
  FrmPaswd.LabInfo.Caption := SInfoReentry;

  if (FrmPaswd.ShowModal <> mrOk) and Assigned(FOnError) then
    FOnError(Self, peRecognize);

  FrmPaswd.Close;
end;


// Register
procedure Register;
begin
  {$IFDEF VER300}
  RegisterComponents('TCF Add', [TEvPassword]);
  {$ENDIF}
end;


end.


