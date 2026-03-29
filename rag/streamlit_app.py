import streamlit as st
import os
import glob
import json
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="TXT RAG – Cortex Search", page_icon="❄️", layout="wide")

# ── Active Snowpark session ───────────────────────────────────────────────────
session = get_active_session()

# ── Styles ────────────────────────────────────────────────────────────────────
st.markdown("""
<style>
    .main-header { font-size:2rem; font-weight:700; color:#1a1a2e; }
    .sub-header  { color:#666; font-size:0.95rem; margin-bottom:1.5rem; }
    .file-card {
        background:#f8f9fa; border:1px solid #e0e0e0;
        border-radius:10px; padding:1rem 1.4rem;
        margin-bottom:0.8rem; border-left:5px solid #29b5e8;
    }
    .file-title { font-size:1rem; font-weight:600; color:#1a1a2e; }
    .badge {
        display:inline-block; background:#e0f4fb; color:#0e7fa8;
        border-radius:6px; padding:2px 9px; font-size:0.78rem;
        font-weight:600; margin-right:5px;
    }
    .indexed { color:#16a34a; font-size:0.8rem; font-weight:600; }
    .not-indexed { color:#f59e0b; font-size:0.8rem; font-weight:600; }
</style>
""", unsafe_allow_html=True)

# ── Session state ─────────────────────────────────────────────────────────────
if "indexed_files" not in st.session_state:
    st.session_state.indexed_files = set()
if "chat_messages" not in st.session_state:
    st.session_state.chat_messages = []

# ── Header ────────────────────────────────────────────────────────────────────
st.markdown('<div class="main-header">❄️ TXT RAG — Snowflake Cortex Search</div>', unsafe_allow_html=True)
st.markdown('<div class="sub-header">Reads .txt files from the current directory → indexes into Snowflake → answers your questions</div>', unsafe_allow_html=True)

# ── Sidebar ───────────────────────────────────────────────────────────────────
with st.sidebar:
    st.header("⚙️ Settings")
    model = st.selectbox("LLM Model", [
        "mistral-large2", "snowflake-arctic", "llama3.1-70b",
        "llama3.1-8b", "mixtral-8x7b"
    ])
    st.markdown("---")
    st.caption("Place your `.txt` files in the same directory as this app. Run `setup.sql` once to create the Snowflake objects.")

# ══════════════════════════════════════════════════════════════════════════════
# Helper – chunk text
# ══════════════════════════════════════════════════════════════════════════════
def chunk_text(text: str, chunk_size: int = 1000, overlap: int = 150):
    chunks, start = [], 0
    while start < len(text):
        end = min(start + chunk_size, len(text))
        chunks.append(text[start:end])
        start += chunk_size - overlap
    return chunks

# ══════════════════════════════════════════════════════════════════════════════
# Helper – insert chunks via explicit SQL (avoids column count mismatch)
# ══════════════════════════════════════════════════════════════════════════════
def insert_chunks(file_name: str, chunks: list):
    safe_name = file_name.replace("'", "''")
    for i, chunk in enumerate(chunks):
        safe_chunk = chunk.replace("'", "''")
        session.sql(
            f"INSERT INTO PDF_RAG_DB.DATA.DOCS_CHUNKS (FILE_NAME, CHUNK_INDEX, CHUNK) "
            f"VALUES ('{safe_name}', {i}, '{safe_chunk}')"
        ).collect()

# ══════════════════════════════════════════════════════════════════════════════
# Helper – Cortex Search
# ══════════════════════════════════════════════════════════════════════════════
def cortex_search(question: str, limit: int = 5):
    safe_question = question.replace("'", "''")
    payload = json.dumps({
        "query": safe_question,
        "columns": ["CHUNK", "FILE_NAME"],
        "limit": limit
    }).replace("'", "''")
    query = f"""
        SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
            'PDF_RAG_DB.DATA.PDF_SEARCH_SERVICE',
            '{payload}'
        ) AS results
    """
    rows = session.sql(query).collect()
    if rows and rows[0]["RESULTS"]:
        data = json.loads(rows[0]["RESULTS"])
        return data.get("results", [])
    return []

# ══════════════════════════════════════════════════════════════════════════════
# Helper – Cortex Complete
# ══════════════════════════════════════════════════════════════════════════════
def cortex_complete(model: str, question: str, context_chunks: list) -> str:
    context = "\n\n---\n\n".join(
        f"[From: {c.get('FILE_NAME', 'unknown')}]\n{c.get('CHUNK', '')}"
        for c in context_chunks
    )
    prompt = (
        "You are a helpful assistant. Use ONLY the context below to answer the question.\n"
        "If the answer is not in the context, say \"I couldn't find that in the documents.\"\n\n"
        f"Context:\n{context}\n\nQuestion: {question}\nAnswer:"
    )
    safe_prompt = prompt.replace("'", "''")
    rows = session.sql(
        f"SELECT SNOWFLAKE.CORTEX.COMPLETE('{model}', '{safe_prompt}') AS answer"
    ).collect()
    return rows[0]["ANSWER"] if rows else "No response from LLM."

# ══════════════════════════════════════════════════════════════════════════════
# Discover .txt files in current directory
# ══════════════════════════════════════════════════════════════════════════════
txt_files = sorted(glob.glob(os.path.join(os.path.dirname(__file__), "*.txt")))

st.markdown("#### 📂 Text Files in Current Directory")

if not txt_files:
    st.info("No `.txt` files found in the app directory. Add some `.txt` files alongside this app and refresh.")
else:
    col_all, _ = st.columns([2, 8])
    with col_all:
        if st.button("⚡ Index All Files", use_container_width=True):
            with st.spinner("Indexing all files into Snowflake..."):
                for fpath in txt_files:
                    fname = os.path.basename(fpath)
                    if fname not in st.session_state.indexed_files:
                        text = open(fpath, "r", encoding="utf-8", errors="ignore").read()
                        chunks = chunk_text(text)
                        insert_chunks(fname, chunks)
                        st.session_state.indexed_files.add(fname)
            st.success("✅ All files indexed!")
            st.experimental_rerun()

    st.markdown("---")

    for fpath in txt_files:
        fname = os.path.basename(fpath)
        size_kb = round(os.path.getsize(fpath) / 1024, 1)
        text_preview = open(fpath, "r", encoding="utf-8", errors="ignore").read(200).replace("\n", " ")
        is_indexed = fname in st.session_state.indexed_files

        st.markdown(f"""
        <div class="file-card">
            <div class="file-title">📄 {fname}</div>
            <div style="margin-top:0.3rem;">
                <span class="badge">💾 {size_kb} KB</span>
                <span class="{'indexed' if is_indexed else 'not-indexed'}">
                    {'✅ Indexed' if is_indexed else '⏳ Not indexed'}
                </span>
            </div>
            <div style="color:#888;font-size:0.8rem;margin-top:0.4rem;font-style:italic;">
                {text_preview}{'…' if len(text_preview) == 200 else ''}
            </div>
        </div>
        """, unsafe_allow_html=True)

        if not is_indexed:
            if st.button(f"Index {fname}", key=f"idx_{fname}"):
                with st.spinner(f"Indexing {fname}..."):
                    text = open(fpath, "r", encoding="utf-8", errors="ignore").read()
                    chunks = chunk_text(text)
                    insert_chunks(fname, chunks)
                    st.session_state.indexed_files.add(fname)
                st.success(f"✅ {fname} indexed!")
                st.experimental_rerun()

# ══════════════════════════════════════════════════════════════════════════════
# Chat Window
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
st.markdown("#### 💬 Ask your documents")

chat_container = st.container()
with chat_container:
    if not st.session_state.chat_messages:
        st.markdown("""
        <div style='text-align:center;color:#bbb;padding:4rem 0;'>
            <div style='font-size:2rem;'>💬</div>
            <div style='font-size:0.9rem;margin-top:0.4rem;'>Index files above, then ask anything about them…</div>
        </div>""", unsafe_allow_html=True)
    else:
        for msg in st.session_state.chat_messages:
            if msg["role"] == "user":
                st.markdown(f"""
                <div style='display:flex;justify-content:flex-end;margin-bottom:0.5rem;'>
                    <div style='background:#29b5e8;color:white;padding:0.55rem 1rem;
                                border-radius:16px 16px 4px 16px;max-width:72%;font-size:0.88rem;'>
                        {msg["content"]}
                    </div>
                </div>""", unsafe_allow_html=True)
            else:
                st.markdown(f"""
                <div style='display:flex;justify-content:flex-start;margin-bottom:0.5rem;'>
                    <div style='background:#f1f1f1;color:#333;padding:0.55rem 1rem;
                                border-radius:16px 16px 16px 4px;max-width:72%;font-size:0.88rem;'>
                        {msg["content"]}
                    </div>
                </div>""", unsafe_allow_html=True)

# ── Chat input ────────────────────────────────────────────────────────────────
col_input, col_btn = st.columns([9, 1])
with col_input:
    user_input = st.text_input("Ask a question…", key="chat_input", label_visibility="collapsed")
with col_btn:
    send_clicked = st.button("➤", use_container_width=True)

if send_clicked and user_input:
    st.session_state.chat_messages.append({"role": "user", "content": user_input})

    if not st.session_state.indexed_files:
        answer = "⚠️ Please index at least one file first."
    else:
        with st.spinner("Searching & generating answer…"):
            try:
                chunks = cortex_search(user_input)
                if chunks:
                    answer = cortex_complete(model, user_input, chunks)
                else:
                    answer = "I couldn't find relevant content in the indexed documents."
            except Exception as e:
                answer = f"❌ Error: {e}"

    st.session_state.chat_messages.append({"role": "assistant", "content": answer})
    st.experimental_rerun()
