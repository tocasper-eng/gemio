-- =====================================================================
-- drop_trigger.sql - 清除所有安全 Trigger
-- 執行時機：重新部署 trigger.sql 之前
-- =====================================================================

USE master;
GO

-- Server 層級 Trigger
IF EXISTS (SELECT 1 FROM sys.server_triggers WHERE name = 'trg_block_sa_gemio_alter')
BEGIN
    DISABLE TRIGGER [trg_block_sa_gemio_alter] ON ALL SERVER;
    DROP    TRIGGER [trg_block_sa_gemio_alter] ON ALL SERVER;
    PRINT 'trg_block_sa_gemio_alter 已移除。';
END
ELSE
    PRINT 'trg_block_sa_gemio_alter 不存在，跳過。';
GO

-- 資料庫 [casper]
USE casper;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_block_dcl')
BEGIN
    DROP TRIGGER [trg_block_dcl];
    PRINT '[casper] trg_block_dcl 已移除。';
END
ELSE
    PRINT '[casper] trg_block_dcl 不存在，跳過。';
GO

-- 資料庫 [chjer]
USE chjer;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_block_dcl')
BEGIN
    DROP TRIGGER [trg_block_dcl];
    PRINT '[chjer] trg_block_dcl 已移除。';
END
ELSE
    PRINT '[chjer] trg_block_dcl 不存在，跳過。';
GO

-- 資料庫 [jet]
USE jet;
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_block_dcl')
BEGIN
    DROP TRIGGER [trg_block_dcl];
    PRINT '[jet] trg_block_dcl 已移除。';
END
ELSE
    PRINT '[jet] trg_block_dcl 不存在，跳過。';
GO

PRINT '完成。請接著執行 trigger.sql。';
