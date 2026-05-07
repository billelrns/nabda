// Nabda — AI Chat screen
const AD = window.NABDA_DATA;

function ChatScreen({ persona = 'نبضة' }) {
  const [messages, setMessages] = useState(AD.chatHistory);
  const [input, setInput] = useState('');
  const [typing, setTyping] = useState(false);
  const scrollRef = useRef();

  useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [messages, typing]);

  const send = (text) => {
    if (!text.trim()) return;
    const time = new Date().toLocaleTimeString('ar-DZ', { hour: '2-digit', minute: '2-digit' });
    setMessages(m => [...m, { from: 'me', text, time }]);
    setInput('');
    setTyping(true);
    setTimeout(() => {
      setTyping(false);
      const replies = [
        'سؤال رائع 🌸 دعيني أوضّح لك...\n\nخلال الأسبوع 25 من الحمل، يُنصح بـ:\n• شرب كمية كافية من الماء (2 لتر يوميًا)\n• تناول وجبات صغيرة متكررة\n• ممارسة رياضة خفيفة كالمشي\n• النوم على الجانب الأيسر\n\nهل تودّين معرفة المزيد عن أحد هذه الجوانب؟',
        'هذه نقطة مهمة 💛 الرياضة الآمنة في الأسبوع 25 تشمل:\n• المشي 30 دقيقة يوميًا\n• اليوغا للحوامل\n• السباحة\n• تمارين كيغل\n\n⚠️ تجنّبي: التمارين الشاقة، حمل الأثقال، الأنشطة التي تتطلّب توازنًا.',
        'بكل سرور! إليك وصفة عشاء صحية 🥗\n\n**سلطة الكينوا والأفوكادو**\nالمكوّنات:\n• كوب كينوا مطبوخة\n• حبة أفوكادو\n• طماطم كرزية\n• ليمون وزيت زيتون\n\nغنية بالحديد، البروتين والأوميغا 3 — مثالية لك ولجنينك 💚',
      ];
      const reply = replies[Math.floor(Math.random() * replies.length)];
      setMessages(m => [...m, { from: 'ai', text: reply, time }]);
    }, 1400);
  };

  return (
    <div className="screen-enter" style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
      {/* Header */}
      <div style={{
        background: 'linear-gradient(135deg, #E91E63 0%, #7E57C2 100%)',
        padding: '16px 20px 18px',
        borderRadius: '0 0 24px 24px',
        color: '#fff',
        position: 'relative',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{
            width: 48, height: 48, borderRadius: '50%',
            background: 'rgba(255,255,255,.2)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 24, position: 'relative',
          }}>
            ✨
            <span style={{ position: 'absolute', bottom: 0, right: 2, width: 12, height: 12, borderRadius: '50%', background: '#34A853', border: '2px solid #fff' }} />
          </div>
          <div style={{ flex: 1 }}>
            <h2 style={{ margin: 0, fontSize: 18, fontWeight: 800 }}>{persona}</h2>
            <p style={{ margin: '2px 0 0', fontSize: 12, opacity: .85 }}>مساعدتك الذكية • متاحة الآن</p>
          </div>
          <IconBtn name="menu" />
        </div>

        {/* Disclaimer */}
        <div style={{
          marginTop: 14, padding: '8px 12px', borderRadius: 12,
          background: 'rgba(255,255,255,.15)', backdropFilter: 'blur(8px)',
          fontSize: 11, lineHeight: 1.5,
        }}>
          ⚠️ المعلومات للإرشاد فقط، لا تغني عن استشارة طبيبك المعالج.
        </div>
      </div>

      {/* Messages */}
      <div ref={scrollRef} style={{ flex: 1, overflowY: 'auto', padding: '16px 16px 8px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        <div style={{ textAlign: 'center', fontSize: 11, color: 'var(--ink-3)', padding: 4 }}>اليوم • 10:24</div>

        {messages.map((m, i) => <Message key={i} m={m} />)}

        {typing && (
          <div style={{ alignSelf: 'flex-start', display: 'flex', gap: 8, alignItems: 'flex-end' }}>
            <Avatar />
            <div style={{
              background: 'var(--surface)', padding: '14px 18px', borderRadius: '20px 20px 20px 4px',
              boxShadow: 'var(--shadow-sm)', display: 'flex', gap: 4,
            }}>
              {[0,1,2].map(i => <span key={i} className="dot" style={{
                width: 6, height: 6, borderRadius: '50%', background: 'var(--pink)',
                animation: `bob 1.2s ${i * .15}s infinite ease-in-out`,
              }} />)}
            </div>
          </div>
        )}

        {/* Suggestions (only at start) */}
        {messages.length <= 3 && (
          <div style={{ marginTop: 6 }}>
            <p className="t-small" style={{ marginBottom: 8, paddingInline: 4 }}>اقتراحات سريعة:</p>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {AD.chatSuggestions.map((s, i) => (
                <button key={i} onClick={() => send(s)} style={{
                  background: 'var(--surface)', border: '1px solid var(--line)',
                  borderRadius: 999, padding: '8px 14px', fontSize: 12, fontWeight: 700,
                  cursor: 'pointer', fontFamily: 'inherit', color: 'var(--purple-700)',
                }}>{s}</button>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Input */}
      <div style={{
        background: 'var(--surface)', borderTop: '1px solid var(--line)',
        padding: '12px 14px 14px', display: 'flex', gap: 8, alignItems: 'center',
      }}>
        <button style={chatActionBtn}><Icon name="plus" size={20} /></button>
        <div style={{
          flex: 1, background: 'var(--bg-2)', borderRadius: 999, padding: '8px 14px',
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <input value={input} onChange={e => setInput(e.target.value)}
                 onKeyDown={e => e.key === 'Enter' && send(input)}
                 placeholder="اكتبي رسالتك..."
                 style={{ flex: 1, border: 0, outline: 0, background: 'transparent', fontFamily: 'inherit', fontSize: 14, color: 'var(--ink)' }} />
          <Icon name="image" size={20} color="#8B8190" />
        </div>
        <button onClick={() => send(input)} style={{
          width: 44, height: 44, borderRadius: '50%', border: 0, cursor: 'pointer',
          background: 'linear-gradient(135deg, var(--pink), var(--purple))',
          color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 12px rgba(233,30,99,.3)',
        }}>
          {input.trim() ? <Icon name="send" size={18} /> : <Icon name="mic" size={18} />}
        </button>
      </div>

      <style>{`@keyframes bob { 0%,80%,100% { transform: translateY(0); opacity: .4 } 40% { transform: translateY(-4px); opacity: 1 } }`}</style>
    </div>
  );
}

const Avatar = () => (
  <div style={{
    width: 30, height: 30, borderRadius: '50%',
    background: 'linear-gradient(135deg, #E91E63, #7E57C2)',
    color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
    fontSize: 14, flexShrink: 0,
  }}>✨</div>
);

function Message({ m }) {
  const isMe = m.from === 'me';
  return (
    <div style={{ alignSelf: isMe ? 'flex-end' : 'flex-start', maxWidth: '82%', display: 'flex', gap: 8, alignItems: 'flex-end' }}>
      {!isMe && <Avatar />}
      <div>
        <div style={{
          background: isMe
            ? 'linear-gradient(135deg, #00897B, #00796B)'
            : 'var(--surface)',
          color: isMe ? '#fff' : 'var(--ink)',
          padding: '12px 16px',
          borderRadius: isMe ? '20px 20px 4px 20px' : '20px 20px 20px 4px',
          boxShadow: 'var(--shadow-sm)',
          fontSize: 14, lineHeight: 1.6, whiteSpace: 'pre-wrap',
        }}>
          {m.text}
        </div>
        <p style={{ margin: '4px 8px 0', fontSize: 10, color: 'var(--ink-3)', textAlign: isMe ? 'left' : 'right' }}>{m.time}</p>
      </div>
    </div>
  );
}

const chatActionBtn = {
  width: 40, height: 40, borderRadius: '50%', border: 0, cursor: 'pointer',
  background: 'var(--bg-2)', color: 'var(--ink-2)',
  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
};

window.ChatScreen = ChatScreen;
