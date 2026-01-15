/* 
PUM v2 is implemented in AutoHotkey V2, by Sunwind (2026-01-15).

PUM - popup menu
PUM class - popup menu manager

 reference to the following documentation，from the archived forums:
 https://www.autohotkey.com/board/topic/73599-ahk-l-pum-owner-drawn-object-based-popup-menu/
*/
class PUM extends PUM_base
{
  __New(params := "") {
    this.instance := true
    this.Init()
    this.SetParams(params)
    this.gdipToken := pumAPI.Gdip_Startup()
  }
  
  __Get(aName, params) {
    if (aName = "__Class")
      return PUM.__Class
    return PUM._defaults.HasOwnProp(aName) ? PUM._defaults.%aName% : ""
  }
  
  __Delete() {
    pumAPI.Gdip_Shutdown(this.gdipToken)
    this.Free()
  }
  
  Free() {
    for , menu in this._menus.Clone()
      menu.Destroy()
    for , item in this._items.Clone()
      item.Destroy()
    for , hBrush in this._brush
      pumAPI.DeleteObject(hBrush)
    for , hFont in this._font
      pumAPI.DeleteObject(hFont)
  }
  
  Init() {
    this._menus := Map()
    this._items := Map()
    this._itemIDbyUID := Map()
    this._itemsCount := 0
    this._brush := Map()
    this._font := Map()
    this.CreateFonts()
  }

  Destroy() {
    this.IsInstance()
    this.Free()
    this.Init()
  }
  
  IsInstance() {
    if this.instance
      return true
    this.Err("Object is not an instance.`nUse 'new' to make one")
  }
  
  CreateFonts() {
    if !this.pumfont {
      LOGFONT := Buffer(92, 0)
      ok := DllCall("SystemParametersInfoW", "UInt", 0x001F, "UInt", 92, "Ptr", LOGFONT, "UInt", 0, "UInt")
      if !ok
        return
    } else {
      pumAPI.obj2LOGFONT(this.pumfont, &LOGFONT)
    }
    this._font["normal"] := pumAPI.CreateFontIndirect(LOGFONT)
    pumAPI.obj2LOGFONT({weight: 700}, &LOGFONT)
    this._font["bold"] := pumAPI.CreateFontIndirect(LOGFONT)
  }
  
  GetFontNormal() {
    return this._font["normal"]
  }
  
  GetFontBold() {
    return this._font["bold"]
  }
  
  GetBrush(clr) {
    this.IsInstance()
    if this._brush.Has(clr)
      return this._brush[clr]
    return this._brush[clr] := pumAPI.CreateSolidBrush(clr)
  }
  
  SetParams(params) {
    this.IsInstance()
    if !IsObject(params)
      return 0
    if params.HasOwnProp("SelMethod")
      this.selMethod := params.SelMethod
    if params.HasOwnProp("selMethod")
      this.selMethod := params.selMethod
    if params.HasOwnProp("selTColor")
      this.selTColor := params.selTColor
    if params.HasOwnProp("seltcolor")
      this.selTColor := params.seltcolor
    if params.HasOwnProp("selBGColor")
      this.selBGColor := params.selBGColor
    if params.HasOwnProp("selbgcolor")
      this.selBGColor := params.selbgcolor
    if params.HasOwnProp("frameWidth")
      this.frameWidth := params.frameWidth
    if params.HasOwnProp("mnemonicCMD")
      this.mnemonicCmd := params.mnemonicCMD
    if params.HasOwnProp("mnemonicCmd")
      this.mnemonicCmd := params.mnemonicCmd
    if params.HasOwnProp("oninit")
      this.oninit := params.oninit
    if params.HasOwnProp("onuninit")
      this.onuninit := params.onuninit
    if params.HasOwnProp("onselect")
      this.onselect := params.onselect
    if params.HasOwnProp("onrbutton")
      this.onrbutton := params.onrbutton
    if params.HasOwnProp("onmbutton")
      this.onmbutton := params.onmbutton
    if params.HasOwnProp("onrun")
      this.onrun := params.onrun
    if params.HasOwnProp("onshow")
      this.onshow := params.onshow
    if params.HasOwnProp("onclose")
      this.onclose := params.onclose
    if params.HasOwnProp("pumfont")
      this.pumfont := params.pumfont
    if (params.HasOwnProp("selTColor") && this.selTColor != -1)
      this.selTColor := pumAPI.RGBtoBGR(this.selTColor)
    else if (params.HasOwnProp("seltcolor") && this.selTColor != -1)
      this.selTColor := pumAPI.RGBtoBGR(this.selTColor)
    if (params.HasOwnProp("selBGColor") && this.selBGColor != -1)
      this.selBGColor := pumAPI.RGBtoBGR(this.selBGColor)
    else if (params.HasOwnProp("selbgcolor") && this.selBGColor != -1)
      this.selBGColor := pumAPI.RGBtoBGR(this.selBGColor)
  }
  
  GetMenu(menuHandle) {
    this.IsInstance()
    if this._menus.Has(menuHandle)
      return this._menus[menuHandle]
    return 0
  }
  
  GetItemByID(id) {
    this.IsInstance()
    if (id && this._items.Has(id))
      return this._items[id]
    return 0
  }
  
  GetItemByUID(uid) {
    this.IsInstance()
    return this.GetItemByID(this._itemIDbyUID[uid])
  }
  
  CreateMenu(params := "") {
    this.IsInstance()
    handle := pumAPI._CreatePopupMenu()
    newmenu := PUM_Menu(handle, this)
    this._menus[handle] := newmenu
    newmenu.SetParams(params)
    return newmenu
  }

  static _defaults := { selMethod   : "fill"  ;may be "frame","fill"
                      , selBGColor  : DllCall("GetSysColor", "UInt", 29, "UInt")       ;default - COLOR_MENUHILIGHT
                      , selTColor   : DllCall("GetSysColor", "UInt", 14, "UInt")       ;default - COLOR_HIGHLIGHTTEXT
                      , frameWidth  : 1        ;width of select frame when selMethod = "frame"
                      , mnemonicCmd : "run"    ;may be "select","run"
                      , oninit      : ""
                      , onuninit    : ""
                      , onselect    : ""
                      , onrbutton   : ""
                      , onmbutton   : ""
                      , onrun       : ""
                      , onshow      : ""
                      , onclose     : ""
                      , pumfont     : "" }
}

/* 
PUM_Item class represent single menu item
*/

class PUM_Item extends PUM_base
{
  __New(id, objMenu) {
    this.id := id
    this.menu := objMenu
    this.alive := true
  }
  
  __Get(aName, params) {
    if (aName = "__Class")
      return PUM_Item.__Class
    return PUM_Item._defaults.HasOwnProp(aName) ? PUM_Item._defaults.%aName% : ""
  }
  
  __Delete() {
  }
  
  GetPos() {
    return pumAPI._GetItemPosByID(this.menu.handle, this.id)
  }
  
  GetRECT() {
    nPos := this.GetPos()
    if (nPos != -1)
      return pumAPI._GetItemRect(this.menu.handle, nPos)
    return 0
  }
  
  GetParent() {
    return this.menu
  }
  
  Detach() {
    this.detachSubMenu := true
    this.Destroy()
  }
  
  Destroy() {
    if !this.alive
      return 0
    this.Free()
    if pumAPI.IsInteger(this.uid)
      this.menu.objPUM._itemIDbyUID.Delete(this.uid)
    else
      this.menu.objPUM._itemIDbyUID.Delete(this.uid)
    this.menu.objPUM._items.Delete(this.id)
    if this.detachSubMenu {
      this.RemoveSubMenu()
      pumAPI._RemoveItem(this.menu.handle, this.id)
    } else {
      this.DestroySubMenu()
      pumAPI._DeleteItem(this.menu.handle, this.id)
    }
    this.menu := ""
    this.submenu := ""
    this.alive := false
  }
  
  Free() {
    if this.icondestroy
      pumAPI.DestroyIcon(this.hIcon)
    this.hotCharCode := ""
  }
  
  DestroySubMenu() {
    if IsObject(this.assocMenu)
      this.assocMenu.Destroy()
  }
  
  RemoveSubMenu() {
    if !this.alive
      return 0
    if this.assocMenu && this.assocMenu.handle {
      fMask := pumAPI.MIIM_SUBMENU
      cbsize := pumAPI.MENUITEMINFOsize
      struct := Buffer(cbsize, 0)
      NumPut("UInt", cbsize, struct, 0)
      NumPut("UInt", fMask, struct, 4)
      NumPut("Ptr", 0, struct, 16 + A_PtrSize)
      pumAPI._SetMenuItemInfo(this.menu.handle, this.id, false, struct.Ptr)
      this.assocMenu.owner := ""
      this.assocMenu := ""
      this.submenu := ""
    }
  }
  
  SetParams(params, newItemPos := "", fByPos := true) {
    if !this.alive
      return 0
    if IsObject(params) {
      if params.HasOwnProp("name")
        this.name := params.name
      if params.HasOwnProp("bold")
        this.bold := params.bold
      if params.HasOwnProp("icon")
        this.icon := params.icon
      if params.HasOwnProp("iconUseHandle")
        this.iconUseHandle := params.iconUseHandle
      if params.HasOwnProp("break")
        this.break := params.break
      if params.HasOwnProp("submenu")
        this.submenu := params.submenu
      if params.HasOwnProp("tcolor")
        this.tcolor := params.tcolor
      if params.HasOwnProp("bgcolor")
        this.bgcolor := params.bgcolor
      if params.HasOwnProp("noPrefix")
        this.noPrefix := params.noPrefix
      if params.HasOwnProp("disabled")
        this.disabled := params.disabled
      if params.HasOwnProp("noicons")
        this.noicons := params.noicons
      if params.HasOwnProp("notext")
        this.notext := params.notext
      if params.HasOwnProp("uid")
        this.uid := params.uid
      if (this.uid != "")
        this.menu.objPUM._itemIDbyUID[this.uid] := this.id
    } else if !pumAPI.IsEmpty(params) {
      this.name := params
    } else {
      this.issep := 1
    }
    if !pumAPI.isEmpty(this.tcolor)
      this.tcolor := pumAPI.RGBtoBGR(this.tcolor)
    if !pumAPI.isEmpty(this.bgcolor)
      this.bgcolor := pumAPI.RGBtoBGR(this.bgcolor)
    this._update(newItemPos, fByPos)
    return 1
  }
  
  Update() {
    this._update()
  }
  
  GetTColor() {
    return pumAPI.RGBtoBGR(this.tcolor)
  }
  
  GetBGColor() {
    return pumAPI.RGBtoBGR(this.bgcolor)
  }
  
  GetIconHandle() {
    return this.hicon
  }
  
  _update(newItemPos := "", fByPos := true) {
    this.Free()
    this.hfont := this.bold ? this.menu.objPUM.GetFontBold() : this.menu.objPUM.GetFontNormal()
    
    mnemPos := InStr(this.name, "&")
    if mnemPos {
      hotChar := SubStr(this.name, mnemPos + 1, 1)
      hotChar := StrLower(hotChar)
      this.hotCharCode := Ord(hotChar)
    }
    
    fMask := 0
    fMask |= pumAPI.MIIM_FTYPE
    fMask |= pumAPI.MIIM_ID
    fMask |= pumAPI.MIIM_STATE
    fMask |= pumAPI.MIIM_SUBMENU
    fMask |= pumAPI.MIIM_BITMAP
    
    fType := 0
    fType |= pumAPI.MFT_OWNERDRAW
    if this.issep
      fType |= pumAPI.MFT_SEPARATOR
    else if this.break
      fType |= this.break = 2 ? pumAPI.MFT_MENUBARBREAK : pumAPI.MFT_MENUBREAK
    
    fState := 0
    if this.disabled
      fState |= pumAPI.MFS_DISABLED
    wID := this.id
    
    ownedMenu := IsObject(this.submenu) ? this.submenu
               : (pumAPI.IsInteger(this.submenu) && this.menu.objPUM._menus.Has(this.submenu)) ? this.menu.objPUM._menus[this.submenu]
               : 0
    if (IsObject(ownedMenu) && !ownedMenu.owner && pumAPI._IsMenu(ownedMenu.handle)) {
      if !this.assocMenu || (this.assocMenu.handle != ownedMenu.handle) {
        this.DestroySubMenu()
        ownedMenu.owner := this
        this.assocMenu := ownedMenu
        ownedMenu := ""
      }
    }
    
    itemNoIcons := this.noicons = -1 ? this.menu.noicons : this.noicons
    if !itemNoIcons {
      if pumAPI.IsInteger(this.icon) && this.iconUseHandle {
        this.hicon := this.icon
        this.icondestroy := 0
      } else {
        this.hicon := pumAPI._loadIcon(this.icon, this.menu.iconssize)
        this.icondestroy := 1
      }
    }
    
    fMask |= pumAPI.MIIM_DATA
    dwItemData := ObjPtr(this)
    
    cbsize := pumAPI.MENUITEMINFOsize
    struct := Buffer(cbsize, 0)
    NumPut("UInt", cbsize, struct, 0)
    NumPut("UInt", fMask, struct, 4)
    NumPut("UInt", fType, struct, 8)
    NumPut("UInt", fState, struct, 12)
    NumPut("UInt", wID, struct, 16)
    NumPut("Ptr", this.assocMenu ? this.assocMenu.handle : 0, struct, 16 + A_PtrSize)
    NumPut("Ptr", dwItemData, struct, 16 + 4 * A_PtrSize)
    
    if (newItemPos != "")
      pumAPI._insertMenuItem(this.menu.handle, newItemPos, fByPos, struct.Ptr)
    else
      pumAPI._SetMenuItemInfo(this.menu.handle, this.id, false, struct.Ptr)
  }
  
  static _defaults := { issep  : 0
                      , name   : ""
                      , bold   : 0
                      , icon   : 0
                      , iconUseHandle : 0
                      , break  : 0 ;0,1,2
                      , submenu: 0
                      , tcolor : ""
                      , bgcolor: ""
                      , noPrefix : 0
                      , disabled : 0
                      , noicons : -1   ;-1 means use parent menu's setting
                      , notext  : -1 }
}

/* 
PUM_Menu class represent single menu
*/

class PUM_Menu extends PUM_base
{   
  static _defaults := { tcolor     : DllCall("GetSysColor", "UInt", 7, "UInt")  ;default - COLOR_MENUTEXT
                      , bgcolor    : DllCall("GetSysColor", "UInt", 4, "UInt")  ;default - COLOR_MENU
                      , nocolors   : 0
                      , noicons    : 0
                      , notext     : 0
                      , iconssize  : 32
                      , textoffset : 5
                      , maxHeight  : 0
                      , xmargin    : 3
                      , ymargin    : 3
                      , textMargin : 5 } ;this is a pixels amount which will be added after the text to make menu look pretty
  
  static _trackConsts := {  context   : 0x0001  ;TPM_RECURSE
                          ,hcenter  : 0x4     ;TPM_CENTERALIGN
                          ,hleft    : 0x0     ;TPM_LEFTALIGN
                          ,hright   : 0x8     ;TPM_RIGHTALIGN
                          ,vbottom  : 0x20    ;TPM_BOTTOMALIGN
                          ,vtop     : 0x0     ;TPM_TOPALIGN
                          ,vcenter  : 0x10    ;TPM_VCENTERALIGN
                          ,animlr   : 0x400   ;TPM_HORPOSANIMATION
                          ,animrl   : 0x800   ;TPM_HORNEGANIMATION
                          ,animtb   : 0x1000  ;TPM_VERPOSANIMATION
                          ,animbt   : 0x2000  ;TPM_VERNEGANIMATION
                          ,noanim   : 0x4000 }  ;TPM_NOANIMATION
  
  __New(handle, objPUM) {
    this.handle := handle
    this.objPUM := objPUM
    this.alive := true
  }
  
  __Get(aName, params) {
    if (aName = "__Class")
      return PUM_Menu.__Class
    return PUM_Menu._defaults.HasOwnProp(aName) ? PUM_Menu._defaults.%aName% : ""
  }
  
  __Delete() {
  }
  
  EndMenu() {
    pumAPI._EndMenu()
  }
  
  Detach() {
    if IsObject(this.owner) {
      this.owner.RemoveSubMenu()
      this.owner := ""
    }
  }
  
  Destroy() {
    if !this.alive
      return 0
    this.Free()
    if pumAPI.IsInteger(this.handle)
      this.objPUM._menus.Delete(this.handle)
    else
      this.objPUM._menus.Delete(this.handle)
    if this.owner {
      this.owner.assocMenu := ""
      this.owner.submenu := ""
      this.owner := ""
    }
    this.DestroyItems()
    pumAPI._DestroyMenu(this.handle)
    this.objPUM := ""
    this.alive := false
  }
  
  DestroyItems() {
    for , item in this.GetItems()
      item.Destroy()
  }
  
  IsMenu() {
    return pumAPI._IsMenu(this.handle)
  }
  
  GetTColor() {
    return pumAPI.RGBtoBGR(this.tcolor)
  }
  
  GetBGColor() {
    return pumAPI.RGBtoBGR(this.bgcolor)
  }
  
  GetParent() {
    return this.owner.GetParent()
  }
  
  Free() {
  }
  
  GetItems() {
    if !this.alive
      return 0
    return pumAPI._GetMenuItems(this.handle)
  }
  
  GetItemByPos(nPos) {
    return pumAPI._GetItem(this.handle, nPos, true)
  }
  
  Count() {
    if !this.alive
      return 0
    return pumAPI._GetMenuItemCount(this.handle)
  }
  
  Show(x := 0, y := 0, flags := "") {
    if !this.alive
      return 0
    global PUMhParent, PUMGui
    item := 0
    ret := 1
    tpmflags := 0x100
    for , v in pumAPI.StrSplit(flags, A_Space, A_Space A_Tab) {
      val := PUM_Menu._trackConsts.%v%
      if val
        tpmflags |= val
    }
    isContext := (tpmflags & 0x1) != 0
    if !isContext {  ;check if menu is not recursed menu ( has TPM_RECURSE flag )
      foo := this.objPUM.onshow
      if foo {
        cb := 0
        if IsObject(foo)
          cb := foo
        else if (Type(foo) = "String")
          try cb := %foo%
        if cb
          ret := cb.Call("onshow", this)
      }
      if (ret = 0)
        return
      if !IsSet(PUMGui)
      {
        ; PUMGui := Gui("+ToolWindow +AlwaysOnTop")
        PUMGui := Gui("+LastFound +ToolWindow +AlwaysOnTop -Caption +E0x08000000") ; WS_EX_NOACTIVATE
        PUMGui.Title := "PUM_Menu1"
      }
      ; PUMGui.Show("NoActivate w0 h0 x-32000 y-32000")
      PUMGui.Show("Minimize")
      PUMhParent := PUMGui.Hwnd
      WinActivate("ahk_id " PUMhParent)
      pumAPI._msgMonitor(true)
      pumAPI.SetTimer(PUM_MenuCheck, 100)
    } else {
      if !IsSet(PUMGui) {
        ; PUMGui := Gui("+ToolWindow +AlwaysOnTop")
        PUMGui := Gui("+LastFoundExist")
        PUMGui.Title := "PUM_Menu2"
        ; PUMGui.Show("NoActivate w0 h0 x-32000 y-32000")
        PUMGui.Show("Minimize")
      }
      PUMhParent := PUMGui.Hwnd
    }
    this.objPUM.IsMenuShown := true
    itemID := pumAPI._TrackPopupMenuEx(this.handle, tpmflags, x, y, PUMhParent)
    this.objPUM.IsMenuShown := false
    if itemID {
      item := this.objPUM._items[itemID]
      if item {
        foo := this.objPUM.onrun
        if foo {
           if IsObject(foo)
             foo.Call("onrun", item)
           else if (Type(foo) = "String") {
             try cb := %foo%
             if cb
               cb.Call("onrun", item)
           }
        }
      }
    }
    
    if !isContext {
      pumAPI._msgMonitor(false)
      pumAPI.DestroyWindow(PUMhParent)
      foo := this.objPUM.onclose
      if foo {
         if IsObject(foo)
           foo.Call("onclose", this)
         else if (Type(foo) = "String") {
           try cb := %foo%
           if cb
             cb.Call("onclose", this)
         }
      }
    }
    return item
  }
  
  Add(params := "", pos := -1, fByPos := true) {
    if !this.alive
      return 0
    id := ++this.objPUM._itemsCount
    item := PUM_Item(id, this)
    this.objPUM._items[id] := item
    item.SetParams(params, pos, fByPos)
    return item
  }
  
  SetParams(params) {
    if !this.alive
      return 0
    if IsObject(params) {
      if params.HasOwnProp("tcolor")
        this.tcolor := params.tcolor
      if params.HasOwnProp("bgcolor")
        this.bgcolor := params.bgcolor
      if params.HasOwnProp("nocolors")
        this.nocolors := params.nocolors
      if params.HasOwnProp("noicons")
        this.noicons := params.noicons
      if params.HasOwnProp("notext")
        this.notext := params.notext
      if params.HasOwnProp("iconssize")
        this.iconssize := params.iconssize
      if params.HasOwnProp("textoffset")
        this.textoffset := params.textoffset
      if params.HasOwnProp("maxHeight")
        this.maxHeight := params.maxHeight
      if params.HasOwnProp("xmargin")
        this.xmargin := params.xmargin
      if params.HasOwnProp("ymargin")
        this.ymargin := params.ymargin
      if params.HasOwnProp("textMargin")
        this.textMargin := params.textMargin
      if !pumAPI.isEmpty(params.tcolor)
        this.tcolor := pumAPI.RGBtoBGR(this.tcolor)
      if !pumAPI.isEmpty(params.bgcolor)
        this.bgcolor := pumAPI.RGBtoBGR(this.bgcolor)
    }
    this._update()
  }
  
  _update() {
    this.Free()
        ;typedef struct MENUINFO {
    ;  DWORD   cbSize;				0
    ;  DWORD   fMask;				  4
    ;  DWORD   dwStyle;				8
    ;  UINT    cyMax;				  12
    ;  HBRUSH  hbrBack;				16
    ;  DWORD   dwContextHelpID;		16+ptr
    ;  ULONG_PTR  dwMenuData;		16+2ptr
    ;								16+3ptr
    if (pumAPI.IsInteger(this.bgcolor) && !this.nocolors)
      clr := this.bgcolor
    else
      clr := PUM_Menu._defaults.bgcolor

    fMask := 0
    fMask |= pumAPI.MIM_BACKGROUND
    fMask |= pumAPI.MIM_MAXHEIGHT
    fMask |= pumAPI.MIM_MENUDATA
    
    cbSize := pumAPI.MENUINFOsize
    struct := Buffer(cbSize, 0)
    NumPut("UInt", cbSize, struct, 0)
    NumPut("UInt", fMask, struct, 4)
    NumPut("UInt", this.maxHeight, struct, 12)
    NumPut("UPtr", this.objPUM.GetBrush(clr), struct, 16)
    NumPut("UPtr", ObjPtr(this), struct, 16 + 2 * A_PtrSize)
    pumAPI._SetMenuInfo(this.handle, struct.Ptr)
  }
}

PUM_MenuCheck(p*) {
  global PUMhParent
  if PUMhParent && !WinActive("ahk_id " PUMhParent) {
    pumAPI._EndMenu()
    pumAPI.SetTimer(A_ThisFunc, "OFF")
  }
  return
}

;handler of WM_ENTERMENULOOP message
PUM_OnEnterLoop(wParam, lParam, msg, hwnd) {
  return 0
}

;handler of WM_EXITMENULOOP	message
PUM_OnExitLoop(wParam, lParam, msg, hwnd) {
  return 0
}

;not currently used
PUM_OnMButtonDown(wParam, lParam, msg, hwnd) {
  x := lParam & 0xFFFF
  y := lParam >> 16
  isCtrl := wParam & 0x0008
  isLMB := wParam & 0x0001
  isMMB := wParam & 0x0010
  isRMB := wParam & 0x0002
  isShift := wParam & 0x0004
  isXB1 := wParam & 0x0020
  isXB2 := wParam & 0x0040
  ToolTip(x " - " y "`nCtrl " isCtrl "`nLMB " isLMB "`nIsMMB " isMMB "`nIsRMB " isRMB "`nIsShift " isShift "`nIsXB1 " isXB1 "`nIsXB2 " isXB2)
}

;handler of WM_CONTEXTMENU message
PUM_OnRButtonUp(wParam, lParam, msg, hwnd) {
  if item := pumAPI._GetItem(lParam, wParam) {
    foo := item.menu.objPUM.onrbutton
    if foo != "" {
      cb := 0
      if IsObject(foo)
        cb := foo
      else if (Type(foo) = "String")
        try cb := %foo%
      if cb
        cb.Call("onrbutton", item)
    }
  }
  return 0
}

;handler of WM_INITMENUPOPUP message
PUM_OnInit(wParam, lParam, msg, hwnd) {
  hMenu := wParam
  menu := pumAPI._GetMenuFromHandle(hMenu)
  foo := menu.objPUM.oninit
  if foo != "" {
    cb := 0
    if IsObject(foo)
      cb := foo
    else if (Type(foo) = "String")
      try cb := %foo%
    if cb
      cb.Call("oninit", menu)
  }
  return 0
}

;handler of WM_UNINITMENUPOPUP message
PUM_OnUninit(wParam, lParam, msg, hwnd) {
  hMenu := wParam
  menu := pumAPI._GetMenuFromHandle(hMenu)
  foo := menu.objPUM.onuninit
  if foo != "" {
    cb := 0
    if IsObject(foo)
      cb := foo
    else if (Type(foo) = "String")
      try cb := %foo%
    if cb
      cb.Call("onuninit", menu)
  }
  return 0
}

;handler of WM_MENUCHAR message
PUM_OnMenuChar(wParam, lParam, msg, hwnd) {
  charCode := wParam & 0xFFFF
  type := wParam >> 16
  hMenu := lParam
  itemsList := pumAPI._GetMenuItems(hMenu)
  itemPos := ""
  foundItem := ""
  for i, item in itemsList {
    if (item.hotCharCode == charCode) {
      itemPos := i - 1
      foundItem := item
      break
    }
  }
  if (itemPos = "") {
    for i, item in itemsList {
      if pumAPI.isEmpty(hotChar := SubStr(item.name, 1, 1))
        continue
      hotChar := StrLower(hotChar)
      if (Ord(hotChar) == charCode) {
        itemPos := i - 1
        foundItem := item
        break
      }
    }
  }
  if (itemPos != "") {
    mode := foundItem.menu.objPUM.mnemonicCmd = "select" ? 3 : 2
    return (mode << 16) | itemPos
  }
  return 0
}

;handler of WM_MENUSELECT, WM_MBUTTONDOWN messages
PUM_OnSelect(wParam, lParam, msg, hwnd) {
  static hMenu, nItem, fByPosition
  if (msg = 0x207) {
    if item := pumAPI._GetItem(hMenu, nItem, fByPosition) {
      foo := item.menu.objPUM.onmbutton
      if foo != "" {
        cb := 0
        if IsObject(foo)
          cb := foo
        else if (Type(foo) = "String")
          try cb := %foo%
        if cb
          cb.Call("onmbutton", item)
      }
    }
    return 0
  }
  nItem := wParam & 0xFFFF
  state := wParam >> 16
  isSubMenu := state & 0x10
  hMenu := lParam
  if isSubMenu
    fByPosition := true
  else
    fByPosition := false
  if item := pumAPI._GetItem(hMenu, nItem, fByPosition) {
    foo := item.menu.objPUM.onselect
    if foo != "" {
      cb := 0
      if IsObject(foo)
        cb := foo
      else if (Type(foo) = "String")
        try cb := %foo%
      if cb
        cb.Call("onselect", item)
    }
    return 0
  }
  return 0
}

;handler of WM_DRAWITEM message
PUM_OnDraw(wParam, lParam, msg, hwnd) {
  Critical
  sepRect := Buffer(16, 0)
  frameRect := Buffer(16, 0)
  textRect := Buffer(16, 0)
  tmpArrowR := Buffer(16, 0)
  ;~ typedef struct tagDRAWITEMSTRUCT {
  ;~ UINT      CtlType;		    0
  ;~ UINT      CtlID;			4
  ;~ UINT      itemID;			8
  ;~ UINT      itemAction;		12
  ;~ UINT      itemState;		16
  ;~ HWND      hwndItem;		16+ptr
  ;~ HDC       hDC;			    16+2ptr
  ;~ RECT      rcItem;			
  ;~ left						16+3ptr
  ;~ top						20+3ptr
  ;~ right						24+3ptr
  ;~ bottom					    28+3ptr
  ;~ ULONG_PTR itemData;		32+3ptr
  ;~                            32+4ptr
  if (wParam != 0)
    return
  ;~ ctlType := NumGet( lParam + 0, 0, "UInt" )
  ;~ if ( ctlType != 1 )  ;ODT_MENU - again check this is menu
    ;~ return
  itemData := NumGet(lParam + 0, 32 + 3 * A_PtrSize, "UPtr")
  item := ObjFromPtrAddRef(itemData)
  itemAction := NumGet(lParam + 0, 12, "UInt")
  itemState := NumGet(lParam + 0, 16, "UInt")
  hDC := NumGet(lParam + 0, 16 + 2 * A_PtrSize, "UPtr")
  pRECT := lParam + 16 + 3 * A_PtrSize
  left := NumGet(pRECT + 0, 0, "UInt")
  top := NumGet(pRECT + 0, 4, "UInt")
  right := NumGet(pRECT + 0, 8, "UInt")
  bottom := NumGet(pRECT + 0, 12, "UInt")
  
  m := IsObject(item.menu) ? item.menu : PUM_Menu._defaults
  tcolor := m.nocolors ? PUM_Menu._defaults.tcolor
            : item.disabled ? pumAPI.GetSysColor(17)
            : (!pumAPI.IsEmpty(item.tcolor) ? item.tcolor : m.tcolor)
  bgcolor := !m.nocolors ? (!pumAPI.IsEmpty(item.bgcolor) ? item.bgcolor : m.bgcolor)
            : PUM_Menu._defaults.bgcolor
  selMethod := IsObject(item.menu) ? item.menu.objPUM.selMethod : PUM._defaults.selMethod
  selBGColor := IsObject(item.menu) ? item.menu.objPUM.selBGColor : PUM._defaults.selBGColor
  selBGColor := selBGColor = -1 ? ~bgcolor & 0xFFFFFF : selBGColor
  selTColor := item.disabled ? pumAPI.GetSysColor(17)
              : (IsObject(item.menu) ? item.menu.objPUM.selTColor : PUM._defaults.selTColor)
  selTColor := selTColor = -1 ? ~tcolor & 0xFFFFFF : selTColor
  isItemSelected := (itemState & 1)
  
  itemNoIcons := item.noicons = -1 ? m.noicons : item.noicons
  itemNoText := item.notext = -1 ? m.notext : item.notext
  
  if (itemAction = pumAPI.ODA_FOCUS)
    return true
  else ;ODA_DRAWENTIRE | ODA_SELECT
  {
    if item.issep {
      pumAPI.SetRect(sepRect, left, top, right, bottom)
      NumPut("UInt", top + 1, sepRect, 4)
      pumAPI.DrawEdge(hDC, sepRect.Ptr)
    } else {
      if ((itemAction = pumAPI.ODA_SELECT && selMethod = "fill") || (itemAction = pumAPI.ODA_DRAWENTIRE && !pumAPI.IsEmpty(item.bgcolor))) {
        clr := isItemSelected ? selBGColor : bgcolor
        pumAPI.FillRect(hDC, pRECT, clr)
      }
      if (selMethod = "fill" && isItemSelected)
        pumAPI.FillRect(hDC, pRECT, selBGColor)
      if (selMethod = "frame" && itemAction = pumAPI.ODA_SELECT) {
        clr := isItemSelected ? selBGColor : bgcolor
        Loop item.menu.objPUM.frameWidth {
          pumAPI.SetRect(frameRect, left, top, right, bottom)
          infNum := -1 - (A_Index - 1)
          pumAPI.InflateRect(frameRect.Ptr, infNum, infNum)
          pumAPI.FrameRect(hDC, frameRect.Ptr, clr)
        }
      }
      if (!itemNoText && ((itemAction = pumAPI.ODA_SELECT && selMethod = "fill") || itemAction = pumAPI.ODA_DRAWENTIRE)) {
        tClr := isItemSelected ? selTColor : tcolor
        bClr := isItemSelected ? selBGColor : bgcolor
        pumAPI.SetBkColor(hDC, bClr)
        hfontOld := pumAPI.SelectObject(hDC, item.hfont)
        textFlags := 0x4 | 0x20 | 0x100 | (item.noPrefix ? 0x800 : 0)
        tleft := left
                  + (itemNoIcons ? 0 : m.iconssize + m.textoffset)
                  + m.xmargin
        tright := right - (item.assocMenu ? 15 : 0) - m.xmargin
        ttop := top + m.ymargin
        tbot := bottom - m.ymargin
        pumAPI.SetTextColor(hDC, tClr)
        pumAPI.SetRect(textRect, tleft, ttop, tright, tbot)
        pumAPI.DrawText(hDC, item.name, textRect.Ptr, textFlags)
        pumAPI.SelectObject(hDC, hfontOld)
      }
      if (!itemNoIcons && item.GetIconHandle()
          && ((itemAction = pumAPI.ODA_SELECT && selMethod = "fill") || itemAction = pumAPI.ODA_DRAWENTIRE)) {
        pumAPI.DrawIconEx(hDC
                    , left + m.xmargin
                    , top + item._y_icon
                    , item.GetIconHandle())
      }
      if item.assocMenu
          && ((itemAction = pumAPI.ODA_SELECT && selMethod = "fill") || itemAction = pumAPI.ODA_DRAWENTIRE) {
        bmWidth := 15
        bmHeight := bottom - top
        bmY := Round(top - ((bottom - top) - bmHeight) / 2)
        bmX := Round(right - 15)
        arrowDC := pumAPI.CreateCompatibleDC(hDC)
        fillDC := pumAPI.CreateCompatibleDC(hDC)
        arrowBM := pumAPI.CreateCompatibleBitmap(hDC, bmWidth, bmHeight)
        fillBM := pumAPI.CreateCompatibleBitmap(hDC, bmWidth, bmHeight)
        oldArrowBitmap := pumAPI.SelectObject(arrowDC, arrowBM)
        oldFillBitmap := pumAPI.SelectObject(fillDC, fillBM)
        pumAPI.SetRect(tmpArrowR, 0, 0, bmWidth, bmHeight)
        pumAPI.DrawFrameControl(arrowDC, tmpArrowR.Ptr, 2, 0)
        clr := isItemSelected ? selTColor : tcolor
        pumAPI.FillRect(fillDC, tmpArrowR.Ptr, clr)
        pumAPI.BitBlt(hDC, bmX, bmY, bmWidth, bmHeight, fillDC, 0, 0, 0x00660046)
        pumAPI.BitBlt(hDC, bmX, bmY, bmWidth, bmHeight, arrowDC, 0, 0, 0x008800C6)
        pumAPI.BitBlt(hDC, bmX, bmY, bmWidth, bmHeight, fillDC, 0, 0, 0x00660046)
        pumAPI.SelectObject(arrowDC, oldArrowBitmap)
        pumAPI.SelectObject(fillDC, oldFillBitmap)
        pumAPI.DeleteObject(arrowBM)
        pumAPI.DeleteObject(fillBM)
        pumAPI.DeleteDC(arrowDC)
        pumAPI.DeleteDC(fillDC)
      }
    }
  }
  pumAPI.ExcludeClipRect(hDC, left, top, right, bottom)
  return true
}

  ;handler of WM_MEASUREITEM message
PUM_OnMeasure(wParam, lParam, msg, hwnd) {
  Critical
  ;~ typedef struct MEASUREITEMSTRUCT {
  ;~ UINT      CtlType;         0
  ;~ UINT      CtlID;           4
  ;~ UINT      itemID;          8
  ;~ UINT      itemWidth;       12
  ;~ UINT      itemHeight;      16
  ;~ ULONG_PTR itemData;        16+ptr
  ;                             16+2ptr
  if (wParam != 0)
    return
  ;~ CtlType := NumGet( lParam+0, 0, "UInt" )
  ;~ if ( CtlType != 1 ) ;not a menu
    ;~ return
  itemData := NumGet(lParam + 0, 16 + A_PtrSize, "UPtr")
  item := ObjFromPtrAddRef(itemData)
  if item.issep
    h := 4, w := 0
  else {
    m := IsObject(item.menu) ? item.menu : PUM_Menu._defaults
    itemNoIcons := item.noicons = -1 ? m.noicons : item.noicons
    itemNoText := item.notext = -1 ? m.notext : item.notext
    hDC := pumAPI.GetDC(hwnd)
    hOldFont := pumAPI.SelectObject(hDC, item.hfont)
    size := pumAPI.GetTextExtentPoint32(hDC, item.name)
    w := itemNoIcons ? size.cx
        : itemNoText ? m.iconssize - 11
        : m.iconssize + m.textoffset + size.cx
    w += m.xmargin * 2
    if item.submenu
      w += 10
    else if !itemNoText
      w += m.textMargin
    h := itemNoIcons ? size.cy
        : itemNoText ? m.iconssize
        : pumAPI.max(m.iconssize, size.cy)
    h += m.ymargin * 2
    minH := m.iconssize + m.ymargin * 2
    if (h < minH)
      h := minH
    if (h < 18)
      h := 18
    if (w < 50)
      w := 50
    ; 为避免菜单过小，强制给一个足够大的基础尺寸
    if (w < 200)
      w := 200
    if (h < 30)
      h := 30
    item._y_icon := Round((h - m.iconssize) / 2)
    pumAPI.SelectObject(hDC, hOldFont)
    pumAPI.ReleaseDC(hDC, hwnd)
  }
  NumPut("UInt", w, lParam + 0, 12)
  NumPut("UInt", h, lParam + 0, 16)
  return true
}
;-------------------------------------------------------------------------------

/* 
PUM_API v2 is implemented in AutoHotkey V2, by Sunwind (2026-01-15).

PUM_API - The main function of PUM_API is to call the Windows API (TrackPopupMenuEx) to implement an owner-drawn menu.

 reference to the following documentation，from the archived forums:
 https://www.autohotkey.com/board/topic/73599-ahk-l-pum-owner-drawn-object-based-popup-menu/
*/
class PUM_base
{
  __Call(aTarget, aParams*) {
    if PUM_base.HasOwnProp(aTarget)
      return PUM_base.%aTarget%(this, aParams*)
    throw Error("Unknown function '" aTarget "' requested from object '" this.__Class "'")
  }
  
  Err(msg) {
    throw Error(this.__Class " : " msg (A_LastError != 0 ? "`n" this.ErrorFormat(A_LastError) : ""))
  }
  
  ErrorFormat(error_id) {
    buf := Buffer(1000, 0)
    len := DllCall(
      "FormatMessageW",
      "UInt", 0x00001000 | 0x00000200,
      "Ptr", 0,
      "UInt", error_id,
      "UInt", 0,
      "Ptr", buf,
      "UInt", 500,
      "UInt", 0,
      "UInt"
    )
    if !len
      return
    return StrGet(buf, len, "UTF-16")
  }

  static Err(msg) {
    throw Error(this.__Class " : " msg (A_LastError != 0 ? "`n" this.ErrorFormat(A_LastError) : ""))
  }
  
  static ErrorFormat(error_id) {
    buf := Buffer(1000, 0)
    len := DllCall(
      "FormatMessageW",
      "UInt", 0x00001000 | 0x00000200,
      "Ptr", 0,
      "UInt", error_id,
      "UInt", 0,
      "Ptr", buf,
      "UInt", 500,
      "UInt", 0,
      "UInt"
    )
    if !len
      return
    return StrGet(buf, len, "UTF-16")
  }
}

class pumAPI_base extends PUM_base
{
  __Get(name, params) {
    if !this.HasOwnProp("initialized") {
      this.Init()
      return this.%name%
    }
    throw Error("Unknown field '" name "' requested from object '" this.__Class "'")
  }
}

class pumAPI extends pumAPI_base
{
  static __New() {
    this.Init()
  }

  static Init() {
    this.LoadDllFunction("User32.dll", "DrawIconEx")
    this.LoadDllFunction("Gdi32.dll", "ExcludeClipRect")
    this.LoadDllFunction("Gdi32.dll", "SetBkColor")
    this.LoadDllFunction("Gdi32.dll", "SetTextColor")
    this.LoadDllFunction("User32.dll", "FrameRect")
    this.LoadDllFunction("User32.dll", "InflateRect")
    this.LoadDllFunction("User32.dll", "DrawEdge")
    this.LoadDllFunction("Gdi32.dll", "DeleteDC")
    this.LoadDllFunction("User32.dll", "ReleaseDC")
    this.LoadDllFunction("Gdi32.dll", "BitBlt")
    this.LoadDllFunction("User32.dll", "FillRect")
    this.LoadDllFunction("Gdi32.dll", "CreateCompatibleDC")
    this.LoadDllFunction("Gdi32.dll", "CreateCompatibleBitmap")
    this.LoadDllFunction("User32.dll", "SetRect")
    this.LoadDllFunction("User32.dll", "DrawFrameControl")
    this.LoadDllFunction("User32.dll", "GetSysColorBrush")
    this.LoadDllFunction("User32.dll", "GetSysColor")
    this.LoadDllFunction("Gdi32.dll", "CreateSolidBrush")
    this.LoadDllFunction("Gdi32.dll", "DeleteObject")
    this.LoadDllFunction("Gdi32.dll", "SelectObject")
    this.LoadDllFunction("User32.dll", "GetDC")
    this.LoadDllFunction("Gdi32.dll", "GetTextExtentPoint32W")
    this.LoadDllFunction("User32.dll", "CopyImage")
    this.LoadDllFunction("user32.dll", "PrivateExtractIconsW")
    this.LoadDllFunction("user32.dll", "DestroyIcon")
    this.LoadDllFunction("user32.dll", "SystemParametersInfoW")
    this.LoadDllFunction("Gdi32.dll", "CreateFontIndirectW")
    this.LoadDllFunction("gdiplus.dll", "GdiplusStartup")
    this.LoadDllFunction("gdiplus.dll", "GdiplusShutdown")
    this.LoadDllFunction("gdiplus.dll", "GdipCreateBitmapFromFileICM")
    this.LoadDllFunction("gdiplus.dll", "GdipCreateHICONFromBitmap")
    this.LoadDllFunction("gdiplus.dll", "GdipDisposeImage")
    this.LoadDllFunction("User32.dll", "DrawTextExW")
    this.LoadDllFunction("User32.dll", "DestroyWindow")
    
    this.LoadDllFunction("User32.dll", "GetMenuItemRect")
    this.LoadDllFunction("User32.dll", "CreatePopupMenu")
    this.LoadDllFunction("User32.dll", "DestroyMenu")
    this.LoadDllFunction("User32.dll", "DeleteMenu")
    this.LoadDllFunction("User32.dll", "RemoveMenu")
    this.LoadDllFunction("User32.dll", "SetMenuInfo")
    this.LoadDllFunction("User32.dll", "SetMenuItemInfoW")
    this.LoadDllFunction("User32.dll", "GetMenuItemInfoW")
    this.LoadDllFunction("User32.dll", "GetMenuInfo")
    this.LoadDllFunction("User32.dll", "GetMenuItemCount")
    this.LoadDllFunction("User32.dll", "GetMenuItemID")
    this.LoadDllFunction("User32.dll", "GetSubMenu")
    this.LoadDllFunction("User32.dll", "IsMenu")
    this.LoadDllFunction("User32.dll", "EndMenu")
    this.LoadDllFunction("User32.dll", "InsertMenuItemW")
    this.LoadDllFunction("User32.dll", "TrackPopupMenuEx")
    this.LoadDllFunction("Gdi32.dll", "GetDeviceCaps")
    this.LoadDllFunction("Kernel32.dll", "MulDiv")
    this.LoadDllFunction("Shlwapi.dll", "PathFindExtensionW")
    this.initialized := true
  }
  
  static LoadDllFunction(file, function) {
    hModule := DllCall("GetModuleHandleW", "WStr", file, "UPtr")
    if !hModule
      hModule := DllCall("LoadLibraryW", "WStr", file, "UPtr")
    ret := DllCall("GetProcAddress", "Ptr", hModule, "AStr", function, "UPtr")
    if !ret
      this.Err("Could not load function '" function "'")
    this.DefineProp("p" function, {Value: ret})
  }
  
  static SetTimer(funcOrName, time := "") {
    static st_timers := Map(), st_cb := Map()
    fn := 0
    key := IsObject(funcOrName) ? funcOrName.Name : funcOrName
    if st_timers.Has(key) {
      if (time = "")
        return st_timers[key]
      if (time = "OFF" || time = 0) {
        DllCall("KillTimer", "Ptr", 0, "UInt", st_timers[key].tID)
        st_timers.Delete(key)
        return
      }
      DllCall("KillTimer", "Ptr", 0, "UInt", st_timers[key].tID)
      st_timers.Delete(key)
    }
    if IsInteger(time) {
      if (time != 0) {
        if !IsObject(funcOrName) {
          try fn := Func(funcOrName)
          catch {
            throw Error("Non existent function used for timer: " funcOrName)
          }
        } else {
          fn := funcOrName
        }
        ;CallbackCreate(fn, , 4) （留空 Options 参数）。意图是指定参数个数为 4。
        cb := st_cb.Has(key) ? st_cb[key] : (st_cb[key] := CallbackCreate(fn, , 4))
        timerID := DllCall("SetTimer", "Ptr", 0, "UInt", 0, "UInt", Abs(time), "Ptr", cb, "UInt")
        st_timers[key] := {tID: timerID, delay: time}
      }
    }
  }
  
  
  static DrawIconEx(hDC, xLeft, yTop, hIcon) {
    return DllCall(this.pDrawIconEx, "Ptr", hDC, "Int", xLeft, "Int", yTop, "Ptr", hIcon, "Int", 0, "Int", 0, "UInt", 0, "Ptr", 0, "UInt", 3)
  }
  static ExcludeClipRect(hDC, left, top, right, bottom) {
    return DllCall(this.pExcludeClipRect, "Ptr", hDC, "Int", left, "Int", top, "Int", right, "Int", bottom)
  }
  static SetBkColor(hDC, clr) {
    return DllCall(this.pSetBkColor, "Ptr", hDC, "UInt", clr)
  }
  static SetTextColor(hDC, clr) {
    return DllCall(this.pSetTextColor, "Ptr", hDC, "UInt", clr)
  }
  static FrameRect(hDC, pRECT, clr) {
    hBrush := this.CreateSolidBrush(clr)
    ret := DllCall(this.pFrameRect, "Ptr", hDC, "Ptr", pRECT, "Ptr", hBrush)
    this.DeleteObject(hBrush)
    return ret
  }
  static InflateRect(pRECT, x, y) {
    return DllCall(this.pInflateRect, "Ptr", pRECT, "Int", x, "Int", y)
  }
  static DrawEdge(hDC, pRECT) {
    return DllCall(this.pDrawEdge, "Ptr", hDC, "Ptr", pRECT, "UInt", (0x0002 | 0x0004), "UInt", 0x0002)
  }
  static DeleteDC(hDC) {
    return DllCall(this.pDeleteDC, "Ptr", hDC)
  }
  static ReleaseDC(hDC, hWnd) {
    return DllCall(this.pReleaseDC, "Ptr", hWnd, "Ptr", hDC)
  }
  static BitBlt(hdcDest, nXDest, nYDest, nWidth, nHeight, hdcSrc, nXSrc, nYSrc, dwRop) {
    return DllCall(this.pBitBlt, "Ptr", hdcDest, "UInt", nXDest, "UInt", nYDest, "UInt", nWidth, "UInt", nHeight, "Ptr", hdcSrc, "UInt", nXSrc, "UInt", nYSrc, "UInt", dwRop)
  }
  static FillRect(hDC, pRECT, Clr) {
    hBrush := this.CreateSolidBrush(Clr)
    ret := DllCall(this.pFillRect, "Ptr", hDC, "Ptr", pRECT, "Ptr", hBrush)
    this.DeleteObject(hBrush)
    return ret
  }
  static CreateCompatibleDC(hDC) {
    return DllCall(this.pCreateCompatibleDC, "Ptr", hDC)
  }
  static CreateCompatibleBitmap(hDC, w, h) {
    return DllCall(this.pCreateCompatibleBitmap, "Ptr", hDC, "UInt", w, "UInt", h)
  }
  static SetRect(rect, left, top, right, bottom) {
    NumPut("UInt", left, rect, 0)
    NumPut("UInt", top, rect, 4)
    NumPut("UInt", right, rect, 8)
    NumPut("UInt", bottom, rect, 12)
    return DllCall(this.pSetRect, "Ptr", rect, "UInt", left, "UInt", top, "UInt", right, "UInt", bottom)
  }
  static DrawFrameControl(hDC, pRECT, uType, uState) {
    return DllCall(this.pDrawFrameControl, "Ptr", hDC, "Ptr", pRECT, "UInt", uType, "UInt", uState)
  }
  static GetSysColorBrush(nIndex) {
    return DllCall(this.pGetSysColorBrush, "UInt", nIndex)
  }
  static GetSysColor(nIndex) {
    return DllCall(this.pGetSysColor, "UInt", nIndex)
  }
  static CreateSolidBrush(clr) {
    return DllCall(this.pCreateSolidBrush, "UInt", clr)
  }
  static DeleteObject(hObj) {
    return DllCall(this.pDeleteObject, "Ptr", hObj)
  }
  static SelectObject(hDC, hObj) {
    if !hObj
      return 0
    return DllCall(this.pSelectObject, "Ptr", hDC, "Ptr", hObj)
  }
  static GetDC(hwnd) {
    return DllCall(this.pGetDC, "Ptr", hwnd)
  }
  static GetTextExtentPoint32(hDC, string) {
    buf := Buffer(8, 0)
    DllCall(this.pGetTextExtentPoint32W, "Ptr", hDC, "Ptr", StrPtr(string), "UInt", StrLen(string), "Ptr", buf)
    return {cx: NumGet(buf, 0, "UInt"), cy: NumGet(buf, 4, "UInt")}
  }
  static max(var1, var2) {
    return var1 > var2 ? var1 : var2
  }
  static IsInteger(var) {
    return IsInteger(var)
  }
  static isEmpty(var) {
    return (var = "")
  }
  static IconGetPath(Ico) {
    spec := Ico
    pos := InStr(Ico, ":",, -1)
    if (pos > 4)
      spec := SubStr(Ico, 1, pos - 1)
    return this.PathUnquoteSpaces(spec)
  }
  static IconGetIndex(Ico) {
    pos := InStr(Ico, ":",, -1)
    if (pos > 4) {
      ind := SubStr(Ico, pos + 1)
      if ind = ""
        ind := 0
      return ind
    }
  }
  static IconCopy(handle, size, type := 1, flags := 0x8) {
    return DllCall(this.pCopyImage, "Ptr", handle, "UInt", type, "Int", size, "Int", size, "UInt", flags)
  }
  static IconExtract(icoPath, size := 32) {
    pPath := this.IconGetPath(icoPath)
    pNum := this.IconGetIndex(icoPath)
    pNum := pNum = "" ? 0 : pNum
    handle := 0
    DllCall(this.pPrivateExtractIconsW, "WStr", pPath, "UInt", pNum, "UInt", size, "UInt", size, "Ptr*", &handle, "Ptr", 0, "UInt", 1, "UInt", 0)
    if !handle {
      SplitPath(pPath, , , &Ext)
      if (Ext = "exe")
        DllCall(this.pPrivateExtractIconsW, "WStr", "shell32.dll", "UInt", 2, "UInt", size, "UInt", size, "Ptr*", &handle, "Ptr", 0, "UInt", 1, "UInt", 0)
    }
    return handle
  }
  static PathUnquoteSpaces(path) {
    path := Trim(path)
    if RegExMatch(path, '^\s*"+(.*?)"+\s*$', &match)
      path := match[1]
    return path
  }
  static PathFindExtension(sPath) {
    return DllCall(this.pPathFindExtensionW, "Ptr", StrPtr(sPath), "Ptr")
  }
  static PathGetExt(sPath) {
    sPath := this.PathUnquoteSpaces(sPath)
    if this.isEmpty(sPath)
      return ""
    ext := StrGet(this.PathFindExtension(sPath), "UTF-16")
    return SubStr(ext, 2)
  }
  static DestroyIcon(hIcon) {
    return DllCall(this.pDestroyIcon, "Ptr", hIcon)
  }
  static Free(&var) {
    var := ""
  }
  static GetSysFont(&LOGFONT) {
    buf := Buffer(92, 0)
    ok := DllCall(this.pSystemParametersInfoW, "UInt", 0x001F, "UInt", 92, "Ptr", buf, "UInt", 0, "UInt")
    if !ok
      return 0
    LOGFONT := buf
    return buf.Ptr
  }
  static CreateFontIndirect(pLOGFONT) {
    return DllCall(this.pCreateFontIndirectW, "Ptr", pLOGFONT)
  }
  static StrSplit(str, delim, omit := "") {
    return StrSplit(str, delim, omit)
  }
  static Gdip_Startup() {
    ;A_PtrSize 32位系统为 4, 64位系统为 8
    ;3*A_PtrSize = 12, 24
    ;在32位系统下, GdiplusStartupInput 占用 12 字节是不够的，所以统一定义成24字节。
    GdiplusStartupInput := Buffer(24, 0)
    NumPut("UInt", 1, GdiplusStartupInput, 0)
    DllCall(this.pGdiplusStartup, "Ptr*", &pToken := 0, "Ptr", GdiplusStartupInput, "Ptr", 0)
    return pToken
  }
  static Gdip_Shutdown(pToken) {
    DllCall(this.pGdiplusShutdown, "Ptr", pToken)
    return 0
  }
  static RGBtoBGR(bgr_clr) {
    return (bgr_clr & 0xFF0000) >> 16 | (bgr_clr & 0x00FF00) | (bgr_clr & 0x0000FF) << 16
  }
  static DrawText(hDC, text, pRect, flags) {
    return DllCall(this.pDrawTextExW, "Ptr", hDC, "WStr", text, "UInt", -1, "Ptr", pRect, "UInt", flags, "Ptr", 0)
  }
  static DestroyWindow(hwnd) {
    return DllCall(this.pDestroyWindow, "Ptr", hwnd)
  }
  static GetDeviceCaps(hWnd := 0, flags := 90) {
    return DllCall(this.pGetDeviceCaps, "Ptr", DllCall("GetDC", "Ptr", hWnd, "Ptr"), "UInt", flags, "Int")
  }
  static MulDiv(a, b, c) {
    return DllCall(this.pMulDiv, "Int", a, "Int", b, "Int", c, "Int")
  }
  static obj2LOGFONT(obj, &LOGFONT) {
    if !IsObject(obj)
      obj := this.Str2Dict(obj)
    buf := Buffer(92, 0)
    if obj.HasOwnProp("height") {
      NumPut("Int", -this.MulDiv(Abs(obj.height), this.GetDeviceCaps(), 72), buf, 0)
    }
    if obj.HasOwnProp("width")
      NumPut("UInt", obj.width, buf, 4)
    if obj.HasOwnProp("Escapement")
      NumPut("UInt", obj.Escapement, buf, 8)
    if obj.HasOwnProp("Orientation")
      NumPut("UInt", obj.Orientation, buf, 12)
    if obj.HasOwnProp("Weight")
      NumPut("UInt", obj.Weight, buf, 16)
    if obj.HasOwnProp("Italic")
      NumPut("UChar", obj.Italic, buf, 20)
    if obj.HasOwnProp("Underline")
      NumPut("UChar", obj.Underline, buf, 21)
    if obj.HasOwnProp("strike")
      NumPut("UChar", obj.strike, buf, 22)
    if obj.HasOwnProp("OutPrecision")
      NumPut("UChar", obj.OutPrecision, buf, 24)
    if obj.HasOwnProp("ClipPrecision")
      NumPut("UChar", obj.ClipPrecision, buf, 25)
    if obj.HasOwnProp("PitchAndFamily")
      NumPut("UChar", obj.PitchAndFamily, buf, 27)
    if obj.HasOwnProp("CharSet")
      NumPut("UChar", obj.CharSet, buf, 23)
    if obj.HasOwnProp("Quality")
      NumPut("UChar", obj.Quality, buf, 26)
    if obj.HasOwnProp("name")
      StrPut(obj.name, buf.Ptr + 28, 32, "UTF-16")
    LOGFONT := buf
  }
  static LOGFONT2obj(&LOGFONT) {
    if !(LOGFONT is Buffer)
      return 0
    if LOGFONT.Size != 92
      return 0
    buf := LOGFONT
    obj := {}
    obj.height := Abs(this.MulDiv(Abs(NumGet(buf, 0, "Int")), 72, this.GetDeviceCaps()))
    obj.width := NumGet(buf, 4, "Int")
    obj.Escapement := NumGet(buf, 8, "Int")
    obj.Orientation := NumGet(buf, 12, "Int")
    obj.Weight := NumGet(buf, 16, "Int")
    obj.italic := NumGet(buf, 20, "UChar")
    obj.underline := NumGet(buf, 21, "UChar")
    obj.strike := NumGet(buf, 22, "UChar")
    obj.CharSet := NumGet(buf, 23, "UChar")
    obj.OutPrecision := NumGet(buf, 24, "UChar")
    obj.ClipPrecision := NumGet(buf, 25, "UChar")
    obj.Quality := NumGet(buf, 26, "UChar")
    obj.PitchAndFamily := NumGet(buf, 27, "UChar")
    obj.name := StrGet(buf.Ptr + 28, 32, "UTF-16")
    return obj
  }
  static Dict2Str(obj, delim := "|", separ := ":") {
    fstr := ""
    for key, val in obj
      fstr .= (fstr ? delim : "") key separ val
    return fstr
  }
  static Str2Dict(fstr, delim := "|", separ := ":") {
    obj := {}
    for i, pair in this.StrSplit(fstr, delim, A_Space A_Tab) {
      ar := this.StrSplit(pair, separ, A_Space A_Tab)
      if ar.Length >= 2
        obj.%ar[1]% := ar[2]
    }
    return obj
  }
  
  static _GetItemPosByID(hMenu, itemID) {
    nCount := this._GetMenuItemCount(hMenu)
    if (nCount != -1) {
      Loop nCount {
        nPos := A_Index - 1
        rID := this._GetMenuItemID(hMenu, nPos)
        if (rID = -1)
          rID := this._GetItem(hMenu, nPos).id
        if (itemID = rID)
          return nPos
      }
    }
    return -1
  }
  static _GetItemRect(hMenu, nPos) {
    RECT := Buffer(16, 0)
    if DllCall(this.pGetMenuItemRect, "Ptr", 0, "Ptr", hMenu, "UInt", nPos, "Ptr", RECT, "Int") {
      return {
        left: NumGet(RECT, 0, "UInt"),
        top: NumGet(RECT, 4, "UInt"),
        right: NumGet(RECT, 8, "UInt"),
        bottom: NumGet(RECT, 12, "UInt")
      }
    }
    return 0
  }
  static _GetMenuItems(hMenu) {
    arrItems := []
    nCount := this._GetMenuItemCount(hMenu)
    if (nCount != -1) {
      Loop nCount {
        nPos := A_Index - 1
        item := this._GetItem(hMenu, nPos)
        if item
          arrItems.Push(item)
      }
    }
    return arrItems
  }
  static _GetMenuFromHandle(hMenu) {
    cbSize := this.MENUINFOsize
    fMask := this.MIM_MENUDATA
    MENUINFO := Buffer(cbSize, 0)
    NumPut("UInt", cbSize, MENUINFO, 0)
    NumPut("UInt", fMask, MENUINFO, 4)
    this._GetMenuInfo(hMenu, &MENUINFO)
    objPtr := NumGet(MENUINFO, 16 + 2 * A_PtrSize, "UPtr")
    if objPtr
      return ObjFromPtrAddRef(objPtr)
  }
  
  static _GetItem(hMenu, nItem, fByPos := true) {
    cbsize := this.MENUITEMINFOsize
    MENUITEMINFO := Buffer(cbsize, 0)
    fMask := this.MIIM_DATA
    NumPut("UInt", cbsize, MENUITEMINFO, 0)
    NumPut("UInt", fMask, MENUITEMINFO, 4)
    if this._GetMenuItemInfo(hMenu, nItem, fByPos, &MENUITEMINFO) {
      objPtr := NumGet(MENUITEMINFO, 16 + 4 * A_PtrSize, "Ptr")
      if objPtr
        return ObjFromPtrAddRef(objPtr)
    }
  }
 
  static _loadIcon(pPath, pSize) {
    if !pPath
      return 0
    if this.IsInteger(pPath)
      return this.IconCopy(pPath, pSize, 1, 0)
    if (this.IconGetIndex(pPath) = "" && !(this.PathGetExt(pPath) ~= "i)^(ico|cur|ani)$")) {
      DllCall(this.pGdipCreateBitmapFromFileICM, "WStr", pPath, "Ptr*", &pBitmap)
      DllCall(this.pGdipCreateHICONFromBitmap, "Ptr", pBitmap, "Ptr*", &hIcon)
      DllCall(this.pGdipDisposeImage, "Ptr", pBitmap)
      hIcon := this.IconCopy(hIcon, pSize)
      return hIcon
    } else {
      return this.IconExtract(pPath, pSize)
    }
  }
 
  static _CreatePopupMenu() {
    return DllCall(this.pCreatePopupMenu, "Ptr")
  }
  static _DestroyMenu(hMenu) {
    return DllCall(this.pDestroyMenu, "Ptr", hMenu)
  }
  static _DeleteItem(hMenu, itemID, flag := 0) {
    return DllCall(this.pDeleteMenu, "Ptr", hMenu, "UInt", itemID, "UInt", flag ? 0x400 : 0)
  }
  static _RemoveItem(hMenu, itemID, flag := 0) {
    return DllCall(this.pRemoveMenu, "Ptr", hMenu, "UInt", itemID, "UInt", flag ? 0x400 : 0)
  }
  static _SetMenuInfo(hMenu, MENUINFO_ptr) {
    return DllCall(this.pSetMenuInfo, "Ptr", hMenu, "Ptr", MENUINFO_ptr)
  }
  static _SetMenuItemInfo(hMenu, itemID, fByPosition, MENUITEMINFO_ptr) {
    return DllCall(this.pSetMenuItemInfoW, "Ptr", hMenu, "UInt", itemID, "UInt", fByPosition, "Ptr", MENUITEMINFO_ptr)
  }
  static _GetMenuItemInfo(hMenu, uItem, fByPosition, &MENUITEMINFO) {
    return DllCall(this.pGetMenuItemInfoW, "Ptr", hMenu, "UInt", uItem, "UInt", fByPosition, "Ptr", MENUITEMINFO)
  }
  static _GetMenuInfo(hMenu, &MENUINFO) {
    return DllCall(this.pGetMenuInfo, "Ptr", hMenu, "Ptr", MENUINFO)
  }
  static _GetMenuItemCount(hMenu) {
    return DllCall(this.pGetMenuItemCount, "Ptr", hMenu, "Int")
  }
  static _GetMenuItemID(hMenu, nPos) {
    return DllCall(this.pGetMenuItemID, "Ptr", hMenu, "UInt", nPos, "Int")
  }
  static _GetSubMenu(hMenu, nPos) {
    return DllCall(this.pGetSubMenu, "Ptr", hMenu, "UInt", nPos, "Ptr")
  }
  static _IsMenu(hMenu) {
    return DllCall(this.pIsMenu, "Ptr", hMenu, "Int")
  }
  static _EndMenu() {
    return DllCall(this.pEndMenu)
  }
  static _insertMenuItem(hMenu, prevID, fByPos, MENUITEMINFO_ptr) {
    return DllCall(this.pInsertMenuItemW, "Ptr", hMenu, "UInt", prevID, "UInt", fByPos, "Ptr", MENUITEMINFO_ptr)
  }
  static _TrackPopupMenuEx(hMenu, uFlags, X, Y, hWnd) {
    return DllCall(this.pTrackPopupMenuEx, "Ptr", hMenu, "UInt", uFlags, "Int", X, "Int", Y, "Ptr", hWnd, "Ptr", 0, "UInt")
  }
  
  static _msgMonitor(state) {
    static WM_MENUSELECT := 0x11F
      , WM_MEASUREITEM := 0x2C
      , WM_DRAWITEM := 0x2B
      , WM_ENTERMENULOOP := 0x211
      , WM_INITMENUPOPUP := 0x117
      , WM_UNINITMENUPOPUP := 0x125
      , WM_EXITMENULOOP := 0x212
      , WM_MENUCOMMAND := 0x126
      , WM_MENURBUTTONUP := 0x0122
      , WM_CONTEXTMENU := 0x7B
      , WM_MBUTTONDOWN := 0x207
      , WM_MENUCHAR := 0x120
    
    static oldMeasure := 0, oldDraw := 0, oldrbutton := 0, oldMButton := 0, oldMenuChar := 0

    if state {
      OnMessage(WM_ENTERMENULOOP, PUM_OnEnterLoop)
      oldMeasure := OnMessage(WM_MEASUREITEM, PUM_OnMeasure)
      oldDraw := OnMessage(WM_DRAWITEM, PUM_OnDraw)
      OnMessage(WM_MENUSELECT, PUM_OnSelect)
      OnMessage(WM_INITMENUPOPUP, PUM_OnInit)
      OnMessage(WM_UNINITMENUPOPUP, PUM_OnUninit)
      oldrbutton := OnMessage(WM_MENURBUTTONUP, PUM_OnRButtonUp)
      oldMButton := OnMessage(WM_MBUTTONDOWN, PUM_OnSelect)
      oldMenuChar := OnMessage(WM_MENUCHAR, PUM_OnMenuChar)
      OnMessage(WM_EXITMENULOOP, PUM_OnExitLoop)
    } else {
      OnMessage(WM_ENTERMENULOOP, PUM_OnEnterLoop, 0)
      OnMessage(WM_MEASUREITEM, PUM_OnMeasure, 0)
      OnMessage(WM_DRAWITEM, PUM_OnDraw, 0)
      OnMessage(WM_INITMENUPOPUP, PUM_OnInit, 0)
      OnMessage(WM_MENUSELECT, PUM_OnSelect, 0)
      OnMessage(WM_EXITMENULOOP, PUM_OnExitLoop, 0)
      OnMessage(WM_UNINITMENUPOPUP, PUM_OnUninit, 0)
      OnMessage(WM_MENURBUTTONUP, PUM_OnRButtonUp, 0)
      OnMessage(WM_MBUTTONDOWN, PUM_OnSelect, 0)
      OnMessage(WM_MENUCHAR, PUM_OnMenuChar, 0)
    }
  }
  
  static MNS_AUTODISMISS := 0x10000000
    , MNS_CHECKORBMP := 0x04000000
    , MNS_DRAGDROP := 0x20000000
    , MNS_MODELESS := 0x40000000
    , MNS_NOCHECK := 0x80000000
    , MNS_NOTIFYBYPOS := 0x08000000
    , MFT_MENUBREAK := 0x00000040
    , MFT_MENUBARBREAK := 0x00000020
    , MFT_OWNERDRAW := 0x00000100
    , MFT_SEPARATOR := 0x00000800
    , MFT_RIGHTORDER := 0x00002000
    , MIIM_DATA := 0x00000020
    , MIIM_STRING := 0x00000040
    , MIIM_FTYPE := 0x00000100
    , MIIM_ID := 0x00000002
    , MIIM_STATE := 0x00000001
    , MIIM_SUBMENU := 0x00000004
    , MIIM_BITMAP := 0x00000080
    , MENUITEMINFOsize := 16 + 8 * A_PtrSize
    , MENUINFOsize := 16 + 3 * A_PtrSize
    , HBMMENU_CALLBACK := -1
    , MIM_BACKGROUND := 0x00000002
    , MIM_STYLE := 0x00000010
    , MIM_MAXHEIGHT := 0x00000001 
    , MIM_MENUDATA := 0x00000008
    , ODA_DRAWENTIRE := 0x0001
    , ODA_SELECT := 0x0002
    , ODA_FOCUS := 0x0004
    , MFS_DISABLED := 0x3
}
