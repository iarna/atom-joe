{CompositeDisposable} = require 'atom'

getBlock = (editor) ->
  if (editor.persistentBlock)
    return editor.persistentBlock
  thisLocation = editor.getCursorBufferPosition()
  editor.persistentBlock = editor.markBufferRange(new Range(thisLocation, thisLocation), {invalidate: 'never'})
  editor.decorateMarker(editor.persistentBlock, {type: "highlight", class: "selection"})
  return editor.persistentBlock

module.exports = AtomJoe =
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'joe:block-start': => @blockStart()
    @subscriptions.add atom.commands.add 'atom-workspace', 'joe:block-end': => @blockEnd()
    @subscriptions.add atom.commands.add 'atom-workspace', 'joe:block-copy': => @blockCopy()
    @subscriptions.add atom.commands.add 'atom-workspace', 'joe:block-move': => @blockMove()

  deactivate: ->
    @subscriptions.dispose()

  blockStart: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    persistentBlock = getBlock(editor)
    currentRange = persistentBlock.getBufferRange()
    currentRange.start = editor.getCursorBufferPosition()
    if (currentRange.end.row < currentRange.start.row)
      currentRange.end = currentRange.start
    if (currentRange.end.row == currentRange.start.row && currentRange.end.col < currentRange.start.col)
      currentRange.end.col = currentRange.start.col
    persistentBlock.setBufferRange(currentRange)

  blockEnd: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    persistentBlock = getBlock(editor)
    currentRange = editor.persistentBlock.getBufferRange()
    currentRange.end = editor.getCursorBufferPosition()
    if (currentRange.start.row > currentRange.end.row)
      currentRange.start = currentRange.end
    if (currentRange.end.row == currentRange.start.row && currentRange.start.col > currentRange.end.col)
      currentRange.start.col = currentRange.end.col
    persistentBlock.setBufferRange(currentRange)

  blockCopy: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    persistentBlock = getBlock(editor)
    moveTo = persistentBlock.getBufferRange()
    toCopy = editor.getTextInBufferRange(moveTo)
    editor.insertText(toCopy)

  blockMove: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    persistentBlock = getBlock(editor)
    moveFrom = persistentBlock.getBufferRange()
    toMove = editor.getTextInBufferRange(moveFrom)
    moveTo = moveFrom
    editor.transact ->
      editor.setTextInBufferRange(moveFrom, '')
      moveTo.start = editor.getCursorBufferPosition()
      editor.insertText(toMove)
      moveTo.end = editor.getCursorBufferPosition()
      persistentBlock.setBufferRange(moveTo)
