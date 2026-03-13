import pymssql


def _cfg() -> dict:
    """讀取連線參數：優先 st.secrets，fallback .env"""
    try:
        import streamlit as st
        s = st.secrets
        return {
            'server':   s['DB_SERVER'],
            'port':     int(s.get('DB_PORT', 1433)),
            'database': s['DB_NAME'],
            'user':     s['DB_USER'],
            'password': s['DB_PASSWORD'],
        }
    except Exception:
        from dotenv import load_dotenv
        import os
        load_dotenv()
        return {
            'server':   os.environ['DB_SERVER'],
            'port':     int(os.environ.get('DB_PORT', 1433)),
            'database': os.environ['DB_NAME'],
            'user':     os.environ['DB_USER'],
            'password': os.environ['DB_PASSWORD'],
        }


def get_connection():
    c = _cfg()
    return pymssql.connect(
        server=c['server'],
        port=c['port'],
        user=c['user'],
        password=c['password'],
        database=c['database'],
        charset='UTF-8',
    )
