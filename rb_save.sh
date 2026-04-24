#!/bin/zsh

# --- 1. 自動檢查並請求管理員權限 ---
if [[ $EUID -ne 0 ]]; then
   echo "正在請求管理員 (sudo) 權限以執行系統優化..."
   sudo -v
   # 保持 sudo 權限直到腳本結束
   while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

# --- 2. 主選單 ---
show_menu() {
    clear
    echo "==========================================="
    echo "      RB 專用極簡省電工具 (macOS v1.0)"
    echo "==========================================="
    echo "1. 徹底關閉 Finder (桌面消失/省電)"
    echo "2. 恢復 Finder (顯示桌面)"
    echo "3. 終極優化 (低耗電模式 + 系統限制)"
    echo "4. 恢復正常 (標準模式)"
    echo "5. 退出"
    echo "==========================================="
}

while true; do
    show_menu
    printf "請輸入選項 (1-5): "
    read Selection

    case $Selection in
        1)
            echo "正在停用 Finder 自動重啟並關閉..."
            # 停止 Finder 的自動啟動機制
            launchctl unload -w /System/Library/LaunchAgents/com.apple.finder.plist 2>/dev/null
            killall Finder 2>/dev/null
            echo "成功：Finder 已關閉（桌面圖示與視窗將消失）。"
            read -n 1 -s -p "按任意鍵繼續..."
            ;;
        2)
            echo "正在恢復 Finder..."
            # 重新加載 Finder 機制
            launchctl load -w /System/Library/LaunchAgents/com.apple.finder.plist 2>/dev/null
            open /System/Library/CoreServices/Finder.app
            echo "成功：Finder 已恢復。"
            read -n 1 -s -p "按任意鍵繼續..."
            ;;
        3)
            echo "正在套用 macOS 低耗電優化..."
            # 開啟低耗電模式 (macOS Monterey 12.0+)
            sudo pmset -a lowpower 1
            # 減少螢幕亮度與休眠等待時間
            sudo pmset -a displaysleep 2
            sudo pmset -a disksleep 5
            # 關閉藍牙 (省電大戶，如需使用請手動開啟)
            # blueutil --power 0 (需安裝 blueutil，此處先跳過)
            echo "成功：已切換至低耗電模式 (Low Power Mode)。"
            read -n 1 -s -p "按任意鍵繼續..."
            ;;
        4)
            echo "正在恢復標準模式..."
            sudo pmset -a lowpower 0
            sudo pmset -a displaysleep 10
            sudo pmset -a disksleep 10
            echo "成功：系統已恢復預設平衡狀態。"
            read -n 1 -s -p "按任意鍵繼續..."
            ;;
        5)
            # 退出前確保 Finder 機制是正常的
            launchctl load -w /System/Library/LaunchAgents/com.apple.finder.plist 2>/dev/null
            exit 0
            ;;
        *)
            echo "錯誤：無效的選項！"
            sleep 1
            ;;
    esac
done