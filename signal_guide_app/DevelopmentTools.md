下載並安裝 Android Studio & Flutter & Intellij IDEA
==========
> Android Studio 是為Android平台開發程式的整合式開發環境

> Flutter 是跨平台框架(同時讓iOS與Android平台使用)

> Intellij IDEA 是編輯 Flutter 的開發工具 

---

### 下載 Android Studio 步驟
> Windows 使用者
1. 連到 [Android Studio 官網](https://developer.android.com/studio?hl=zh-tw#get-android-studio)
   > 使用版本： android-studio-2024.3.2.15-windows.exe
2. 依照安裝精靈的指示進行
3. 確保選擇安裝 "Android Studio" 和 "Android Virtual Device"
4. 建議安裝路徑：C:\Program Files\Android\Android Studio

---

### 下載 Flutter 步驟
1. 連到 [Flutter 官網](https://docs.flutter.dev/get-started/install)
2. 選擇電腦的作業系統( Windows / macOS / Linux / ChromeOS )
   > 我用 Windows
3. 選擇要開發的APP類型( Android / Web / Desktop )
   > 我用 Android
4. 下載 Flutter SDK 包
   > 使用版本： flutter_windows_3.32.5-stable.zip
5. 建立一個可以安裝 Flutter 的資料夾
   > 例如: `C:\src`
6. 將下載好的 **Flutter SDK 包** 解壓縮至 可以安裝 Flutter 的資料夾
   > `C:\src\flutter`
7. 設定 Windows PATH 變數
   > 1. **滑鼠右鍵** 按電腦螢幕左下角的 **開始**
   > 2. 選擇 **系統**
   > 3. 選擇 **進階系統設定**
   > 4. 選擇 **環境變數**
   > 5. 在使用者變數找到 **Path**，然後選擇編輯
   > 6. 按 **新增** ，輸入 路徑 `C:\src\flutter\bin` 後，按確定(三次)
8. 檢查軟體
   > 1. 打開終端機，輸入指令 `flutter doctor`
   > > > 應該 command-line tools 尚未安裝
   > 2. 打開 Android Studio
   > > > 開啟設定找到 **Languages & Frameworks** 的 **Android SDK**，選擇 **SDK Tools**，然後 Apply
   > 3. 在終端機輸入指令 `flutter doctor --android-licenses`，一直輸入 `y` 接受
   > 4. 全部顯示 **綠色 √** 並出現 `No issues found!` ，表示開發 Flutter 的套件都安裝好了
   > > > ![image](https://github.com/user-attachments/assets/6d8b82c7-495a-4887-8e79-bfeb53e44dc2)



---

### 下載 Intellij IDEA 步驟
1. 連到 [Intellij IDEA 官網](https://www.jetbrains.com/idea/download/?section=windows)
   > 選擇 IntelliJ IDEA Community Edition
   
   > 使用版本：ideaIC-2025.1.3.exe
2. 勾選
   > ![image](https://github.com/user-attachments/assets/a78add97-68f5-4817-a0a9-0f505e1d4136)

3. 開啟 Intellij IDEA ，點開設定找到 `Plugins` ，在搜尋框輸入 `flutter` 安裝模組
