// Quick test script for AI endpoint
const testPrompt = 'What is this task about?';

fetch('http://localhost:3001/api/ai/enhance', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    taskId: 'TASK-001',
    prompt: testPrompt,
    conversationHistory: []
  })
})
.then(res => res.json())
.then(data => {
  if (data.error) {
    console.error('❌ AI Error:', data.error);
    process.exit(1);
  } else {
    console.log('✅ AI Response:', data.response.substring(0, 200) + '...');
    console.log('\n✅ AI Assistant is working!');
    process.exit(0);
  }
})
.catch(err => {
  console.error('❌ Request Error:', err.message);
  process.exit(1);
});
