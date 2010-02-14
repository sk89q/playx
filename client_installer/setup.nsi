!include Registry.nsh
!include Sections.nsh
!include MUI2.nsh

Name "PlayX Chrome Support Pack"

!define VERSION 1.1.0.0
!define URL "http://github.com/sk89q/playx"
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_FINISHPAGE_NOAUTOCLOSE

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE license.txt
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE English

Var SteamPath
Var NumInstalls

OutFile playx-chrome-setup.exe
InstallDir "$PROGRAMFILES\PlayX Chrome Support Pack"
CRCCheck on
XPStyle on
ShowInstDetails show
VIProductVersion "${VERSION}"
VIAddVersionKey ProductName "PlayX Chrome Support Pack"
VIAddVersionKey ProductVersion "${VERSION}"
VIAddVersionKey FileVersion "${VERSION}"
VIAddVersionKey FileDescription "Installer for gm_chrome support for PlayX"
VIAddVersionKey LegalCopyright "(c) 2010 sk89q"

Section "!PlayX files" playx_files
    SetOutPath $INSTDIR\garrysmod\materials\playx
    SetOverwrite on
    File screen.vmt
    File screen.vtf
    File screen_sq.vmt
    File screen_sq.vtf
SectionEnd

Section "!gm_chrome" gm_chrome
    SetOutPath $INSTDIR
    SetOverwrite on
    File Awesomium.dll
    File icudt38.dll
    SetOutPath $INSTDIR\garrysmod\lua\includes\modules
    File gm_chrome.dll
SectionEnd

Section /o "gm_chrome source code" gm_chrome_src
    SetOutPath $INSTDIR
    SetOverwrite on
    File gm_chrome_src.zip
SectionEnd

LangString DESC_gm_chrome ${LANG_ENGLISH} "gm_chrome brings Google Chrome's rendering \
    engine to Garry's Mod. This is a required component, but if you already have gm_chrome, you \
    do not need to re-install it."
LangString DESC_playx_files ${LANG_ENGLISH} "PlayX-specific materials required for gm_chrome support."
LangString DESC_gm_chrome_src ${LANG_ENGLISH} "Source code for developers (optional)."

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
!insertmacro MUI_DESCRIPTION_TEXT ${gm_chrome} $(DESC_gm_chrome)
!insertmacro MUI_DESCRIPTION_TEXT ${playx_files} $(DESC_playx_files)
!insertmacro MUI_DESCRIPTION_TEXT ${gm_chrome_src} $(DESC_gm_chrome_src)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Function .onInit
    InitPluginsDir
    
    SectionSetFlags ${gm_chrome} 1
    SectionSetFlags ${playx_files} 17
    
    ; Detect Steam directory
    ${registry::Read} "HKEY_LOCAL_MACHINE\SOFTWARE\Valve\Steam" "InstallPath" $SteamPath $R1
    StrCmp $SteamPath "" noSteam
    
    ; Let's find a user who has Gmod installed
    FindFirst $R0 $R1 $SteamPath\steamapps\*
    loop:
        StrCmp $R1 "" endSearch ; Ran out of results
        IfFileExists $SteamPath\steamapps\$R1\garrysmod\hl2.exe found
        FindNext $R0 $R1
        Goto loop
        found:
            StrCpy $INSTDIR $SteamPath\steamapps\$R1\garrysmod
            IntOp $NumInstalls $NumInstalls + 1
            FindNext $R0 $R1
            Goto loop
    endSearch:
        FindClose $R0
        IntCmp $NumInstalls 1 foundGmod noGmod moreGmod
        foundGmod:
            Goto done
        moreGmod:
            MessageBox MB_OK|MB_ICONINFORMATION "More than one user was found \
                to have Garry's Mod. When asked to choose a directory to \
                install to, change the username if necessary."
            Goto done
        noGmod:
            MessageBox MB_OK|MB_ICONEXCLAMATION "A Steam user with Garry's Mod \
                installed could not be found. Remember to select your garrysmod \
                directory (not garrysmod/garrysmod) manually when you are asked."
            FindClose $R0
            Goto done
    noSteam:
        MessageBox MB_OK|MB_ICONEXCLAMATION 'Your Steam directory could not be \
            detected. Remember to select your garrysmod directory (not \
            garrysmod/garrysmod) manually when you are asked.'
        Goto done
    done:
    
FunctionEnd

