# Gemio Project

## 專案說明
SQL Server 2022 資料庫安全管理腳本。

## 檔案結構
- `gemio.sql` - 使用者權限設定腳本（Login 建立、資料庫 User 授權）
- `trigger.sql` - 使用者權限設觸發器

## 環境
- 資料庫：SQL Server 2022
- 管理對象帳號：`casper`
- 允許存取的資料庫：`casper`、`chjer`、`jet`

## 慣例
- SQL 腳本使用繁體中文註解
- 每個步驟以區塊分隔，附上說明標題
- 執行前先確認 Login 是否存在（IF NOT EXISTS 保護）

## 規則
- id casper 的密碼是 CasChrAliJimJam
- 除了  id:drlee 能夠執行 dcl 之外，其他的 id 都不能執行dcl
- id:casper 能擁有 database: casper , chjer , jet    授與 DML + EXECUTE
  但不要給 db_owner 改給 db_datareader + db_datawriter ）搭配 DCL Trigger
- id:casper 除了 database: casper , chjer , jet 之外 ，其他的 database 都不能有view的權限
- id:casper 擁有 VIEW ANY DATABASE 伺服器層級權限（讓 SSMS 能看到三個授權資料庫）
- id:casper 在 casper、chjer、jet 三個資料庫擁有 db_backupoperator 角色（備份權限）
- id:casper 擁有 dbcreator 伺服器角色（還原權限；副作用：可建立新資料庫，已知且接受）
- id:sa 若存在，請重新命名成 gemio
- id:sa 或 id:gemio 要停用，而且當有人想恢復使用時，要擋下來。
- 如果你執行的指令需要建立 trigger , 請另外存成 trigger.sql

