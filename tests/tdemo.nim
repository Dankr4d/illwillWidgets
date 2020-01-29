import ../src/widgets
import illwill
import strformat, strutils
import asyncdispatch, httpclient# for async demonstration

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

illwillInit(fullscreen=true, mouseMode=TrackAny)
setControlCHook(exitProc)
hideCursor()

var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

var btnAsyncHttp = newButton("async http", 21, 3, 15, 2)
var btnTest = newButton("fill", 38, 3, 15, 2)
var btnClear = newButton("clear", 38, 6, 15, 2)
var chkTest = newCheckbox("Some content", 38, 9)
var chkTest2 = newCheckbox("Fill Color", 38, 10)
chkTest2.textUnchecked = ":)  "
chkTest2.textChecked =   ":(  "

var chkDraw = newCheckbox("Draw?", 38, 11)

# Info box
var infoBox = newInfoBox("",0 ,0, terminalWidth())
var infoBoxMouse = newInfoBox("",0 ,0, terminalWidth())
var infoBoxAsync = newInfoBox("",0 ,1, terminalWidth())

# Radio buttons
var chkRadA = newRadioBox("Radio Box Option A", 56, 4)
chkRadA.checked = true
var chkRadB = newRadioBox("Radio Box Option B", 56, 5)
var chkRadC = newRadioBox("Radio Box Option C", 56, 6)
var radioBoxGroup = newRadioBoxGroup(@[
  chkRadA, chkRadB, chkRadC
])

var chooseBox = newChooseBox(@[" ", "#", "@", "§"], 81, 3, 10, 5, choosenidx=2)

var textBox = newTextBox("foo", 38, 13, 42, placeholder = "Some placeholder")

proc asyncDemo(): Future[void] {.async.} =
  var idx = 0
  while true:
    idx.inc
    infoBoxAsync.text = "Async Demo: " & $idx
    await sleepAsync(1000)
asyncCheck asyncDemo()

proc httpCall(): Future[void] {.async.} =
  var client = newHttpClient()
  infoBox.text = client.getContent("http://ip.code0.xyz").strip()

proc funDraw(tb: var TerminalBuffer, coords: MouseInfo) = 
  if coords.action == MouseButtonAction.Pressed:
    tb.write coords.x, coords.y, fgRed, "♥"
  else:
    tb.write coords.x, coords.y, fgGreen, "⌀"


while true:
  var key = getKey()

  # Must be done for every textbox
  if textBox.focus:
    if tb.handleKey(textBox, key):
      tb.write(0,2, bgYellow, fgBlue, textBox.text)
      chooseBox.add(textBox.text)
    key.setKeyAsHandled() # If the key input was handled by the textbox
  
  case key
  of Key.None: discard
  of Key.Escape, Key.Q: exitProc()
  of Key.Mouse: #, Key.None: # TODO Key.None here does not work with checkbox
    let coords = getMouse()
    infoBoxMouse.text = $coords
    var ev: Events

    ev = tb.dispatch(btnAsyncHttp, coords)
    if ev.contains MouseUp:
      asyncCheck httpCall()
    if ev.contains MouseDown:
      infoBox.text = "http call to http://ip.code0.xyz to get your public ip!"

    ev = tb.dispatch(btnClear, coords)
    if ev.contains MouseUp:
      tb.clear()
    if ev.contains MouseDown:
      infoBox.text = "CLEARS THE SCREEN!"
    
    ev = tb.dispatch(btnTest, coords)
    if ev.contains MouseUp:
      tb.clear(chooseBox.element)
    if ev.contains MouseDown:
      infoBox.text = "Fills the screen!!"

    ev = tb.dispatch(chkTest, coords)
    if ev.contains MouseUp:
      infoBox.text = "chk test is: " & $chkTest.checked
    
    ev = tb.dispatch(chkTest2, coords)
    if ev.contains MouseUp:
      if chkTest2.checked:
        infoBox.text = "red"
        tb.setForegroundColor fgRed
        chkTest2.color = fgRed
      else:
        infoBox.text = "green"
        chkTest2.color = fgGreen
        tb.setForegroundColor fgGreen

    ev = tb.dispatch(chkDraw, coords)
    if ev.contains MouseDown:
      infoBox.text = "Enables/Disables drawing"

    ev = tb.dispatch(infoBox, coords)
    if ev.contains MouseDown:
      infoBox.text &= "#"
    if ev.contains MouseUp:
      infoBox.text &= "^"

    ev = tb.dispatch(chooseBox, coords)
    if ev.contains MouseUp:
      infoBox.text = fmt"Choose box choosenidx: {chooseBox.choosenidx} -> {chooseBox.element()}"
    
    # Textbox is special! (see above for `handleKey`)
    ev = tb.dispatch(textBox, coords)

    # RadioBoxGroup dispatches to all group members
    ev = tb.dispatch(radioBoxGroup, coords)
    if ev.contains MouseUp:
      infoBox.text = fmt"Radio button with content '{radioBoxGroup.element().text}' selected."

    # We enable / disable drawing based on checkbox value
    if chkDraw.checked:
      tb.funDraw(coords)

  else:
    infoBox.text = $key
    discard
  
  tb.render(btnAsyncHttp)
  tb.render(btnClear)
  tb.render(btnTest)
  tb.render(chkTest)
  tb.render(chkTest2)
  tb.render(chkDraw)

  # RadioBoxGroup renders all its members
  tb.render(radioBoxGroup)

  # Update the info box position to always be on the bottom
  infoBox.w = terminalWidth()
  infoBox.y = terminalHeight()-1
  tb.render(infoBox)
  
  tb.render(infoBoxMouse) # No need to update position (is at the top)
  tb.render(infoBoxAsync)
  tb.render(chooseBox)
  tb.render(textBox)
  
  tb.display()

  poll(30) # for the async demo code (keep poll low), use sleep below for non async.
  # sleep(50) # when no async code used, just call sleep(50)
# 