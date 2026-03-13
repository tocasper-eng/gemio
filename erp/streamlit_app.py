import streamlit as st
import pandas as pd
from db import get_connection

# ── i18n ──────────────────────────────────────────────────────────────────────
LANGS = {
    'zh-TW': {
        'title': '客戶主檔',
        'add': '新增', 'edit': '更改', 'delete': '刪除', 'copy': '複製', 'search': '查詢',
        'save': '儲存', 'cancel': '取消', 'confirm': '確定刪除',
        'num': '自動編號', 'custno': '客戶編號', 'custnm': '客戶名稱',
        'kindno': '客戶類別', 'address0': '公司全名',
        'modal_add': '新增客戶', 'modal_edit': '更改客戶', 'modal_copy': '複製客戶',
        'modal_del': '確認刪除',
        'confirm_del': '確定要刪除此筆資料？此動作無法還原。',
        'err_select': '請先在表格中選取一筆資料',
        'err_dup': '客戶編號已存在，請重新輸入',
        'err_required': '客戶編號為必填欄位',
        'ph_search': '輸入關鍵字搜尋...',
    },
    'zh-CN': {
        'title': '客户主档',
        'add': '新增', 'edit': '更改', 'delete': '删除', 'copy': '复制', 'search': '查询',
        'save': '保存', 'cancel': '取消', 'confirm': '确认删除',
        'num': '自动编号', 'custno': '客户编号', 'custnm': '客户名称',
        'kindno': '客户类别', 'address0': '公司全名',
        'modal_add': '新增客户', 'modal_edit': '更改客户', 'modal_copy': '复制客户',
        'modal_del': '确认删除',
        'confirm_del': '确定要删除此条数据？此操作无法撤销。',
        'err_select': '请先在表格中选取一条数据',
        'err_dup': '客户编号已存在，请重新输入',
        'err_required': '客户编号为必填项',
        'ph_search': '输入关键字搜索...',
    },
    'en': {
        'title': 'Customer Master',
        'add': 'Add', 'edit': 'Edit', 'delete': 'Delete', 'copy': 'Copy', 'search': 'Search',
        'save': 'Save', 'cancel': 'Cancel', 'confirm': 'Confirm Delete',
        'num': 'ID', 'custno': 'Customer No.', 'custnm': 'Customer Name',
        'kindno': 'Category', 'address0': 'Company Name',
        'modal_add': 'Add Customer', 'modal_edit': 'Edit Customer', 'modal_copy': 'Copy Customer',
        'modal_del': 'Confirm Delete',
        'confirm_del': 'Are you sure to delete this record? This cannot be undone.',
        'err_select': 'Please select a record in the table first',
        'err_dup': 'Customer No. already exists, please enter another one',
        'err_required': 'Customer No. is required',
        'ph_search': 'Search...',
    },
}

def resolve_lang(code):
    if not code or not isinstance(code, str):
        return 'zh-TW'
    c = code.lower()
    if 'zh-tw' in c or 'zh-hant' in c:
        return 'zh-TW'
    if c.startswith('zh'):
        return 'zh-CN'
    return 'en'

# ── page config (must be first Streamlit command) ──────────────────────────────
st.set_page_config(page_title='ERP', layout='wide', page_icon='📋')

# ── browser language detection ─────────────────────────────────────────────────
try:
    from streamlit_javascript import st_javascript
    _raw_lang = st_javascript("navigator.language || navigator.userLanguage")
except Exception:
    _raw_lang = None

T = LANGS[resolve_lang(_raw_lang)]

# ── session state defaults ─────────────────────────────────────────────────────
_defaults = {
    'dialog':   None,   # None | 'add' | 'edit' | 'copy' | 'delete'
    'row_data': {},
    'search_q': '',
    'data_ver': 0,      # increment to invalidate cache
}
for k, v in _defaults.items():
    if k not in st.session_state:
        st.session_state[k] = v

# ── db helpers ─────────────────────────────────────────────────────────────────
@st.cache_data(show_spinner=False)
def db_load(q: str, ver: int) -> pd.DataFrame:
    conn = get_connection()
    try:
        cur = conn.cursor()
        if q:
            cur.execute(
                "SELECT num, custno, custnm, kindno, address0 FROM cust "
                "WHERE custno LIKE ? OR custnm LIKE ? OR address0 LIKE ?",
                f'%{q}%', f'%{q}%', f'%{q}%',
            )
        else:
            cur.execute("SELECT num, custno, custnm, kindno, address0 FROM cust")
        cols = [c[0] for c in cur.description]
        return pd.DataFrame(cur.fetchall(), columns=cols)
    finally:
        conn.close()


@st.cache_data(ttl=300, show_spinner=False)
def db_kindno() -> list:
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT dictnm FROM dict WHERE dictno = 'kindno'")
        return [''] + [r[0] for r in cur.fetchall()]
    finally:
        conn.close()


def db_create(d: dict) -> str:
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT 1 FROM cust WHERE custno = ?", d['custno'])
        if cur.fetchone():
            return 'dup'
        cur.execute(
            "INSERT INTO cust (custno, custnm, kindno, address0) VALUES (?,?,?,?)",
            d['custno'], d.get('custnm'), d.get('kindno') or None, d.get('address0'),
        )
        conn.commit()
        return 'ok'
    finally:
        conn.close()


def db_update(num: int, d: dict) -> str:
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT 1 FROM cust WHERE custno = ? AND num <> ?", d['custno'], num)
        if cur.fetchone():
            return 'dup'
        cur.execute(
            "UPDATE cust SET custno=?, custnm=?, kindno=?, address0=? WHERE num=?",
            d['custno'], d.get('custnm'), d.get('kindno') or None, d.get('address0'), num,
        )
        conn.commit()
        return 'ok'
    finally:
        conn.close()


def db_delete(num: int):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM cust WHERE num = ?", num)
        conn.commit()
    finally:
        conn.close()

# ── form helpers ───────────────────────────────────────────────────────────────
def reset_form(mode: str, data: dict = None):
    """Pre-fill session state before opening a dialog."""
    data = data or {}
    opts = db_kindno()
    st.session_state.f_custno   = '' if mode == 'copy' else data.get('custno', '')
    st.session_state.f_custnm   = data.get('custnm', '')
    st.session_state.f_kindno   = data.get('kindno', opts[0] if opts else '')
    st.session_state.f_address0 = data.get('address0', '')


def form_body(mode: str):
    """Shared form used by add / edit / copy dialogs."""
    init = st.session_state.row_data

    if mode == 'edit':
        st.text_input(T['num'], value=str(init.get('num', '')), disabled=True)

    custno   = st.text_input(T['custno'],  key='f_custno')
    custnm   = st.text_input(T['custnm'],  key='f_custnm')
    kindno   = st.selectbox(T['kindno'],   options=db_kindno(), key='f_kindno')
    address0 = st.text_input(T['address0'], key='f_address0')

    st.divider()
    c1, c2 = st.columns(2)
    with c1:
        if st.button(T['save'], type='primary', use_container_width=True):
            if not custno.strip():
                st.error(T['err_required'])
                return
            payload = {
                'custno':   custno.strip(),
                'custnm':   custnm.strip(),
                'kindno':   kindno or None,
                'address0': address0.strip(),
            }
            result = (
                db_update(int(init['num']), payload) if mode == 'edit'
                else db_create(payload)
            )
            if result == 'dup':
                st.error(T['err_dup'])
            else:
                st.session_state.dialog   = None
                st.session_state.row_data = {}
                st.session_state.data_ver += 1
                st.rerun()
    with c2:
        if st.button(T['cancel'], use_container_width=True):
            st.session_state.dialog = None
            st.rerun()

# ── dialogs ────────────────────────────────────────────────────────────────────
@st.dialog(T['modal_add'])
def dialog_add():
    form_body('add')

@st.dialog(T['modal_edit'])
def dialog_edit():
    form_body('edit')

@st.dialog(T['modal_copy'])
def dialog_copy():
    form_body('copy')

@st.dialog(T['modal_del'])
def dialog_delete():
    d = st.session_state.row_data
    st.warning(T['confirm_del'])
    st.markdown(f"**{d.get('custno', '')}  {d.get('custnm', '')}**")
    st.divider()
    c1, c2 = st.columns(2)
    with c1:
        if st.button(T['confirm'], type='primary', use_container_width=True):
            db_delete(int(d['num']))
            st.session_state.dialog   = None
            st.session_state.row_data = {}
            st.session_state.data_ver += 1
            st.rerun()
    with c2:
        if st.button(T['cancel'], use_container_width=True):
            st.session_state.dialog = None
            st.rerun()

# ── heading ────────────────────────────────────────────────────────────────────
st.markdown(f"### 📋 {T['title']}")

# ── toolbar ────────────────────────────────────────────────────────────────────
c_add, c_edit, c_del, c_copy, c_q, c_search = st.columns([1, 1, 1, 1, 4, 1])

with c_add:
    if st.button(T['add'], use_container_width=True):
        reset_form('add')
        st.session_state.dialog = 'add'
        st.rerun()

with c_edit:
    if st.button(T['edit'], use_container_width=True):
        if not st.session_state.row_data:
            st.toast(T['err_select'], icon='⚠️')
        else:
            reset_form('edit', st.session_state.row_data)
            st.session_state.dialog = 'edit'
            st.rerun()

with c_del:
    if st.button(T['delete'], use_container_width=True):
        if not st.session_state.row_data:
            st.toast(T['err_select'], icon='⚠️')
        else:
            st.session_state.dialog = 'delete'
            st.rerun()

with c_copy:
    if st.button(T['copy'], use_container_width=True):
        if not st.session_state.row_data:
            st.toast(T['err_select'], icon='⚠️')
        else:
            reset_form('copy', st.session_state.row_data)
            st.session_state.dialog = 'copy'
            st.rerun()

with c_q:
    with st.form('search_form', clear_on_submit=False, border=False):
        search_q = st.text_input(
            '', placeholder=T['ph_search'],
            label_visibility='collapsed',
            value=st.session_state.search_q,
        )
        submitted = st.form_submit_button(T['search'])
    if submitted:
        st.session_state.search_q = search_q
        st.session_state.row_data = {}
        st.rerun()

with c_search:
    # spacer – search button is inside the form above
    st.write('')

# ── data grid ──────────────────────────────────────────────────────────────────
df = db_load(st.session_state.search_q, st.session_state.data_ver)

col_cfg = {
    'num':      st.column_config.NumberColumn(T['num'],      width='small'),
    'custno':   st.column_config.TextColumn(T['custno'],     width='medium'),
    'custnm':   st.column_config.TextColumn(T['custnm'],     width='large'),
    'kindno':   st.column_config.TextColumn(T['kindno'],     width='medium'),
    'address0': st.column_config.TextColumn(T['address0'],   width='large'),
}

event = st.dataframe(
    df,
    column_config=col_cfg,
    use_container_width=True,
    hide_index=True,
    on_select='rerun',
    selection_mode='single-row',
    height=520,
)

# persist selected row into session state
sel = event.selection.rows
if sel:
    st.session_state.row_data = df.iloc[sel[0]].to_dict()

# ── open dialogs ───────────────────────────────────────────────────────────────
dlg = st.session_state.dialog
if   dlg == 'add':    dialog_add()
elif dlg == 'edit':   dialog_edit()
elif dlg == 'copy':   dialog_copy()
elif dlg == 'delete': dialog_delete()
