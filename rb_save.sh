#!/bin/zsh

# --- 1. 版本與資訊 ---
# RB 極致省電優化工具 (macOS 穩定版 v3.0)
# 修正了對 Intel/Apple Silicon 晶片的兼容性，並強化了 Finder 重啟邏輯。

# --- 2. 自動檢查並請求管理員權限 ---
if [[ $EUID -ne 0 ]]; then
    echo "==========================================="
    echo "      正在請求管理員 (sudo) 權限..."
    echo "==========================================="
    if sudo -v; then
        # 在背景持續更新 sudo 認證，直到腳本結束
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    else
        echo "錯誤：未取得管理員權限，無法執行系統層級優化。"
        exit 1
    fi
fi

# --- 3. 系統環境檢查 ---
OS_VERSION=$(sw_vers -productVersion | cut -d. -f1)
IS_SUPPORT_LOWPOWER=false
if [ "$OS_VERSION" -ge 12 ]; then
    IS_SUPPORT_LOWPOWER=true
fi

# --- 4. 功能函式庫 ---

# 恢復系統標準環境
restore_env() {
    echo "正在恢復系統環境中..."
    # 恢復 Finder
    launchctl load -w /System/Library/LaunchAgents/com.apple.finder.plist 2>/dev/null
    open /System/Library/CoreServices/Finder.app 2>/dev/null
    
    # 恢復電源設定 (平衡)
    if $IS_SUPPORT_LOWPOWER; then
        sudo pmset -a lowpower 0
    fi
    sudo pmset -a powernap 1
    sudo pmset -a displaysleep 10
    sudo pmset -a disksleep 10
    sudo pmset -a lessbright 0
    echo "系統環境已恢復正常。"
}

# 捕捉中斷訊號 (如 Ctrl+C)，確保意外退出時恢復 Finder
trap "restore_env; exit" INT TERM

# 查看當前電力狀態
check_status() {
    echo "--- 當前電源狀態 ---"
    pmset -g live | grep -E "(lowpower|displaysleep|disksleep)"
    echo "-------------------"
}

# --- 5. 主選單 ---
show_menu() {
    clear
    echo "==========================================="
    echo "      RB 專用極簡省電工具 (macOS Stable)"
    echo "==========================================="
    echo " 1. [極致] 徹底關閉 Finder (桌面消失)"
    echo " 2. [恢復] 啟動 Finder (還原桌面)"
    echo " 3. [優化] 終極省電 (開啟 Low Power Mode)"
    echo " 4. [標準] 恢復正常 (預設平衡模式)"
    echo " 5. [查詢] 顯示當前電源設定狀態"
    echo " 6. [退出] 安全關閉"
    echo "==========================================="
    if ! $IS_SUPPORT_LOWPOWER; then
        echo "注意：當前系統版本過低，不支援內建低耗電模式。"
    fi
}

# --- 6. 主程式迴圈 ---
while true; do
    show_menu
    read "Selection?請選擇操作 (1-6): "
    echo ""

    case $Selection in
        1)
            echo "執行中：正在停止 Finder 管理程序..."
            launchctl unload -w /System/Library/LaunchAgents/com.apple.finder.plist 2>/dev/null
            killall Finder 2>/dev/null
            echo "成功：Finder 已停用，釋放 GUI 渲染資源。"
            read -k 1 "tmp?按任意鍵繼續..."
            ;;
        2)
            echo "執行中：正在恢復 Finder..."
            launchctl load -w /System/Library/LaunchAgents/com.apple.finder.plist 2>/dev/null
            open /System/Library/CoreServices/Finder.app 2>/dev/null
            echo "成功：桌面已還原。"
            read -k 1 "tmp?按任意鍵繼續..."
            ;;
        3)
            echo "執行中：正在套用極限省電參數..."
            if $IS_SUPPORT_LOWPOWER; then
                sudo pmset -a lowpower 1
            fi
            sudo pmset -a powernap 0
            sudo pmset -a displaysleep 2
            sudo pmset -a disksleep 5
            sudo pmset -a lessbright 1
            echo "成功：系統已進入低功耗狀態。"
            read -k 1 "tmp?按任意鍵繼續..."
            ;;
        4)
            echo "執行中：正在還原平衡模式..."
            restore_env
            read -k 1 "tmp?按任意鍵繼續..."
            ;;
        5)
            check_status
            read -k 1 "tmp?按任意鍵繼續..."
            ;;
        6)
            echo "正在安全退出..."
            # 確保 Finder 有被載入後才結束
            launchctl load -w /System/Library/LaunchAgents/com.apple.finder.plist 2>/dev/null
            exit 0
            ;;
        *)
            echo "錯誤：輸入無效。"
            sleep 1
            ;;
    esac
done
