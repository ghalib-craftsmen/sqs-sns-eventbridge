import { useState } from 'react'

const S = { idle: 'idle', loading: 'loading', ok: 'ok', error: 'error' }

export default function App() {
  const [id, setId] = useState('')
  const [name, setName] = useState('')
  const [sendInvalid, setSendInvalid] = useState(false)
  const [status, setStatus] = useState(S.idle)
  const [errMsg, setErrMsg] = useState('')

  async function handleSubmit(e) {
    e.preventDefault()
    setStatus(S.loading)
    setErrMsg('')

    const body = sendInvalid
      ? JSON.stringify({ oops: 'missing id and name fields' })
      : JSON.stringify({ id: id.trim(), name: name.trim() })

    try {
      const res = await fetch('/api/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body,
      })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      setStatus(S.ok)
      setId('')
      setName('')
    } catch (err) {
      setStatus(S.error)
      setErrMsg(err.message)
    }
  }

  const loading = status === S.loading

  return (
    <div style={css.page}>
      <div style={css.card}>
        <h1 style={css.title}>SQS Message Sender</h1>
        <p style={css.sub}>
          CloudFront → API Gateway → SQS → Step Functions → DynamoDB / SNS
        </p>

        <form onSubmit={handleSubmit} style={css.form}>
          <label style={css.label}>
            ID
            <input
              style={css.input}
              value={id}
              onChange={e => setId(e.target.value)}
              placeholder="msg-001"
              disabled={sendInvalid || loading}
              required={!sendInvalid}
            />
          </label>

          <label style={css.label}>
            Name
            <input
              style={css.input}
              value={name}
              onChange={e => setName(e.target.value)}
              placeholder="Alice"
              disabled={sendInvalid || loading}
              required={!sendInvalid}
            />
          </label>

          <label style={css.checkLabel}>
            <input
              type="checkbox"
              checked={sendInvalid}
              onChange={e => setSendInvalid(e.target.checked)}
              disabled={loading}
            />
            Send invalid message (triggers SNS email alert)
          </label>

          <button
            type="submit"
            style={{ ...css.btn, ...(loading ? css.btnDisabled : {}) }}
            disabled={loading}
          >
            {loading ? 'Sending…' : 'Send Message'}
          </button>
        </form>

        {status === S.ok && (
          <div style={{ ...css.banner, ...css.bannerOk }}>
            {sendInvalid
              ? 'Invalid message sent — check your email for the SNS alert.'
              : 'Valid message sent — check DynamoDB for the stored item.'}
          </div>
        )}

        {status === S.error && (
          <div style={{ ...css.banner, ...css.bannerErr }}>
            Error: {errMsg}
          </div>
        )}

        <div style={css.pills}>
          <span style={css.pill}>Valid → DynamoDB</span>
          <span style={css.pill}>Invalid → SNS email</span>
          <span style={css.pill}>3× failure → DLQ</span>
        </div>
      </div>
    </div>
  )
}

const css = {
  page: {
    minHeight: '100vh',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: '#f3f4f6',
    fontFamily: 'system-ui, -apple-system, sans-serif',
  },
  card: {
    background: '#fff',
    borderRadius: 12,
    padding: '2.5rem',
    width: '100%',
    maxWidth: 420,
    boxShadow: '0 4px 24px rgba(0,0,0,0.08)',
  },
  title:  { margin: '0 0 0.25rem', fontSize: '1.5rem', color: '#111827' },
  sub:    { margin: '0 0 1.75rem', fontSize: '0.825rem', color: '#6b7280', lineHeight: 1.5 },
  form:   { display: 'flex', flexDirection: 'column', gap: '1rem' },
  label:  { display: 'flex', flexDirection: 'column', gap: 4, fontSize: '0.875rem', fontWeight: 600, color: '#374151' },
  input:  { padding: '0.5rem 0.75rem', borderRadius: 6, border: '1px solid #d1d5db', fontSize: '1rem' },
  checkLabel: { display: 'flex', alignItems: 'center', gap: 8, fontSize: '0.875rem', color: '#374151', cursor: 'pointer' },
  btn:        { padding: '0.65rem', borderRadius: 8, border: 'none', background: '#2563eb', color: '#fff', fontSize: '1rem', fontWeight: 600, cursor: 'pointer' },
  btnDisabled: { opacity: 0.55, cursor: 'not-allowed' },
  banner:    { marginTop: '1rem', padding: '0.75rem 1rem', borderRadius: 8, fontSize: '0.875rem' },
  bannerOk:  { background: '#dcfce7', color: '#166534' },
  bannerErr: { background: '#fee2e2', color: '#991b1b' },
  pills: { marginTop: '1.5rem', display: 'flex', flexWrap: 'wrap', gap: 6, justifyContent: 'center' },
  pill:  { fontSize: '0.7rem', color: '#9ca3af', background: '#f9fafb', padding: '0.2rem 0.6rem', borderRadius: 99, border: '1px solid #e5e7eb' },
}
