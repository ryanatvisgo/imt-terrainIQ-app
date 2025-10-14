const express = require('express');
const fs = require('fs').promises;
const path = require('path');
const cors = require('cors');
const Anthropic = require('@anthropic-ai/sdk');

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());
app.use(express.static('.'));

const KANBAN_DIR = path.join(__dirname, 'kanban');
const COLUMNS = ['backlog', 'ready', 'in_progress', 'review', 'done'];

// Initialize Anthropic client
const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY || ''
});

// Helper function to parse markdown with YAML frontmatter
function parseMarkdownTask(content) {
  const parts = content.split('---\n');
  if (parts.length < 3) {
    throw new Error('Invalid markdown format: missing frontmatter');
  }

  const frontmatter = parts[1];
  const markdown = parts.slice(2).join('---\n');

  // Parse frontmatter
  const task = {};
  frontmatter.split('\n').forEach(line => {
    if (line.includes(':')) {
      const [key, ...valueParts] = line.split(':');
      const value = valueParts.join(':').trim();

      // Handle different value types
      if (value.toLowerCase() === 'null') {
        task[key.trim()] = null;
      } else if (value.toLowerCase() === 'true') {
        task[key.trim()] = true;
      } else if (value.toLowerCase() === 'false') {
        task[key.trim()] = false;
      } else if (value.startsWith('[') && value.endsWith(']')) {
        // Parse array
        if (value === '[]') {
          task[key.trim()] = [];
        } else {
          const items = value.slice(1, -1).split(',').map(i => i.trim());
          task[key.trim()] = items;
        }
      } else {
        task[key.trim()] = value;
      }
    }
  });

  // Parse markdown sections
  const sections = {};
  let currentSection = null;
  let currentContent = [];

  markdown.split('\n').forEach(line => {
    if (line.startsWith('## ')) {
      if (currentSection) {
        sections[currentSection] = currentContent.join('\n');
      }
      currentSection = line.substring(3).trim();
      currentContent = [];
    } else if (currentSection) {
      currentContent.push(line);
    }
  });

  if (currentSection) {
    sections[currentSection] = currentContent.join('\n');
  }

  // Extract structured data from sections
  if (sections['Description']) {
    task.description = sections['Description'].trim();
  }

  if (sections['Use Case']) {
    task.use_case = sections['Use Case'].trim();
  }

  if (sections['Acceptance Criteria']) {
    task.acceptance_criteria = [];
    sections['Acceptance Criteria'].split('\n').forEach(line => {
      line = line.trim();
      if (line.startsWith('- [')) {
        task.acceptance_criteria.push(line.substring(6).trim());
      }
    });
  }

  if (sections['Notes']) {
    task.notes = [];
    sections['Notes'].split('\n').forEach(line => {
      line = line.trim();
      if (line.startsWith('- ') || line.startsWith('* ')) {
        task.notes.push(line.substring(2).trim());
      }
    });
  }

  if (sections['Subtasks']) {
    task.subtasks = [];
    sections['Subtasks'].split('\n').forEach(line => {
      line = line.trim();
      if (line.startsWith('- [x]') || line.startsWith('- [X]')) {
        task.subtasks.push({ title: line.substring(6).trim(), completed: true });
      } else if (line.startsWith('- [ ]')) {
        task.subtasks.push({ title: line.substring(6).trim(), completed: false });
      }
    });
  }

  task.test_data = { good_samples: [], bad_samples: [] };

  return task;
}

// Helper function to convert task to markdown
function taskToMarkdown(task) {
  let md = '---\n';
  md += `id: ${task.id}\n`;
  md += `title: ${task.title}\n`;
  md += `type: ${task.type || 'feature'}\n`;
  md += `priority: ${task.priority || 'medium'}\n`;
  md += `assignee: ${task.assignee || 'unassigned'}\n`;
  md += `validation_status: ${task.validation_status || 'pending'}\n`;
  md += `created_at: ${task.created_at || ''}\n`;
  md += `updated_at: ${task.updated_at || ''}\n`;
  md += `completed_at: ${task.completed_at || 'null'}\n`;

  const tags = task.tags || [];
  md += `tags: [${Array.isArray(tags) ? tags.join(', ') : tags}]\n`;
  md += '---\n\n';

  md += `# ${task.title}\n\n`;
  md += `## Description\n\n`;
  md += `${task.description || 'No description provided'}\n\n`;

  md += `## Use Case\n\n`;
  md += `${task.use_case || '_No use case specified_'}\n\n`;

  md += `## Acceptance Criteria\n\n`;
  if (task.acceptance_criteria && task.acceptance_criteria.length > 0) {
    task.acceptance_criteria.forEach(criterion => {
      md += `- [ ] ${criterion}\n`;
    });
  } else {
    md += `_No criteria specified yet_\n`;
  }
  md += `\n`;

  md += `## Test Data\n\n`;
  md += `### Good Samples\n`;
  md += `_No good samples defined_\n\n`;
  md += `### Bad Samples\n`;
  md += `_No bad samples defined_\n\n`;

  md += `## Subtasks\n\n`;
  if (task.subtasks && task.subtasks.length > 0) {
    task.subtasks.forEach(subtask => {
      const checkbox = subtask.completed ? '[x]' : '[ ]';
      md += `- ${checkbox} ${subtask.title}\n`;
    });
  } else {
    md += `_No subtasks defined_\n`;
  }
  md += `\n`;

  md += `## Notes\n\n`;
  if (task.notes && task.notes.length > 0) {
    task.notes.forEach(note => {
      md += `- ${note}\n`;
    });
  } else {
    md += `_No notes yet_\n`;
  }

  return md;
}

// Helper function to read all tasks
async function getAllTasks() {
  const board = {
    backlog: [],
    ready: [],
    in_progress: [],
    review: [],
    done: []
  };

  for (const column of COLUMNS) {
    const columnPath = path.join(KANBAN_DIR, column);
    try {
      const files = await fs.readdir(columnPath);
      const mdFiles = files.filter(f => f.endsWith('.md'));

      for (const file of mdFiles) {
        const filePath = path.join(columnPath, file);
        const content = await fs.readFile(filePath, 'utf-8');
        const task = parseMarkdownTask(content);
        board[column].push(task);
      }

      // Sort by task ID
      board[column].sort((a, b) => {
        const numA = parseInt(a.id.split('-')[1]);
        const numB = parseInt(b.id.split('-')[1]);
        return numA - numB;
      });
    } catch (err) {
      console.error(`Error reading column ${column}:`, err);
    }
  }

  return board;
}

// Helper function to find task file
async function findTaskFile(taskId) {
  for (const column of COLUMNS) {
    const columnPath = path.join(KANBAN_DIR, column);
    const filePath = path.join(columnPath, `${taskId}.md`);
    try {
      await fs.access(filePath);
      return { column, filePath };
    } catch (err) {
      // File doesn't exist in this column, continue
    }
  }
  return null;
}

// Helper function to read project context
async function getProjectContext() {
  try {
    const requirementsPath = path.join(__dirname, 'REQUIREMENTS.md');
    const projectInfoPath = path.join(__dirname, '.claude', 'project_info.md');

    const requirements = await fs.readFile(requirementsPath, 'utf-8');
    const projectInfo = await fs.readFile(projectInfoPath, 'utf-8');

    return {
      requirements: requirements.substring(0, 5000), // Limit context size
      projectInfo: projectInfo.substring(0, 3000)
    };
  } catch (err) {
    console.error('Error reading project context:', err);
    return { requirements: '', projectInfo: '' };
  }
}

// API Routes

// Get all tasks organized by column
app.get('/api/board', async (req, res) => {
  try {
    const board = await getAllTasks();
    res.json(board);
  } catch (err) {
    console.error('Error getting board:', err);
    res.status(500).json({ error: 'Failed to load board' });
  }
});

// Get specific task
app.get('/api/task/:id', async (req, res) => {
  try {
    const taskLocation = await findTaskFile(req.params.id);
    if (!taskLocation) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const content = await fs.readFile(taskLocation.filePath, 'utf-8');
    const task = parseMarkdownTask(content);
    res.json({ task, column: taskLocation.column });
  } catch (err) {
    console.error('Error getting task:', err);
    res.status(500).json({ error: 'Failed to load task' });
  }
});

// Update task
app.put('/api/task/:id', async (req, res) => {
  try {
    const taskLocation = await findTaskFile(req.params.id);
    if (!taskLocation) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const updatedTask = {
      ...req.body,
      updated_at: new Date().toISOString()
    };

    const markdown = taskToMarkdown(updatedTask);

    await fs.writeFile(
      taskLocation.filePath,
      markdown,
      'utf-8'
    );

    res.json({ success: true, task: updatedTask });
  } catch (err) {
    console.error('Error updating task:', err);
    res.status(500).json({ error: 'Failed to update task' });
  }
});

// Move task to different column
app.post('/api/task/:id/move', async (req, res) => {
  try {
    const { toColumn } = req.body;

    if (!COLUMNS.includes(toColumn)) {
      return res.status(400).json({ error: 'Invalid column' });
    }

    const taskLocation = await findTaskFile(req.params.id);
    if (!taskLocation) {
      return res.status(404).json({ error: 'Task not found' });
    }

    if (taskLocation.column === toColumn) {
      return res.json({ success: true, message: 'Task already in target column' });
    }

    // Read task
    const content = await fs.readFile(taskLocation.filePath, 'utf-8');
    const task = parseMarkdownTask(content);

    // Update task metadata
    task.updated_at = new Date().toISOString();
    if (toColumn === 'done' && !task.completed_at) {
      task.completed_at = new Date().toISOString();
      task.validation_status = 'passed';
    }

    // Write to new location
    const newPath = path.join(KANBAN_DIR, toColumn, `${task.id}.md`);
    const markdown = taskToMarkdown(task);
    await fs.writeFile(newPath, markdown, 'utf-8');

    // Delete from old location
    await fs.unlink(taskLocation.filePath);

    res.json({ success: true, task, newColumn: toColumn });
  } catch (err) {
    console.error('Error moving task:', err);
    res.status(500).json({ error: 'Failed to move task' });
  }
});

// AI Enhancement endpoint
app.post('/api/ai/enhance', async (req, res) => {
  try {
    const { taskId, prompt, conversationHistory = [] } = req.body;

    if (!process.env.ANTHROPIC_API_KEY) {
      return res.status(400).json({
        error: 'ANTHROPIC_API_KEY not set. Please set it in your environment.'
      });
    }

    // Get task details
    const taskLocation = await findTaskFile(taskId);
    let taskContext = '';
    if (taskLocation) {
      const content = await fs.readFile(taskLocation.filePath, 'utf-8');
      const task = parseMarkdownTask(content);
      taskContext = `Current Task (${task.id}):\nTitle: ${task.title}\nDescription: ${task.description}\nType: ${task.type}\nPriority: ${task.priority}\nStatus: ${taskLocation.column}\n`;

      if (task.acceptance_criteria && task.acceptance_criteria.length > 0) {
        taskContext += `\nAcceptance Criteria:\n${task.acceptance_criteria.map((c, i) => `${i + 1}. ${c}`).join('\n')}`;
      }

      if (task.notes && task.notes.length > 0) {
        taskContext += `\nNotes:\n${task.notes.join('\n')}`;
      }
    }

    // Get project context
    const projectContext = await getProjectContext();

    // Build system message
    const systemMessage = `You are an AI assistant helping with task management for the TerrainIQ Dashcam project.

Project Context:
${projectContext.projectInfo}

Requirements Summary (first 5000 chars):
${projectContext.requirements}

${taskContext}

Your role is to help refine, enhance, and discuss tasks in relation to the rest of the project. You can:
- Break down complex tasks into subtasks
- Suggest acceptance criteria
- Identify dependencies on other parts of the project
- Recommend implementation approaches
- Point out potential issues or considerations
- Help clarify requirements

Be concise and actionable in your responses.`;

    // Build messages array
    const messages = [
      ...conversationHistory,
      { role: 'user', content: prompt }
    ];

    // Call Claude API
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 2048,
      system: systemMessage,
      messages: messages
    });

    const assistantMessage = response.content[0].text;

    res.json({
      success: true,
      response: assistantMessage,
      conversationHistory: [
        ...conversationHistory,
        { role: 'user', content: prompt },
        { role: 'assistant', content: assistantMessage }
      ]
    });

  } catch (err) {
    console.error('Error with AI enhancement:', err);
    res.status(500).json({ error: err.message || 'Failed to get AI response' });
  }
});

// Get board metadata
app.get('/api/metadata', async (req, res) => {
  try {
    const metadataPath = path.join(KANBAN_DIR, 'board-metadata.json');
    const content = await fs.readFile(metadataPath, 'utf-8');
    const metadata = JSON.parse(content);
    res.json(metadata);
  } catch (err) {
    console.error('Error getting metadata:', err);
    res.status(500).json({ error: 'Failed to load metadata' });
  }
});

app.listen(PORT, () => {
  console.log(`Kanban server running on http://localhost:${PORT}`);
  console.log(`Open http://localhost:${PORT}/kanban_ui.html to view the board`);
  if (!process.env.ANTHROPIC_API_KEY) {
    console.warn('\n⚠️  ANTHROPIC_API_KEY not set. AI features will not work.');
    console.warn('Set it with: export ANTHROPIC_API_KEY=your_key_here\n');
  }
});
