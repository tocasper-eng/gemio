# Gemio ERP 二次開發專案

## 專案說明
針對現有 ERP 系統進行二次開發，資料庫為 SQL Server。

## 技術環境
- 語言：Python 3.x
- 資料庫：SQL Server 2022
- 資料庫連線：透過環境變數管理（不硬寫連線字串）
- 套件：`pyodbc`、`python-dotenv`

## 資料庫連線設定

### 環境變數定義
| 環境變數名稱         | 說明                      | 範例值                   |
|---------------------|--------------------------|-------------------------|
| `DB_SERVER`         | SQL Server 主機名稱或 IP  | `localhost` / `192.168.1.1` |
| `DB_PORT`           | 連接埠（預設 1433）        | `1433`                  |
| `DB_NAME`           | 資料庫名稱                | `casper`                |
| `DB_USER`           | 登入帳號                  | `casper`                |
| `DB_PASSWORD`       | 登入密碼                  | （不記錄於文件）          |
| `DB_TRUST_CERT`     | 是否信任伺服器憑證         | `true` / `false`        |

### 連線字串格式
```
Server=${DB_SERVER},${DB_PORT};Database=${DB_NAME};User Id=${DB_USER};Password=${DB_PASSWORD};TrustServerCertificate=${DB_TRUST_CERT};
```

### .env 範例（`.env.example`）
```env
DB_SERVER=163.17.141.61
DB_PORT=8000
DB_NAME=casper
DB_USER=nutc30
DB_PASSWORD=
DB_TRUST_CERT=yes
```

> **注意**：`.env` 檔案不得提交至版控，請將 `.env` 加入 `.gitignore`。

## 套件安裝

```bash
pip install pyodbc python-dotenv
```

> Windows 需安裝 [ODBC Driver 18 for SQL Server](https://learn.microsoft.com/zh-tw/sql/connect/odbc/download-odbc-driver-for-sql-server)

## Python 資料庫連線模組（`db.py`）

```python
import os
import pyodbc
from dotenv import load_dotenv

load_dotenv()

def get_connection():
    conn_str = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={os.environ['DB_SERVER']},{os.environ.get('DB_PORT', '1433')};"
        f"DATABASE={os.environ['DB_NAME']};"
        f"UID={os.environ['DB_USER']};"
        f"PWD={os.environ['DB_PASSWORD']};"
        f"TrustServerCertificate={os.environ.get('DB_TRUST_CERT', 'yes')};"
    )
    return pyodbc.connect(conn_str)
```

### 使用方式

```python
from db import get_connection

with get_connection() as conn:
    cursor = conn.cursor()
    cursor.execute("SELECT TOP 10 * FROM some_table")
    rows = cursor.fetchall()
    for row in rows:
        print(row)
```

## 開發規範
- 所有連線參數均從環境變數讀取，禁止硬寫帳號密碼
- 後續需求將持續補充至本文件

## 資料表定義

### `cust`（客戶主檔）
```sql
SELECT num, custno, custnm, kindno, address0 FROM cust
```

| 欄位        | 說明       | 備註         |
|------------|-----------|-------------|
| `num`      | 自動編號   | PK          |
| `custno`   | 客戶編號   | UNIQUE      |
| `custnm`   | 客戶名稱   |             |
| `kindno`   | 客戶類別   |             |
| `address0` | 公司全名   |             |

## 待補充需求
（後續由使用者繼續定義）
