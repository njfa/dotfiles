import os
from keyhac import *

def configure(keymap):

    vscode_path = "C:\\Users\\{}\\scoop\\apps\\vscode\\current\\Code.exe".format(os.environ['UserName'])
    vivaldi_path = "C:\\Users\\{}\\AppData\\Local\\Vivaldi\\Application\\vivaldi.exe".format(os.environ['UserName'])
    chrome_path = "C:\\Users\\{}\\scoop\\apps\\googlechrome\\current\\chrome.exe".format(os.environ['UserName'])
    edge_path = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"

    # Google日本語入力で事前にキャンセル後にIMEを無効化のキー設定が必要
    ime_cancel_key = "C-CloseBracket"

    #################################################################
    # フォント
    #################################################################
    keymap.setFont("更紗等幅ゴシック J", 14)

    #################################################################
    # エディタ
    #################################################################
    # vscodeが存在する場合、設定編集するエディタに指定
    if os.path.exists(vscode_path):
        keymap.editor = vscode_path

    #################################################################
    # IME
    #################################################################

    def toggle_ime():
        keymap.wnd.setImeStatus(keymap.wnd.getImeStatus() ^ 1)

    def ime_on(func):
        def _func():
            func()
            keymap.wnd.setImeStatus(1)
        return _func

    def ime_off(func):
        def _func():
            keymap.wnd.setImeStatus(0)
            func()
        return _func

    #################################################################
    # クリップボード履歴リスト
    #################################################################

    import datetime

    # 日時をペーストする機能
    def dateAndTime(fmt):
        def _dateAndTime():
            return datetime.datetime.now().strftime(fmt)
        return _dateAndTime

    # 日時
    date_and_time_items = [
        ( "YYYY/MM/DD HH:MM:SS",   dateAndTime("%Y/%m/%d %H:%M:%S") ),
        ( "YYYY/MM/DD",            dateAndTime("%Y/%m/%d") ),
        ( "HH:MM:SS",              dateAndTime("%H:%M:%S") ),
        ( "YYYYMMDD_HHMMSS",       dateAndTime("%Y%m%d_%H%M%S") ),
        ( "YYYYMMDD",              dateAndTime("%Y%m%d") ),
        ( "HHMMSS",                dateAndTime("%H%M%S") ),
    ]

    keymap.cblisters += [
        ( "日時",           cblister_FixedPhrase(date_and_time_items) )
        ]

    #################################################################
    # ランチャー
    #################################################################

    # ランチャーリストで使用するアプリケーションソフト
    application_items = []

    # VS Codeが存在する場合はランチャーに追加。無ければメモ帳を追加
    if os.path.exists(vscode_path):
        application_items += [["VS Code", keymap.ShellExecuteCommand(None, vscode_path, "", "")]]
    else:
        application_items += [["メモ帳", keymap.ShellExecuteCommand(None, "notepad.exe", "", "")]]

    # Vivaliが存在する場合はランチャーに追加
    if os.path.exists(vivaldi_path):
        application_items += [["Vivaldi", keymap.ShellExecuteCommand(None, vivaldi_path, "", "")]]

    # Chromeが存在する場合はランチャーに追加
    if os.path.exists(chrome_path):
        application_items += [["Google Chrome", keymap.ShellExecuteCommand(None, chrome_path, "", "")]]

    # Edgeが存在する場合はランチャーに追加
    if os.path.exists(edge_path):
        application_items += [["Microsoft Edge", keymap.ShellExecuteCommand(None, edge_path, "", "")]]

    application_items += [
        ["ファイルエクスプローラー",    keymap.ShellExecuteCommand(None, r"explorer.exe", "", "")]
    ]

    ignore_application_list = [
    ]

    def popWindow(wnd):
        def _func():
            try:
                if wnd.isMinimized():
                    wnd.restore()
                wnd.getLastActivePopup().setForeground()
            except:
                print("選択したウィンドウは存在しませんでした")
        return _func

    def getWindowList():
        def makeWindowList(wnd, arg):
            if wnd.isVisible() and not wnd.getOwner():

                class_name = wnd.getClassName()
                title = wnd.getText()
                process_name = wnd.getProcessName()

                if process_name not in ignore_application_list and title != "":
                    # 表示されていないストアアプリ（「設定」等）が window_list に登録されるのを抑制する
                    if class_name == "Windows.UI.Core.CoreWindow":
                        if title in window_dict:
                            if window_dict[title] in window_list:
                                window_list.remove(window_dict[title])
                        else:
                            window_dict[title] = wnd
                    elif class_name == "ApplicationFrameWindow":
                        if title not in window_dict:
                            window_dict[title] = wnd
                            window_list.append(wnd)
                    else:
                        window_list.append(wnd)
            return True

        window_dict = {}
        window_list = []
        Window.enum(makeWindowList, None)

        return window_list

    def lancherList():
        def popLancherList():

            # リストウィンドウのフォーマッタを定義する
            list_formatter = "{:30}"

            # 既にリストが開いていたら閉じるだけ
            if keymap.isListWindowOpened():
                keymap.cancelListWindow()
                return

            # ウィンドウ
            window_list = getWindowList()
            window_items = []
            if window_list:
                processName_length = max(map(len, map(Window.getProcessName, window_list)))

                formatter = "{0:" + str(processName_length) + "} | {1}"
                for wnd in window_list:
                    window_items.append((formatter.format(wnd.getProcessName(), wnd.getText()), popWindow(wnd)))

            window_items.append((list_formatter.format("<Desktop>"), keymap.ShellExecuteCommand(None, r"shell:::{3080F90D-D7AD-11D9-BD98-0000947B0257}", "", "")))

            application_items[0][0] = list_formatter.format(application_items[0][0])

            # その他
            other_items = [
                ["config.pyを編集", keymap.command_EditConfig],
                ["config.pyをリロード", keymap.command_ReloadConfig],
            ]
            other_items[0][0] = list_formatter.format(other_items[0][0])

            listers = [
                ["Window",  cblister_FixedPhrase(window_items)],
                ["Applications",  cblister_FixedPhrase(application_items)],
                ["Other",   cblister_FixedPhrase(other_items)],
            ]

            try:
                select_item = keymap.popListWindow(listers)

                if not select_item:
                    Window.find("Progman", None).setForeground()
                    select_item = keymap.popListWindow(listers)

                if select_item and select_item[0] and select_item[0][1]:
                    select_item[0][1]()
            except:
                print("エラーが発生しました")
        # キーフックの中で時間のかかる処理を実行できないので、delayedCall() を使って遅延実行する
        keymap.delayedCall(popLancherList, 0)

    #################################################################
    # キーの置き換え (共通)
    #################################################################

    keymap_global = keymap.defineWindowKeymap()
    # LAlt hjklを上下左右に変更
    keymap_global["LA-h"] = "Left"
    keymap_global["LA-j"] = "Down"
    keymap_global["LA-k"] = "Up"
    keymap_global["LA-l"] = "Right"
    keymap_global["LA-e"] = "End"
    keymap_global["LA-a"] = "Home"
    keymap_global["LA-n"] = "C-Tab"
    keymap_global["LA-p"] = "C-S-Tab"

    # LWinを仮想キーに変更
    keymap.replaceKey("LWin", 250)
    keymap_global["(250)"] = keymap.defineMultiStrokeKeymap( "(250)" )

    keymap_global["(250)"]["(250)"] = lancherList
    keymap_global["(250)"]["Comma"] = keymap.command_ClipboardList

    # 仮想デスクトップ
    keymap_global["(250)"]["c"] = "LC-RW-D"
    keymap_global["(250)"]["l"] = "LC-RW-Right"
    keymap_global["(250)"]["h"] = "LC-RW-Left"
    keymap_global["(250)"]["d"] = "LC-RW-F4"

    # コロン、セミコロンの入れ替え
    keymap_global["S-Semicolon"] = "Semicolon"
    keymap_global["Semicolon"] = "S-Semicolon"

    # Escキーの割当
    # 日本語入力中はIMEを無効化してからEscを入力する
    keymap_global["C-Semicolon"] = "Esc"
    keymap_global["Esc"] = "Esc"

    keymap_vscode = keymap.defineWindowKeymap(exe_name="code.exe")
    keymap_vscode["C-Semicolon"] = keymap.InputKeyCommand(ime_cancel_key, "Esc")
    keymap_vscode["Esc"] = keymap.InputKeyCommand(ime_cancel_key, "Esc")

    #################################################################
    # キーの置き換え (keyhac)
    #################################################################
    keymap_keyhac = keymap.defineWindowKeymap(exe_name="keyhac.exe")
    keymap_keyhac["C-h"] = "Left"
    keymap_keyhac["C-j"] = "Down"
    keymap_keyhac["C-k"] = "Up"
    keymap_keyhac["C-l"] = "Right"
    keymap_keyhac["Slash"] = "f"
    keymap_keyhac["Semicolon"] = "Esc"
