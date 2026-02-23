-- =====================================================================
-- trigger.sql - SQL Server 2022 安全 Trigger 設定腳本
-- 執行順序：在 gemio.sql 執行完畢後再執行本檔
-- 依據 CLAUDE.md 規則：
--   1. 封鎖任何對 sa / gemio 的修改（含重新啟用）
--   2. 只允許 drlee 執行 DCL（GRANT / REVOKE / DENY）
-- 各 Trigger 加入 TRIGGER_NESTLEVEL 防止遞迴觸發（Error 217）
-- =====================================================================

USE master;
GO

-- =====================================================================
-- Trigger 1: Server 層級 - 封鎖對 sa 或 gemio 的任何 ALTER_LOGIN
-- =====================================================================
CREATE OR ALTER TRIGGER [trg_block_sa_gemio_alter]
ON ALL SERVER
FOR ALTER_LOGIN
AS
BEGIN
    SET NOCOUNT ON;

    -- 防止遞迴觸發（Error 217）
    IF TRIGGER_NESTLEVEL(@@PROCID) > 1 RETURN;

    DECLARE @xml    XML           = EVENTDATA();
    DECLARE @target NVARCHAR(256) = @xml.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)');

    IF LOWER(@target) IN ('sa', 'gemio')
    BEGIN
        RAISERROR('【安全政策】禁止對 sa / gemio 帳號進行任何修改（含重新啟用）。', 16, 1);
        ROLLBACK;
    END;
END;
GO

-- =====================================================================
-- Trigger 2: 資料庫 [casper] - 只允許 drlee 執行 DCL
-- =====================================================================
USE casper;
GO

CREATE OR ALTER TRIGGER [trg_block_dcl]
ON DATABASE
FOR GRANT_DATABASE, REVOKE_DATABASE, DENY_DATABASE
AS
BEGIN
    SET NOCOUNT ON;

    -- 防止遞迴觸發（Error 217）
    IF TRIGGER_NESTLEVEL(@@PROCID) > 1 RETURN;

    IF SUSER_SNAME() <> 'drlee'
    BEGIN
        RAISERROR('【安全政策】只有 drlee 可以執行 DCL（GRANT / REVOKE / DENY）。', 16, 1);
        ROLLBACK;
    END;
END;
GO

-- =====================================================================
-- Trigger 3: 資料庫 [chjer] - 只允許 drlee 執行 DCL
-- =====================================================================
USE chjer;
GO

CREATE OR ALTER TRIGGER [trg_block_dcl]
ON DATABASE
FOR GRANT_DATABASE, REVOKE_DATABASE, DENY_DATABASE
AS
BEGIN
    SET NOCOUNT ON;

    -- 防止遞迴觸發（Error 217）
    IF TRIGGER_NESTLEVEL(@@PROCID) > 1 RETURN;

    IF SUSER_SNAME() <> 'drlee'
    BEGIN
        RAISERROR('【安全政策】只有 drlee 可以執行 DCL（GRANT / REVOKE / DENY）。', 16, 1);
        ROLLBACK;
    END;
END;
GO

-- =====================================================================
-- Trigger 4: 資料庫 [jet] - 只允許 drlee 執行 DCL
-- =====================================================================
USE jet;
GO

CREATE OR ALTER TRIGGER [trg_block_dcl]
ON DATABASE
FOR GRANT_DATABASE, REVOKE_DATABASE, DENY_DATABASE
AS
BEGIN
    SET NOCOUNT ON;

    -- 防止遞迴觸發（Error 217）
    IF TRIGGER_NESTLEVEL(@@PROCID) > 1 RETURN;

    IF SUSER_SNAME() <> 'drlee'
    BEGIN
        RAISERROR('【安全政策】只有 drlee 可以執行 DCL（GRANT / REVOKE / DENY）。', 16, 1);
        ROLLBACK;
    END;
END;
GO

-- =====================================================================
-- 驗證：確認所有 Trigger 已建立且啟用
-- =====================================================================
USE master;

SELECT name AS [Trigger], type_desc, is_disabled AS [已停用]
FROM sys.server_triggers
WHERE name = 'trg_block_sa_gemio_alter';

USE casper; SELECT DB_NAME() AS [資料庫], name AS [Trigger], is_disabled AS [已停用] FROM sys.triggers WHERE name = 'trg_block_dcl';
USE chjer;  SELECT DB_NAME() AS [資料庫], name AS [Trigger], is_disabled AS [已停用] FROM sys.triggers WHERE name = 'trg_block_dcl';
USE jet;    SELECT DB_NAME() AS [資料庫], name AS [Trigger], is_disabled AS [已停用] FROM sys.triggers WHERE name = 'trg_block_dcl';
