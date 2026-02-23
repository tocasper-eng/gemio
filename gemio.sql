-- =====================================================================
-- gemio.sql - SQL Server 2022 登入 / 使用者 / 權限設定腳本
-- 執行順序：先執行本檔，再執行 trigger.sql
-- 依據 CLAUDE.md 規則：
--   1. casper 擁有 casper、chjer、jet 的 DML + EXECUTE 權限
--      （db_datareader + db_datawriter，不授予 db_owner）
--   2. casper 除授權三資料庫外，其他資料庫均 DENY CONNECT
--   3. casper 擁有 VIEW ANY DATABASE（SSMS 可見授權資料庫）
--   4. casper 在三個資料庫各有 db_backupoperator 角色（備份）
--   5. casper 擁有 dbcreator 伺服器角色（還原；副作用可建立新 DB，已知並接受）
--   6. sa 若存在，重新命名為 gemio
--   7. sa 與 gemio 均停用，嘗試啟用時由 trigger.sql 攔截
--   8. drlee 為唯一可執行 DCL 的帳號（透過 trigger.sql 強制）
-- =====================================================================

USE master;
GO

-- =====================================================================
-- Step 1: 建立 Server Login
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'casper')
    CREATE LOGIN casper WITH PASSWORD = 'CasChrAliJimJam';

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'drlee')
    CREATE LOGIN drlee WITH PASSWORD = 'YourStrongP@ssword2!';

-- drlee 加入 sysadmin，使其具備執行 DCL 的伺服器層級能力
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_role_members srm
    JOIN sys.server_principals   sp  ON srm.role_principal_id   = sp.principal_id
    JOIN sys.server_principals   mbr ON srm.member_principal_id = mbr.principal_id
    WHERE sp.name  = 'sysadmin'
      AND mbr.name = 'drlee'
)
    ALTER SERVER ROLE sysadmin ADD MEMBER drlee;
GO

-- =====================================================================
-- Step 2: 將 sa 重新命名為 gemio（若 sa 仍存在）
-- =====================================================================
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'sa')
BEGIN
    ALTER LOGIN sa WITH NAME = gemio;
    PRINT 'sa 已重新命名為 gemio。';
END
ELSE
    PRINT 'sa 不存在，跳過重新命名。';
GO

-- =====================================================================
-- Step 3: 停用 sa（若仍存在）與 gemio
-- =====================================================================
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'sa')
    ALTER LOGIN sa DISABLE;

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'gemio')
    ALTER LOGIN gemio DISABLE;
GO

-- =====================================================================
-- Step 4: 資料庫 [casper] - 建立 User 並授予 DML + EXECUTE
-- =====================================================================
USE casper;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'casper')
    CREATE USER casper FOR LOGIN casper;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members rm
    JOIN sys.database_principals r   ON rm.role_principal_id   = r.principal_id
    JOIN sys.database_principals mbr ON rm.member_principal_id = mbr.principal_id
    WHERE r.name = 'db_datareader' AND mbr.name = 'casper'
)
    EXEC sp_addrolemember 'db_datareader', 'casper';

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members rm
    JOIN sys.database_principals r   ON rm.role_principal_id   = r.principal_id
    JOIN sys.database_principals mbr ON rm.member_principal_id = mbr.principal_id
    WHERE r.name = 'db_datawriter' AND mbr.name = 'casper'
)
    EXEC sp_addrolemember 'db_datawriter', 'casper';

GRANT EXECUTE TO casper;

-- 禁止 casper 查看 SP 定義（原始碼）；SP 名稱仍可見，但程式邏輯受保護
DENY VIEW DEFINITION TO casper;
GO

-- =====================================================================
-- Step 5: 資料庫 [chjer] - 建立 User 並授予 DML + EXECUTE
-- =====================================================================
USE chjer;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'casper')
    CREATE USER casper FOR LOGIN casper;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members rm
    JOIN sys.database_principals r   ON rm.role_principal_id   = r.principal_id
    JOIN sys.database_principals mbr ON rm.member_principal_id = mbr.principal_id
    WHERE r.name = 'db_datareader' AND mbr.name = 'casper'
)
    EXEC sp_addrolemember 'db_datareader', 'casper';

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members rm
    JOIN sys.database_principals r   ON rm.role_principal_id   = r.principal_id
    JOIN sys.database_principals mbr ON rm.member_principal_id = mbr.principal_id
    WHERE r.name = 'db_datawriter' AND mbr.name = 'casper'
)
    EXEC sp_addrolemember 'db_datawriter', 'casper';

GRANT EXECUTE TO casper;

-- 禁止 casper 查看 SP 定義（原始碼）；SP 名稱仍可見，但程式邏輯受保護
DENY VIEW DEFINITION TO casper;
GO

-- =====================================================================
-- Step 6: 資料庫 [jet] - 建立 User 並授予 DML + EXECUTE
-- =====================================================================
USE jet;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'casper')
    CREATE USER casper FOR LOGIN casper;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members rm
    JOIN sys.database_principals r   ON rm.role_principal_id   = r.principal_id
    JOIN sys.database_principals mbr ON rm.member_principal_id = mbr.principal_id
    WHERE r.name = 'db_datareader' AND mbr.name = 'casper'
)
    EXEC sp_addrolemember 'db_datareader', 'casper';

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members rm
    JOIN sys.database_principals r   ON rm.role_principal_id   = r.principal_id
    JOIN sys.database_principals mbr ON rm.member_principal_id = mbr.principal_id
    WHERE r.name = 'db_datawriter' AND mbr.name = 'casper'
)
    EXEC sp_addrolemember 'db_datawriter', 'casper';

GRANT EXECUTE TO casper;

-- 禁止 casper 查看 SP 定義（原始碼）；SP 名稱仍可見，但程式邏輯受保護
DENY VIEW DEFINITION TO casper;
GO

-- =====================================================================
-- Step 7: 拒絕 casper VIEW / 連線其他所有資料庫
-- =====================================================================
USE master;
GO

DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'
USE [' + name + N'];
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''casper'')
    DENY CONNECT TO casper;
-- 停用 guest，防止透過 guest 繞過限制
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''guest'' AND type = ''S'')
    REVOKE CONNECT FROM guest;
'
FROM sys.databases
WHERE name NOT IN ('casper', 'chjer', 'jet', 'master', 'tempdb', 'model', 'msdb')
  AND state_desc = 'ONLINE';

IF LEN(@sql) > 0
    EXEC sp_executesql @sql;
GO

-- =====================================================================
-- Step 8: 授予 casper 備份與還原權限
-- =====================================================================

-- 8-1 確保 casper 在 SSMS 中可看到三個授權資料庫
--     （VIEW ANY DATABASE 為 listing 權限，只看得到名稱；
--       其他資料庫仍因 DENY CONNECT 無法真正存取）
USE master;
GO

GRANT VIEW ANY DATABASE TO casper;
GO

-- 8-2 備份權限：各資料庫加入 db_backupoperator 角色
USE casper;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members rm
    JOIN sys.database_principals r   ON rm.role_principal_id   = r.principal_id
    JOIN sys.database_principals mbr ON rm.member_principal_id = mbr.principal_id
    WHERE r.name = 'db_backupoperator' AND mbr.name = 'casper'
)
    EXEC sp_addrolemember 'db_backupoperator', 'casper';
GO

USE chjer;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members rm
    JOIN sys.database_principals r   ON rm.role_principal_id   = r.principal_id
    JOIN sys.database_principals mbr ON rm.member_principal_id = mbr.principal_id
    WHERE r.name = 'db_backupoperator' AND mbr.name = 'casper'
)
    EXEC sp_addrolemember 'db_backupoperator', 'casper';
GO

USE jet;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members rm
    JOIN sys.database_principals r   ON rm.role_principal_id   = r.principal_id
    JOIN sys.database_principals mbr ON rm.member_principal_id = mbr.principal_id
    WHERE r.name = 'db_backupoperator' AND mbr.name = 'casper'
)
    EXEC sp_addrolemember 'db_backupoperator', 'casper';
GO

-- 8-3 還原權限：加入 dbcreator 伺服器層級角色
--     dbcreator 是 SQL Server 內建最小化能執行 RESTORE DATABASE 的角色
--     副作用：casper 也能建立新資料庫（若不可接受，唯一替代為 db_owner）
USE master;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_role_members srm
    JOIN sys.server_principals sp  ON srm.role_principal_id   = sp.principal_id
    JOIN sys.server_principals mbr ON srm.member_principal_id = mbr.principal_id
    WHERE sp.name = 'dbcreator' AND mbr.name = 'casper'
)
    ALTER SERVER ROLE dbcreator ADD MEMBER casper;
GO

-- =====================================================================
-- Step 9: 驗證
-- =====================================================================

-- 9-1 確認 sa / gemio 狀態
SELECT name, is_disabled AS [已停用]
FROM sys.server_principals
WHERE name IN ('sa', 'gemio');

-- 9-2 確認 casper 在各資料庫的 Role 與 EXECUTE 權限
USE casper;
SELECT dp.name AS [帳號], r.name AS [角色]
FROM sys.database_role_members rm
JOIN sys.database_principals r  ON rm.role_principal_id   = r.principal_id
JOIN sys.database_principals dp ON rm.member_principal_id = dp.principal_id
WHERE dp.name = 'casper';

SELECT class_desc, permission_name, state_desc
FROM sys.database_permissions
WHERE grantee_principal_id = USER_ID('casper');

USE chjer;
SELECT dp.name AS [帳號], r.name AS [角色]
FROM sys.database_role_members rm
JOIN sys.database_principals r  ON rm.role_principal_id   = r.principal_id
JOIN sys.database_principals dp ON rm.member_principal_id = dp.principal_id
WHERE dp.name = 'casper';

USE jet;
SELECT dp.name AS [帳號], r.name AS [角色]
FROM sys.database_role_members rm
JOIN sys.database_principals r  ON rm.role_principal_id   = r.principal_id
JOIN sys.database_principals dp ON rm.member_principal_id = dp.principal_id
WHERE dp.name = 'casper';
