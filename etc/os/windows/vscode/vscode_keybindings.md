# 'when' clause contexts

## Conditional operators

|  Operator  | Symbol |               Example               |         |
| ---------- | ------ | ----------------------------------- | ------- |
| Equality   | ==     | "editorLangId == typescript"        |         |
| Inequality | !=     | "resourceExtname != .js"            |         |
| Or         | \|\|   | "isLinux \|\| isWindows"            |         |
| And        | &&     | "textInputFocus && !editorReadonly" |         |
| Matches    | =~     | resourceScheme =~ /^untitled$       | ^file$/ |

## Contexts

|           Context name           |                                                    True when                                                    |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Editor contexts                  |                                                                                                                 |
| editorFocus                      | An editor has focus, either the text or a widget.                                                               |
| editorTextFocus                  | The text in an editor has focus (cursor is blinking).                                                           |
| textInputFocus                   | Any editor has focus (regular editor, debug REPL, etc.).                                                        |
| inputFocus                       | Any text input area has focus (editors or text boxes).                                                          |
| editorHasSelection               | Text is selected in the editor.                                                                                 |
| editorHasMultipleSelections      | Multiple regions of text are selected (multiple cursors).                                                       |
| editorReadonly                   | The editor is read only.                                                                                        |
| editorLangId                     | True when the editor's associated language Id matches. Example: "editorLangId == typescript".                   |
| isInDiffEditor                   | The active editor is a difference editor.                                                                       |
| isInEmbeddedEditor               | True when the focus is inside an embedded editor.                                                               |
| Operating system contexts        |                                                                                                                 |
| isLinux                          | True when the OS is Linux                                                                                       |
| isMac                            | True when the OS is macOS                                                                                       |
| isWindows                        | True when the OS is Windows                                                                                     |
| isWeb                            | True when accessing the editor from the Web                                                                     |
| List contexts                    |                                                                                                                 |
| listFocus                        | A list has focus.                                                                                               |
| listSupportsMultiselect          | A list supports multi select.                                                                                   |
| listHasSelectionOrFocus          | A list has selection or focus.                                                                                  |
| listDoubleSelection              | A list has a selection of 2 elements.                                                                           |
| listMultiSelection               | A list has a selection of multiple elements.                                                                    |
| Mode contexts                    |                                                                                                                 |
| inDebugMode                      | A debug session is running.                                                                                     |
| debugType                        | True when debug type matches. Example: "debugType == 'node'".                                                   |
| inSnippetMode                    | The editor is in snippet mode.                                                                                  |
| inQuickOpen                      | The Quick Open drop-down has focus.                                                                             |
| Resource contexts                |                                                                                                                 |
| resourceScheme                   | True when the resource Uri scheme matches. Example: "resourceScheme == file"                                    |
| resourceFilename                 | True when the Explorer or editor filename matches. Example: "resourceFilename == gulpfile.js"                   |
| resourceExtname                  | True when the Explorer or editor filename extension matches. Example: "resourceExtname == .js"                  |
| resourceLangId                   | True when the Explorer or editor title language Id matches. Example: "resourceLangId == markdown"               |
| isFileSystemResource             | True when the Explorer or editor file is a file system resource that can be handled from a file system provider |
| resourceSet                      | True when an Explorer or editor file is set                                                                     |
| resource                         | The full Uri of the Explorer or editor file                                                                     |
| Explorer contexts                |                                                                                                                 |
| explorerViewletVisible           | True if Explorer view is visible.                                                                               |
| explorerViewletFocus             | True if Explorer view has keyboard focus.                                                                       |
| filesExplorerFocus               | True if File Explorer section has keyboard focus.                                                               |
| openEditorsFocus                 | True if OPEN EDITORS section has keyboard focus.                                                                |
| explorerResourceIsFolder         | True if a folder is selected in the Explorer.                                                                   |
| Editor widget contexts           |                                                                                                                 |
| findWidgetVisible                | Editor Find widget is visible.                                                                                  |
| suggestWidgetVisible             | Suggestion widget (IntelliSense) is visible.                                                                    |
| suggestWidgetMultipleSuggestions | Multiple suggestions are displayed.                                                                             |
| renameInputVisible               | Rename input text box is visible.                                                                               |
| referenceSearchVisible           | Peek References peek window is open.                                                                            |
| inReferenceSearchEditor          | The Peek References peek window editor has focus.                                                               |
| config.editor.stablePeek         | Keep peek editors open (controlled by editor.stablePeek setting).                                               |
| quickFixWidgetVisible            | Quick Fix widget is visible.                                                                                    |
| parameterHintsVisible            | Parameter hints are visible (controlled by editor.parameterHints.enabled setting).                              |
| parameterHintsMultipleSignatures | Multiple parameter hints are displayed.                                                                         |
| Integrated terminal contexts     |                                                                                                                 |
| terminalFocus                    | An integrated terminal has focus.                                                                               |
| terminalIsOpen                   | An integrated terminal is opened.                                                                               |
| Timeline view contexts           |                                                                                                                 |
| timelineFollowActiveEditor       | True if the Timeline view is following the active editor.                                                       |
| Timeline view item contexts      |                                                                                                                 |
| timelineItem                     | True when the timeline item's context value matches. Example: "timelineItem =~ /git:file:commit\\b/".           |
| Extension contexts               |                                                                                                                 |
| extension                        | True when the extension's ID matches. Example: "extension == eamodio.gitlens".                                  |
| extensionStatus                  | True when the extension is installed. Example: "extensionStatus == installed".                                  |
| extensionHasConfiguration        | True if the extension has configuration.                                                                        |
| Global UI contexts               |                                                                                                                 |
| notificationFocus                | Notification has keyboard focus.                                                                                |
| notificationCenterVisible        | Notification Center is visible at the bottom right of VS Code.                                                  |
| notificationToastsVisible        | Notification toast is visible at the bottom right of VS Code.                                                   |
| searchViewletVisible             | Search view is open.                                                                                            |
| sideBarVisible                   | Side Bar is displayed.                                                                                          |
| sideBarFocus                     | Side Bar has focus.                                                                                             |
| panelFocus                       | Panel has focus.                                                                                                |
| inZenMode                        | Window is in Zen Mode.                                                                                          |
| isCenteredLayout                 | Editor is in centered layout mode.                                                                              |
| inDebugRepl                      | Focus is in the Debug Console REPL.                                                                             |
| workbenchState                   | Can be empty, folder (1 folder), or workspace.                                                                  |
| workspaceFolderCount             | Count of workspace folders.                                                                                     |
| replaceActive                    | Search view Replace text box is open.                                                                           |
| view                             | True when view identifier matches. Example: "view == myViewsExplorerID".                                        |
| viewItem                         | True when viewItem context matches. Example: "viewItem == someContextValue".                                    |
| isFullscreen                     | True when window is in fullscreen.                                                                              |
| focusedView                      | The identifier of the currently focused view.                                                                   |
| canNavigateBack                  | True if it is possible to navigate back.                                                                        |
| canNavigateForward               | True if it is possible to navigate forward.                                                                     |
| canNavigateToLastEditLocation    | True if it is possible to navigate to the last edit location.                                                   |
| Global Editor UI contexts        |                                                                                                                 |
| textCompareEditorVisible         | At least one diff (compare) editor is visible.                                                                  |
| textCompareEditorActive          | A diff (compare) editor is active.                                                                              |
| editorIsOpen                     | True if one editor is open.                                                                                     |
| groupActiveEditorDirty           | True when the active editor in a group is dirty.                                                                |
| groupEditorsCount                | Number of editors in a group.                                                                                   |
| activeEditorGroupEmpty           | True if the active editor group has no editors.                                                                 |
| activeEditorGroupIndex           | Index of the active editor in an group (beginning with 1).                                                      |
| activeEditorGroupLast            | True when the active editor in an group is the last one.                                                        |
| multipleEditorGroups             | True when multiple editor groups are present.                                                                   |
| editorPinned                     | True when the active editor in a group is pinned (not in preview mode).                                         |
| activeEditor                     | The identifier of the active editor in a group.                                                                 |
| Configuration settings contexts  |                                                                                                                 |
| config.editor.minimap.enabled    | True when the setting editor.minimap.enabled is true.                                                           |

Note: You can use any user or workspace setting that evaluates to a boolean here with the prefix "config.".

### Specific view or panel context name

| Context name  |                                    True when                                     |
| ------------- | -------------------------------------------------------------------------------- |
| activeViewlet | True when view is visible. Example: "activeViewlet == 'workbench.view.explorer'" |
| activePanel   | True when panel is visible. Example: "activePanel == 'workbench.panel.output'"   |
| focusedView   | True when view is focused. Example: "focusedView == myViewsExplorerID            |

### View Identifiers

workbench.view.explorer - File Explorer
workbench.view.search - Search
workbench.view.scm - Source Control
workbench.view.debug - Run
workbench.view.extensions - Extensions

### Panel Identifiers

workbench.panel.markers - Problems
workbench.panel.output - Output
workbench.panel.repl - Debug Console
workbench.panel.terminal - Integrated Terminal
workbench.panel.comments - Comments
workbench.view.search - Search when search.location is set to panel

## Variables

<https://code.visualstudio.com/docs/editor/variables-reference>
