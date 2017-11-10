;--------------------------------
;Object.NET's Bridge.NET CLI Installer
  !define CompanyName "Object.NET"
  !define ProductName "Bridge.NET CLI"
  !define BridgeExec "bridge.exe"
  !define BridgeUninst "bridge-uninstall.exe"
  !define Version "16.5.0"
  !define CompanyRegKey "Software\${CompanyName}"
  !define BaseRegKey "${CompanyRegKey}\${ProductName}"
  !define Build "Release"
  !define AssembliesPath "tools"
  !define TemplatesPath "Templates"
  !define SrcPath "..\..\Bridge\bin\${Build}"

  !define SysUninstallKey "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ProductName}"

  ; Whether to install to the current user or for the whole machine
  !define InstallScope "user" ; user or machine

  !if ${InstallScope} == "machine"
    !define RegistryRoot "HKLM"
    !define Environ '${RegistryRoot} "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
  !else
    !define RegistryRoot "HKCU"
    !define Environ '${RegistryRoot} "Environment"'
  !endif

;--------------------------------
;NSIS Modern User Interface
;Include Modern UI

  !include "MUI2.nsh"

;--------------------------------
;NSIS code not specific to Bridge, extracted from other sources

  !include "external-functions.nsh"

;--------------------------------
;General

  ;Name and file
  Name "Bridge.NET CLI"
  OutFile "bridge-${Version}-install.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\${CompanyName}\${ProductName}"

  ;Get installation folder from registry if available
  InstallDirRegKey "${RegistryRoot}" "${BaseRegKey}" ""

  ;Request application privileges for Windows Vista and newer
  RequestExecutionLevel admin

  SetCompressor /solid lzma

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_LICENSE "..\..\LICENSE"
  !insertmacro MUI_PAGE_COMPONENTS

  !define MUI_PAGE_CUSTOMFUNCTION_SHOW AskOrReuseDir
  !insertmacro MUI_PAGE_DIRECTORY

  !insertmacro MUI_PAGE_INSTFILES

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Makes the target directory selection read-only if Bridge has already been
;installed in the system. This will avoid reinstalling in another location
;and losing install/uninstall information.

Function AskOrReuseDir

  ReadRegStr $0 "${RegistryRoot}" "${BaseRegKey}" ""
  IfErrors done

  ; Sets the installation path the same previously used
  StrCpy $INSTDIR $0
  EnableWindow $mui.DirectoryPage.Directory 0
  EnableWindow $mui.DirectoryPage.BrowseButton 0
  MessageBox MB_OK "An installation of ${ProductName} is already registered at '$INSTDIR'. To change destination install directory, you must uninstall it. Proceeding will upgrade/update current installation."

done:

FunctionEnd

;--------------------------------
;Languages

  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

Section "${ProductName} v${Version}" InstallBridge

  SetOutPath "$INSTDIR"

  File "${SrcPath}\${BridgeExec}"

  SetOutPath "$INSTDIR\${AssembliesPath}\"

  File "${SrcPath}\${AssembliesPath}\*"

  SetOutPath "$INSTDIR\${TemplatesPath}\"

  File /r "${SrcPath}\${TemplatesPath}\*"

  ;Store installation folder
  WriteRegStr "${RegistryRoot}" "${BaseRegKey}" "" $INSTDIR

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\${BridgeUninst}"

  WriteRegStr "${RegistryRoot}" "${SysUninstallKey}" \
    "DisplayName" "${ProductName} v${Version}"
  WriteRegStr "${RegistryRoot}" "${SysUninstallKey}" \
    "UninstallString" "$\"$INSTDIR\${BridgeUninst}$\""
  WriteRegStr "${RegistryRoot}" "${SysUninstallKey}" \
    "QuietUninstallString" "$\"$INSTDIR\${BridgeUninst}$\" /S"

SectionEnd

Section "Add to Path" AddToPath

  Push "$INSTDIR"
  Call AddToPath

  ;Store installation folder
  WriteRegDWORD "${RegistryRoot}" "${BaseRegKey}" "AddedToPath" 1

SectionEnd

;--------------------------------
;Descriptions

  ;Language strings
  LangString DESC_InstallBridge ${LANG_ENGLISH} "Installs ${ProductName} v${Version}."
  LangString DESC_AddToPath ${LANG_ENGLISH} "Adds bridge.exe to environment %PATH%."

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${InstallBridge} $(DESC_InstallBridge)
    !insertmacro MUI_DESCRIPTION_TEXT ${AddToPath} $(DESC_AddToPath)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section
Section "Uninstall"

  Delete "$INSTDIR\${AssembliesPath}\*"

  RMDir "$INSTDIR\${AssembliesPath}"

  RMDir /r "$INSTDIR\${TemplatesPath}"

  Delete "$INSTDIR\${BridgeExec}"

  Delete "$INSTDIR\${BridgeUninst}"

  RMDir "$INSTDIR"

  ;Removes the Object.NET folder if it is left empty
  ;It will actually just remove the directory one level
  ;above installation dir -- provided it was made empty
  ;after uninstallation.
  StrCpy $0 "$INSTDIR\.."
  Call un.DeleteDirIfEmpty

  ReadRegDWORD $0 "${RegistryRoot}" "${BaseRegKey}" "AddedToPath"
  IfErrors done
  ${If} $0 == 1
   Push "$INSTDIR"
   Call un.RemoveFromPath
  ${EndIf}
  DeleteRegValue "${RegistryRoot}" "${BaseRegKey}" "AddedToPath"

done:
  DeleteRegKey /ifempty "${RegistryRoot}" "${BaseRegKey}"
  DeleteRegKey /ifempty "${RegistryRoot}" "${CompanyRegKey}"

  ;The windows uninstall entry will be removed for good.
  DeleteRegKey "${RegistryRoot}" "${SysUninstallKey}" \

SectionEnd