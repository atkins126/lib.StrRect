{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  StrRect - String rectification utility

    Main aim of this library is to simplify conversions in Lazarus when passing
    strings to RTL or WinAPI - mainly to ensure the same code can be used in all
    compilers (Delphi, FPC 2.x.x, FPC 3.x.x) without a need for symbol checks.

    It also provides set of functions for string comparison that encapsulates
    some of the intricacies given by different approach in different compilers.

    For details about encodings refer to file encoding_notes.txt that should
    be distributed with this library.

    Library was tested in following IDE/compilers:

      Delphi 7 Personal (non-unicode, Windows)
      Delphi 10.1 Berlin Personal (unicode, Windows)
      Lazarus 1.4.4 - FPC 2.6.4 (non-unicode, Windows)
      Lazarus 2.0.8 - FPC 3.0.4 (non-unicode, Windows)
      Lazarus 2.0.8 - FPC 3.0.4 (non-unicode, Linux)
      Lazarus 2.0.8 - FPC 3.0.4 (unicode, Windows)
      Lazarus 2.0.8 - FPC 3.0.4 (unicode, Linux)

    Tested compatible FPC modes:
    
      Delphi, DelphiUnicode, FPC (default), ObjFPC, TurboPascal

    WARNING - a LOT of assumptions were made when creating this library (most
              of it was written "blind", with no access to internet and
              documentation), so if you find any error or mistake, please
              contact the author.
              Also, if you are certain that some part, in here marked as
              dubious, is actually correct, let the author know.

  Version 1.4.1 (2020-08-08)

  Last change (2020-08-08)

  ©2017-2020 František Milt

  Contacts:
    František Milt: frantisek.milt@gmail.com

  Support:
    If you find this code useful, please consider supporting its author(s) by
    making a small donation using the following link(s):

      https://www.paypal.me/FMilt

  Changelog:
    For detailed changelog and history please refer to this git repository:

      github.com/TheLazyTomcat/Lib.StrRect

  Dependencies:
    none

===============================================================================}
{
  I do not have any good information on non-windows Delphi, therefore this
  entire unit is marked as platform in those systems as a warning.
}
unit StrRect{$IF not Defined(FPC) and not(Defined(WINDOWS) or Defined(MSWINDOWS))} platform{$IFEND};

{$IF Defined(WINDOWS) or Defined(MSWINDOWS)}
  {$DEFINE Windows}
{$IFEND}

{$IFDEF FPC}
  // do not set $MODE, leave the unit mode-agnostic
  {$MODESWITCH RESULT+}
  {$MODESWITCH DEFAULTPARAMETERS+}
  {$INLINE ON}
  {$DEFINE CanInline}
  {
    Activate symbol BARE_FPC if you want to compile this unit outside of
    Lazarus.
    Non-unicode default strings are assumed to be encoded using current CP when
    defined, otherwise they are assumed to be UTF8-encoded.
    Has effect only in FPC older than 2.7.1, in newer versions there are ways
    of how to discern the encoding automatically.

    It is automatically undefined if you compile the program in Lazarus
    with LCL (lazarus defines symbol LCL, this symbol is observed).

    Not defined by default.
  }
  {.$DEFINE BARE_FPC}
  {$IFDEF LCL}  // clearly not bare FPC...
    {$UNDEF BARE_FPC}
  {$ENDIF}
{$ELSE}
  {$IF CompilerVersion >= 17 then}  // Delphi 2005+
    {$DEFINE CanInline}
  {$ELSE}
    {$UNDEF CanInline}
  {$IFEND}
{$ENDIF}
{$H+} // explicitly activate long strings

interface

type
{$IF not Declared(UnicodeString)}
  UnicodeString = WideString;
{$ELSE}
  // don't ask, it must be here
  UnicodeString = System.UnicodeString;
{$IFEND}

{$IFNDEF FPC}
const
  FPC_FULLVERSION = Integer(0);
{$ENDIF}

{===============================================================================
    Auxiliary public functions
===============================================================================}
{
  Following two functions are present in newer Delphi where they replace
  deprecated UTF8Decode/UTF8Encode.
  They are here for use in older compilers.
}
{$IF not Declared(UTF8ToString)}
Function UTF8ToString(const Str: UTF8String): UnicodeString;{$IFDEF CanInline} inline; {$ENDIF}
{$DEFINE Implement_UTF8ToString}
{$IFEND}
{$IF not Declared(StringToUTF8)}
Function StringToUTF8(const Str: UnicodeString): UTF8String;{$IFDEF CanInline} inline; {$ENDIF}
{$DEFINE Implement_StringToUTF8}
{$IFEND}

{
  UTF8AnsiStrings

  Returns true when single-byte strings (AnsiString, ShortString, String in
  some cases) are encoded using UTF-8 encoding, false otherwise.
}
Function UTF8AnsiStrings: Boolean;{$IFDEF CanInline} inline; {$ENDIF}

{
  UTF8AnsiDefaultStrings

  Returns true when default strings (type String) are UTF-8 ecoded ansi strings,
  false in all other cases (eg. when in Unicode).
}
Function UTF8AnsiDefaultStrings: Boolean;{$IFDEF CanInline} inline; {$ENDIF}

{===============================================================================
    Default string <-> explicit string conversions
===============================================================================}
{
  Depending on some use cases, the actually used string type might change,
  therefore following type aliases are introduced for such cases.
}
type
{$IF Defined(FPC) and Defined(Unicode)}
  TRTLString = AnsiString;  TRTLChar = AnsiChar;  PRTLChar = PAnsiChar;
{$ELSE}
  TRTLString = String;      TRTLChar = Char;      PRTLChar = PChar;  
{$IFEND}
{$IF not Defined(FPC) and Defined(Windows) and Defined(Unicode)}
  TWinString = WideString;  TWinChar = Widechar;  PWinChar = PWideChar;
  TSysString = WideString;  TSysChar = WideChar;  PSysChar = PWideChar;
{$ELSE}
  TWinString = AnsiString;  TWinChar = Ansichar;  PWinChar = PAnsiChar;
  TSysString = AnsiString;  TSysChar = Ansichar;  PSysChar = PAnsichar;
{$IFEND}
{$IFDEF FPC}
  {$IF FPC_FULLVERSION >= 20701}
  TGUIString = type AnsiString(CP_UTF8);  TGUIChar = AnsiChar;  PGUIChar = PAnsiChar;
  {$ELSE}
  TGUIString = AnsiString;  TGUIChar = AnsiChar;  PGUIChar = PAnsiChar;
  {$IFEND}
{$ELSE}
  TGUIString = String;      TGUIChar = Char;      PGUIChar = PChar;
{$ENDIF}
{$IF Defined(FPC) and not Defined(Windows) and Defined(Unicode)}
  TCSLString = AnsiString;  TCSLChar = AnsiChar;  PCSLChar = PAnsiChar;
{$ELSE}
  TCSLString = String;      TCSLChar = Char;      PCSLChar = PChar;
{$IFEND}

//------------------------------------------------------------------------------

Function StrToShort(const Str: String): ShortString;{$IF Defined(CanInline) and Defined(FPC)} inline; {$IFEND}
Function ShortToStr(const Str: ShortString): String;{$IF Defined(CanInline) and Defined(FPC)} inline; {$IFEND}

Function StrToAnsi(const Str: String): AnsiString;{$IF Defined(CanInline) and Defined(FPC)} inline; {$IFEND}
Function AnsiToStr(const Str: AnsiString): String;{$IF Defined(CanInline) and Defined(FPC)} inline; {$IFEND}

Function StrToUTF8(const Str: String): UTF8String;{$IFDEF CanInline} inline; {$ENDIF}
Function UTF8ToStr(const Str: UTF8String): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToWide(const Str: String): WideString;{$IFDEF CanInline} inline; {$ENDIF}
Function WideToStr(const Str: WideString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToUnicode(const Str: String): UnicodeString;{$IFDEF CanInline} inline; {$ENDIF}
Function UnicodeToStr(const Str: UnicodeString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToRTL(const Str: String): TRTLString;{$IFDEF CanInline} inline; {$ENDIF}
Function RTLToStr(const Str: TRTLString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToGUI(const Str: String): TGUIString;{$IFDEF CanInline} inline; {$ENDIF}
Function GUIToStr(const Str: TGUIString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToWinA(const Str: String): AnsiString;{$IF Defined(CanInline) and Defined(FPC)} inline; {$IFEND}
Function WinAToStr(const Str: AnsiString): String;{$IF Defined(CanInline) and Defined(FPC)} inline; {$IFEND}

Function StrToWinW(const Str: String): WideString;{$IFDEF CanInline} inline; {$ENDIF}
Function WinWToStr(const Str: WideString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToWin(const Str: String): TWinString;{$IFDEF CanInline} inline; {$ENDIF}
Function WinToStr(const Str: TWinString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToCsl(const Str: String): TCSLString;{$IFDEF CanInline} inline; {$ENDIF}
Function CslToStr(const Str: TCSLString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToSys(const Str: String): TSysString;{$IFDEF CanInline} inline; {$ENDIF}
Function SysToStr(const Str: TSysString): String;{$IFDEF CanInline} inline; {$ENDIF}

{===============================================================================
    Explicit string comparison
===============================================================================}

Function ShortStringCompare(const A,B: ShortString; CaseSensitive: Boolean): Integer;
Function AnsiStringCompare(const A,B: AnsiString; CaseSensitive: Boolean): Integer;
Function UTF8StringCompare(const A,B: UTF8String; CaseSensitive: Boolean): Integer;
Function WideStringCompare(const A,B: WideString; CaseSensitive: Boolean): Integer;
Function UnicodeStringCompare(const A,B: UnicodeString; CaseSensitive: Boolean): Integer;
Function StringCompare(const A,B: String; CaseSensitive: Boolean): Integer;

implementation

uses
  SysUtils
{$IF not Defined(FPC) and (CompilerVersion >= 20)}(* Delphi2009+ *)
  , AnsiStrings
{$IFEND}
{$IFDEF Windows}
  , Windows
{$ENDIF};

{===============================================================================
    Auxiliary public functions
===============================================================================}

{$IFDEF Implement_UTF8ToString}
Function UTF8ToString(const Str: UTF8String): UnicodeString;
begin
Result := UTF8Decode(Str);
end;
{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF Implement_StringToUTF8}
Function StringToUTF8(const Str: UnicodeString): UTF8String;
begin
Result := UTF8Encode(Str);
end;
{$ENDIF}

//------------------------------------------------------------------------------

Function UTF8AnsiStrings: Boolean;
begin
{$IFDEF FPC}
  // FPC
  {$IFDEF Windows}
    // check for FPC is there because of Delphi :/
    {$IF FPC_FULLVERSION >= 20701}
      // new FPC, version 2.7.1 and newer
      Result := StringCodePage(AnsiString('')) = CP_UTF8;
    {$ELSE}
      // old FPC, before version 2.7.1
      Result := False;  // old FPC (prior to 2.7.1), everything is assumed to be ansi CP
    {$IFEND}
  {$ELSE}
    Result := True; // linux, everything is assumed to be UTF-8
  {$ENDIF}
{$ELSE}
  // delphi
  Result := {$IFDEF Windows}False{$ELSE}True{$ENDIF};
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function UTF8AnsiDefaultStrings: Boolean;
begin
{$IFDEF Unicode}
  Result := False;  // strings are encoded using UTF-16
{$ELSE}
  {$IFDEF FPC}
    // FPC
    {$IFDEF Windows}
      {$IF FPC_FULLVERSION >= 20701}
        Result := StringCodePage(AnsiString('')) = CP_UTF8;
      {$ELSE}
        {$IFDEF BARE_FPC}
          Result := GetACP = CP_UTF8;
        {$ELSE}
          Result := True;
        {$ENDIF}
      {$IFEND}
    {$ELSE}
      Result := True;
    {$ENDIF}
  {$ELSE}
    // delphi
    Result := {$IFDEF Windows}False{$ELSE}True{$ENDIF};
  {$ENDIF}
{$ENDIF}
end;


{===============================================================================
    Internal functions
===============================================================================}

{$IFDEF Windows}
type
  PUnicodeChar = PWideChar;

//------------------------------------------------------------------------------

Function UnicodeToAnsiCP(const Str: UnicodeString; CodePage: UINT = CP_ACP): AnsiString;
begin
If Length (Str) > 0 then
  begin
    SetLength(Result,WideCharToMultiByte(CodePage,0,PUnicodeChar(Str),Length(Str),nil,0,nil,nil));
    WideCharToMultiByte(CodePage,0,PUnicodeChar(Str),Length(Str),PAnsiChar(Result),Length(Result) * SizeOf(AnsiChar),nil,nil);
  {$IF Defined(FPC) and (FPC_FULLVERSION >= 20701)}
    SetCodePage(RawByteString(Result),CodePage,False);
  {$IFEND}
  end
else Result := '';
end;

//------------------------------------------------------------------------------

Function AnsiCPToUnicode(const Str: AnsiString; CodePage: UINT = CP_ACP): UnicodeString;
const
  ExclCodePages: array[0..19] of Word = (50220,50221,50222,50225,50227,50229,52936,
    54936,57002,57003,57004,57005,57006,57007,57008,57009,57010,57011,65000,42);
var
  i:      Integer;
  Flags:  DWORD;
begin
If Length (Str) > 0 then
  begin
    Flags := MB_PRECOMPOSED;
    For i := Low(ExclCodePages) to High(ExclCodePages) do
      If CodePage = ExclCodePages[i] then
        begin
          Flags := 0;
          Break{For i};
        end;
    SetLength(Result,MultiByteToWideChar(CodePage,Flags,PAnsiChar(Str),Length(Str) * SizeOf(AnsiChar),nil,0));
    MultiByteToWideChar(CodePage,Flags,PAnsiChar(Str),Length(Str) * SizeOf(AnsiChar),PUnicodeChar(Result),Length(Result));
  end
else Result := '';
end;

//------------------------------------------------------------------------------

Function UTF8ToAnsiCP(const Str: UTF8String; CodePage: UINT = CP_ACP): AnsiString;{$IFDEF CanInline} inline; {$ENDIF}
begin
Result := UnicodeToAnsiCP(UTF8ToString(Str),CodePage);
end;

//------------------------------------------------------------------------------

Function AnsiCPToUTF8(const Str: AnsiString; CodePage: UINT = CP_ACP): UTF8String;{$IFDEF CanInline} inline; {$ENDIF}
begin
Result := StringToUTF8(AnsiCPToUnicode(Str,CodePage));
end;

{$ENDIF}

//------------------------------------------------------------------------------

{$IF Defined(Windows) and not Defined(Unicode)}

Function AnsiToConsole(const Str: AnsiString): AnsiString;
begin
If Length (Str) > 0 then
  begin
    Result := StrToWinA(Str);
    UniqueString(Result);
    If not CharToOEMBuff(PAnsiChar(Result),PAnsiChar(Result),Length(Result)) then
      Result := '';
  {$IF Defined(FPC) and (FPC_FULLVERSION >= 20701)}
    SetCodePage(RawByteString(Result),CP_OEMCP,False);
  {$IFEND}
  end
else Result := '';
end;

//------------------------------------------------------------------------------

Function ConsoleToAnsi(const Str: AnsiString): AnsiString;
begin
If Length (Str) > 0 then
  begin
    Result := Str;
    UniqueString(Result);
    If OEMToCharBuff(PAnsiChar(Result),PAnsiChar(Result),Length(Result)) then
      Result := WinAToStr(Result)
    else
      Result := '';
  {$IF Defined(FPC) and (FPC_FULLVERSION >= 20701)}
    SetCodePage(RawByteString(Result),CP_ACP,False);
  {$IFEND}
  end
else Result := '';
end;

{$IFEND}

//------------------------------------------------------------------------------

Function UTF8ToUTF16(const Str: UTF8String): UnicodeString;{$IFDEF CanInline} inline; {$ENDIF}
begin
Result := UTF8ToString(Str);
end;

//------------------------------------------------------------------------------

Function UTF16ToUTF8(const Str: UnicodeString): UTF8String;{$IFDEF CanInline} inline; {$ENDIF}
begin
Result := StringToUTF8(Str);
end;


{===============================================================================
    Default string <-> explicit string conversion
===============================================================================}

Function StrToShort(const Str: String): ShortString;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      If UTF8AnsiStrings then
        Result := ShortString(UTF16ToUTF8(Str))
      else
        Result := ShortString(UnicodeToAnsiCP(Str));
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings and not UTF8AnsiStrings then
        Result := ShortString(UTF8ToAnsiCP(Str))
      else
        Result := ShortString(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := ShortString(UTF16ToUTF8(Str));
    {$ELSE}
      // non-unicode FPC on Linux
      Result := ShortString(Str);
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := ShortString(UnicodeToAnsiCP(Str));
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := ShortString(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := ShortString(UTF16ToUTF8(Str));
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := ShortString(Str);
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function ShortToStr(const Str: ShortString): String;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      If UTF8AnsiStrings then
        Result := String(UTF8ToUTF16(Str))
      else
        Result := String(AnsiCPToUnicode(Str));
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings and not UTF8AnsiStrings then
        Result := String(AnsiCPToUTF8(Str))
      else
        Result := String(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := String(UTF8ToUTF16(Str));
    {$ELSE}
      // non-unicode FPC on Linux
      Result := String(Str);
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := String(AnsiCPToUnicode(Str));
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := String(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := String(UTF8ToUTF16(Str));
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := String(Str);
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToAnsi(const Str: String): AnsiString;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      If UTF8AnsiStrings then
        Result := UTF16ToUTF8(Str)
      else
        Result := UnicodeToAnsiCP(Str);
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings and not UTF8AnsiStrings then
        Result := UTF8ToAnsiCP(Str)
      else
        Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := UnicodeToAnsiCP(Str);
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function AnsiToStr(const Str: AnsiString): String;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      If UTF8AnsiStrings then
        Result := UTF8ToUTF16(Str)
      else
        Result := AnsiCPToUnicode(Str);
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings and not UTF8AnsiStrings then
        Result := AnsiCPToUTF8(Str)
      else
        Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := AnsiCPToUnicode(Str);
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToUTF8(const Str: String): UTF8String;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := Str
      else
        Result := AnsiCPToUTF8(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := AnsiCPToUTF8(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function UTF8ToStr(const Str: UTF8String): String;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := Str
      else
        Result := UTF8ToAnsiCP(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := UTF8ToAnsiCP(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToWide(const Str: String): WideString;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := Str;
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := UTF8ToUTF16(Str)
      else
        Result := AnsiCPToUnicode(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := Str; 
    {$ELSE}
      // non-unicode FPC on Linux
      Result := UTF8ToUTF16(Str);
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := Str;  
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := AnsiCPToUnicode(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := Str;  
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := UTF8ToUTF16(Str);
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function WideToStr(const Str: WideString): String;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := Str;
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := UTF16ToUTF8(Str)
      else
        Result := UnicodeToAnsiCP(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := Str;
    {$ELSE}
      // non-unicode FPC on Linux
      Result := UTF16ToUTF8(Str);
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := UnicodeToAnsiCP(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := UTF16ToUTF8(Str);
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToUnicode(const Str: String): UnicodeString;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := Str;
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := UTF8ToUTF16(Str)
      else
        Result := AnsiCPToUnicode(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := Str;
    {$ELSE}
      // non-unicode FPC on Linux
      Result := UTF8ToUTF16(Str);
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := AnsiCPToUnicode(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := UTF8ToUTF16(Str);
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function UnicodeToStr(const Str: UnicodeString): String;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := Str;
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := UTF16ToUTF8(Str)
      else
        Result := UnicodeToAnsiCP(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := Str;
    {$ELSE}
      // non-unicode FPC on Linux
      Result := UTF16ToUTF8(Str);
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := UnicodeToAnsiCP(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := UTF16ToUTF8(Str);
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToRTL(const Str: String): TRTLString;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      If UTF8AnsiStrings then
        Result := UTF16ToUTF8(Str)
      else
        Result := UnicodeToAnsiCP(Str);
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings and not UTF8AnsiStrings then
        Result := UTF8ToAnsiCP(Str)
      else
        Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function RTLToStr(const Str: TRTLString): String;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      If UTF8AnsiStrings then
        Result := UTF8ToUTF16(Str)
      else
        Result := AnsiCPToUnicode(Str);
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings and not UTF8AnsiStrings then
        Result := AnsiCPToUTF8(Str)
      else
        Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToGUI(const Str: String): TGUIString;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := Str
      else
        Result := AnsiCPToUTF8(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function GUIToStr(const Str: TGUIString): String;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := Str
      else
        Result := UTF8ToAnsiCP(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToWinA(const Str: String): AnsiString;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := UnicodeToAnsiCP(Str);
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := UTF8ToAnsiCP(Str)
      else
        Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := UnicodeToAnsiCP(Str);
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function WinAToStr(const Str: AnsiString): String;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := AnsiCPToUnicode(Str);
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := AnsiCPToUTF8(Str)
      else
        Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := AnsiCPToUnicode(Str);
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToWinW(const Str: String): WideString;
begin
Result := StrToWide(Str);
end;

//------------------------------------------------------------------------------

Function WinWToStr(const Str: WideString): String;
begin
Result := WideToStr(Str);
end;

//------------------------------------------------------------------------------

Function StrToWin(const Str: String): TWinString;
begin
Result := StrToSys(Str);
end;

//------------------------------------------------------------------------------

Function WinToStr(const Str: TWinString): String;
begin
Result := SysToStr(Str);
end;

//------------------------------------------------------------------------------

Function StrToCsl(const Str: String): TCSLString;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := Str;
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := UTF8ToAnsiCP(Str,CP_OEMCP)
      else
        Result := AnsiToConsole(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := AnsiToConsole(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function CslToStr(const Str: TCSLString): String;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := Str;
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := AnsiCPToUTF8(Str,CP_OEMCP)
      else
        Result := ConsoleToAnsi(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := ConsoleToAnsi(Str);
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToSys(const Str: String): TSysString;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := UnicodeToAnsiCP(Str);
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := UTF8ToAnsiCP(Str)
      else
        Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := UTF16ToUTF8(Str);
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function SysToStr(const Str: TSysString): String;
begin
{$IFDEF FPC}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode FPC on Windows
      Result := AnsiCPToUnicode(Str);
    {$ELSE}
      // non-unicode FPC on Windows
      If UTF8AnsiDefaultStrings then
        Result := AnsiCPToUTF8(Str)
      else
        Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode FPC on Linux
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode FPC on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF Windows}
    {$IFDEF Unicode}
      // unicode Delphi on Windows
      Result := Str;
    {$ELSE}
      // non-unicode Delphi on Windows
      Result := Str;
    {$ENDIF}
  {$ELSE}
    {$IFDEF Unicode}
      // unicode Delphi on Linux
      Result := UTF8ToUTF16(Str);
    {$ELSE}
      // non-unicode Delphi on Linux
      Result := Str;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;


{===============================================================================
    Explicit string comparison
===============================================================================}

Function ShortStringCompare(const A,B: ShortString; CaseSensitive: Boolean): Integer;
begin
If CaseSensitive then
{$IF Defined(FPC) and Defined(Unicode)}
  Result := SysUtils.UnicodeCompareStr(ShortToStr(A),ShortToStr(B))
else
  Result := SysUtils.UnicodeCompareText(ShortToStr(A),ShortToStr(B));
{$ELSE}
  Result := SysUtils.AnsiCompareStr(ShortToStr(A),ShortToStr(B))
else
  Result := SysUtils.AnsiCompareText(ShortToStr(A),ShortToStr(B));
{$IFEND}
end;

//------------------------------------------------------------------------------

Function AnsiStringCompare(const A,B: AnsiString; CaseSensitive: Boolean): Integer;
begin
If CaseSensitive then
{$IFDEF FPC}
  Result := SysUtils.AnsiCompareStr(A,B)
else
  Result := SysUtils.AnsiCompareText(A,B)
{$ELSE}
{$IF Declared(AnsiStrings)}
  Result := AnsiStrings.AnsiCompareStr(A,B)
else
  Result := AnsiStrings.AnsiCompareText(A,B)
{$ELSE}
  Result := SysUtils.AnsiCompareStr(A,B)
else
  Result := SysUtils.AnsiCompareText(A,B)
{$IFEND}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function UTF8StringCompare(const A,B: UTF8String; CaseSensitive: Boolean): Integer;
begin
If CaseSensitive then
{$IFDEF FPC}
  Result := SysUtils.UnicodeCompareStr(UTF8ToUTF16(A),UTF8ToUTF16(B))
else
  Result := SysUtils.UnicodeCompareText(UTF8ToUTF16(A),UTF8ToUTF16(B))
{$ELSE}
{$IFDEF Unicode}
  Result := SysUtils.AnsiCompareStr(UTF8ToUTF16(A),UTF8ToUTF16(B))
else
  Result := SysUtils.AnsiCompareText(UTF8ToUTF16(A),UTF8ToUTF16(B))
{$ELSE}
  Result := SysUtils.WideCompareStr(UTF8ToUTF16(A),UTF8ToUTF16(B))
else
  Result := SysUtils.WideCompareText(UTF8ToUTF16(A),UTF8ToUTF16(B))
{$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function WideStringCompare(const A,B: WideString; CaseSensitive: Boolean): Integer;
begin
If CaseSensitive then
  Result := SysUtils.WideCompareStr(A,B)
else
  Result := SysUtils.WideCompareText(A,B)
end;

//------------------------------------------------------------------------------

Function UnicodeStringCompare(const A,B: UnicodeString; CaseSensitive: Boolean): Integer;
begin
If CaseSensitive then
{$IFDEF FPC}
  Result := SysUtils.UnicodeCompareStr(A,B)
else
  Result := SysUtils.UnicodeCompareText(A,B)
{$ELSE}
{$IFDEF Unicode}
  Result := SysUtils.AnsiCompareStr(A,B)
else
  Result := SysUtils.AnsiCompareText(A,B)
{$ELSE}
  Result := SysUtils.WideCompareStr(A,B)
else
  Result := SysUtils.WideCompareText(A,B)
{$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StringCompare(const A,B: String; CaseSensitive: Boolean): Integer;
begin
If CaseSensitive then
{$IF Defined(FPC) and Defined(Unicode)}
  Result := SysUtils.UnicodeCompareStr(A,B)
else
  Result := SysUtils.UnicodeCompareText(A,B)
{$ELSE}
  Result := SysUtils.AnsiCompareStr(A,B)
else
  Result := SysUtils.AnsiCompareText(A,B)
{$IFEND}
end;

end.
