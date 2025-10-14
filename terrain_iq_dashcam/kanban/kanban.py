#!/usr/bin/env python3
"""
Kanban Board CLI for TerrainIQ Dashcam Development
Folder-based task management system optimized for AI agent workflows
Uses Markdown files with YAML frontmatter for better readability and documentation
"""

import json
import re
import click
from datetime import datetime
from pathlib import Path
from rich.console import Console
from rich.table import Table
from rich import print as rprint

console = Console()
KANBAN_DIR = Path(__file__).parent
METADATA_FILE = KANBAN_DIR / "board-metadata.json"
COLUMNS = ['backlog', 'ready', 'in_progress', 'review', 'done']

# Helper Functions

def load_metadata():
    """Load board metadata from JSON file"""
    if not METADATA_FILE.exists():
        console.print("[red]Error: board-metadata.json not found![/red]")
        console.print("Run from the kanban directory or check installation")
        raise click.Abort()

    with open(METADATA_FILE, 'r') as f:
        return json.load(f)

def save_metadata(metadata):
    """Save board metadata to JSON file"""
    with open(METADATA_FILE, 'w') as f:
        json.dump(metadata, f, indent=2)

def parse_markdown_task(content):
    """Parse markdown file with YAML frontmatter into task dict"""
    # Split frontmatter and content
    parts = content.split('---\n', 2)
    if len(parts) < 3:
        raise ValueError("Invalid markdown format: missing frontmatter")

    frontmatter_text = parts[1]
    markdown_content = parts[2]

    # Parse frontmatter manually (simple YAML parser for our use case)
    task = {}
    for line in frontmatter_text.strip().split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip()

            # Handle different value types
            if value.lower() == 'null':
                task[key] = None
            elif value.lower() == 'true':
                task[key] = True
            elif value.lower() == 'false':
                task[key] = False
            elif value.startswith('[') and value.endswith(']'):
                # Parse list
                if value == '[]':
                    task[key] = []
                else:
                    # Remove brackets and split by comma
                    items = value[1:-1].split(',')
                    task[key] = [item.strip() for item in items if item.strip()]
            else:
                task[key] = value

    # Parse markdown content sections
    task['_markdown'] = markdown_content

    # Extract sections from markdown
    sections = parse_markdown_sections(markdown_content)

    # Map sections back to task structure
    if 'Description' in sections:
        task['description'] = sections['Description'].strip()

    if 'Use Case' in sections:
        task['use_case'] = sections['Use Case'].strip()

    if 'Acceptance Criteria' in sections:
        criteria = []
        for line in sections['Acceptance Criteria'].strip().split('\n'):
            line = line.strip()
            if line.startswith('- ['):
                # Extract checkbox text
                criteria.append(line[6:].strip())
        task['acceptance_criteria'] = criteria

    if 'Notes' in sections:
        notes = []
        for line in sections['Notes'].strip().split('\n'):
            line = line.strip()
            if line.startswith('- ') or line.startswith('* '):
                notes.append(line[2:].strip())
        task['notes'] = notes

    # Ensure test_data structure exists
    if 'test_data' not in task:
        task['test_data'] = {'good_samples': [], 'bad_samples': []}

    return task

def parse_markdown_sections(markdown):
    """Parse markdown into sections based on ## headers"""
    sections = {}
    current_section = None
    current_content = []

    for line in markdown.split('\n'):
        if line.startswith('## '):
            if current_section:
                sections[current_section] = '\n'.join(current_content)
            current_section = line[3:].strip()
            current_content = []
        elif current_section:
            current_content.append(line)

    if current_section:
        sections[current_section] = '\n'.join(current_content)

    return sections

def task_to_markdown(task):
    """Convert task dict to markdown with YAML frontmatter"""
    # Build frontmatter
    frontmatter_lines = []

    # Required fields
    frontmatter_lines.append(f"id: {task['id']}")
    frontmatter_lines.append(f"title: {task['title']}")
    frontmatter_lines.append(f"type: {task.get('type', 'feature')}")
    frontmatter_lines.append(f"priority: {task.get('priority', 'medium')}")
    frontmatter_lines.append(f"assignee: {task.get('assignee', 'unassigned')}")
    frontmatter_lines.append(f"validation_status: {task.get('validation_status', 'pending')}")
    frontmatter_lines.append(f"created_at: {task.get('created_at', '')}")
    frontmatter_lines.append(f"updated_at: {task.get('updated_at', '')}")
    frontmatter_lines.append(f"completed_at: {task.get('completed_at', 'null')}")

    # Tags
    tags = task.get('tags', [])
    if tags:
        tags_str = ', '.join(tags)
        frontmatter_lines.append(f"tags: [{tags_str}]")
    else:
        frontmatter_lines.append("tags: []")

    frontmatter = '\n'.join(frontmatter_lines)

    # Build markdown content
    content_lines = []
    content_lines.append(f"# {task['title']}")
    content_lines.append("")
    content_lines.append("## Description")
    content_lines.append("")
    content_lines.append(task.get('description', 'No description provided'))
    content_lines.append("")

    # Use Case
    content_lines.append("## Use Case")
    content_lines.append("")
    content_lines.append(task.get('use_case', '_No use case specified_'))
    content_lines.append("")

    # Acceptance Criteria
    content_lines.append("## Acceptance Criteria")
    content_lines.append("")
    criteria = task.get('acceptance_criteria', [])
    if criteria:
        for criterion in criteria:
            # Preserve checkbox state if present
            if criterion.strip():
                content_lines.append(f"- [ ] {criterion}")
    else:
        content_lines.append("_No criteria specified yet_")
    content_lines.append("")

    # Test Data
    content_lines.append("## Test Data")
    content_lines.append("")
    content_lines.append("### Good Samples")
    good_samples = task.get('test_data', {}).get('good_samples', [])
    if good_samples:
        for sample in good_samples:
            content_lines.append(f"- {sample}")
    else:
        content_lines.append("_No good samples defined_")
    content_lines.append("")
    content_lines.append("### Bad Samples")
    bad_samples = task.get('test_data', {}).get('bad_samples', [])
    if bad_samples:
        for sample in bad_samples:
            content_lines.append(f"- {sample}")
    else:
        content_lines.append("_No bad samples defined_")
    content_lines.append("")

    # Notes
    content_lines.append("## Notes")
    content_lines.append("")
    notes = task.get('notes', [])
    if notes:
        for note in notes:
            content_lines.append(f"- {note}")
    else:
        content_lines.append("_No notes yet_")

    markdown_content = '\n'.join(content_lines)

    # Combine frontmatter and content
    return f"---\n{frontmatter}\n---\n\n{markdown_content}\n"

def load_task(task_file):
    """Load a task from Markdown file"""
    with open(task_file, 'r') as f:
        content = f.read()
    return parse_markdown_task(content)

def save_task(task, column):
    """Save task to column folder as Markdown"""
    task_file = KANBAN_DIR / column / f"{task['id']}.md"
    markdown = task_to_markdown(task)
    with open(task_file, 'w') as f:
        f.write(markdown)

def get_all_tasks():
    """Get all tasks organized by column"""
    tasks = {}
    for column in COLUMNS:
        column_path = KANBAN_DIR / column
        tasks[column] = []

        if column_path.exists():
            for task_file in sorted(column_path.glob('TASK-*.md')):
                try:
                    task = load_task(task_file)
                    tasks[column].append(task)
                except Exception as e:
                    console.print(f"[yellow]Warning: Could not load {task_file.name}: {e}[/yellow]")

    return tasks

def find_task(task_id):
    """Find task and return (task, column)"""
    for column in COLUMNS:
        task_file = KANBAN_DIR / column / f"{task_id}.md"
        if task_file.exists():
            return load_task(task_file), column
    return None, None

def generate_task_id():
    """Generate next task ID"""
    metadata = load_metadata()
    task_num = metadata['next_task_number']
    task_id = f"TASK-{task_num:03d}"
    metadata['next_task_number'] = task_num + 1
    save_metadata(metadata)
    return task_id

def get_color_for_priority(priority):
    """Get color code for priority"""
    colors = {
        'low': 'green',
        'medium': 'yellow',
        'high': 'orange1',
        'critical': 'red'
    }
    return colors.get(priority, 'white')

def get_color_for_type(task_type):
    """Get color code for task type"""
    colors = {
        'feature': 'cyan',
        'bug': 'red',
        'test': 'green',
        'docs': 'blue',
        'refactor': 'magenta'
    }
    return colors.get(task_type, 'white')

# CLI Commands

@click.group()
def cli():
    """Kanban board management for TerrainIQ Dashcam Development"""
    pass

@cli.command()
@click.option('--column', type=click.Choice(COLUMNS), help='Show specific column only')
def show(column):
    """Display the kanban board"""
    metadata = load_metadata()
    tasks = get_all_tasks()

    columns_to_show = [column] if column else COLUMNS

    for col in columns_to_show:
        col_meta = metadata['columns'][col]
        table = Table(title=f"\n{col_meta['name']} ({len(tasks[col])} tasks)",
                     title_style="bold cyan")

        table.add_column("ID", style="cyan", width=10)
        table.add_column("Title", style="white", width=40)
        table.add_column("Type", width=10)
        table.add_column("Priority", width=10)
        table.add_column("Assignee", width=12)

        for task in tasks[col]:
            type_color = get_color_for_type(task.get('type', 'feature'))
            priority_color = get_color_for_priority(task.get('priority', 'medium'))
            assignee_style = "green" if task.get('assignee') == 'agent' else "blue" if task.get('assignee') == 'human' else "dim"

            table.add_row(
                f"[cyan]{task['id']}[/cyan]",
                task['title'][:38] + "..." if len(task['title']) > 40 else task['title'],
                f"[{type_color}]{task.get('type', 'feature')}[/{type_color}]",
                f"[{priority_color}]{task.get('priority', 'medium')}[/{priority_color}]",
                f"[{assignee_style}]{task.get('assignee', 'unassigned')}[/{assignee_style}]"
            )

        if tasks[col]:
            console.print(table)
        else:
            console.print(f"\n[dim]{col_meta['name']}: No tasks[/dim]")

@cli.command()
@click.option('--title', prompt='Task title', help='Task title')
@click.option('--description', prompt='Description', help='Detailed description')
@click.option('--type', type=click.Choice(['feature', 'bug', 'test', 'docs', 'refactor']),
              prompt='Type', help='Task type')
@click.option('--priority', type=click.Choice(['low', 'medium', 'high', 'critical']),
              prompt='Priority', help='Task priority')
@click.option('--assignee', type=click.Choice(['agent', 'human', 'unassigned']),
              default='unassigned', help='Task assignee')
@click.option('--use-case', default='', help='Related use case ID')
def add(title, description, type, priority, assignee, use_case):
    """Add new task to backlog"""
    task_id = generate_task_id()
    now = datetime.now().isoformat()

    task = {
        "id": task_id,
        "title": title,
        "description": description,
        "type": type,
        "priority": priority,
        "assignee": assignee,
        "use_case": use_case,
        "test_data": {
            "good_samples": [],
            "bad_samples": []
        },
        "acceptance_criteria": [],
        "validation_status": "pending",
        "created_at": now,
        "updated_at": now,
        "completed_at": None,
        "tags": [],
        "notes": []
    }

    save_task(task, 'backlog')
    console.print(f"[green]✓[/green] Created task [cyan]{task_id}[/cyan]: {title}")
    console.print(f"[dim]Task added to backlog[/dim]")

@cli.command()
@click.argument('task_id')
@click.argument('column', type=click.Choice(COLUMNS))
def move(task_id, column):
    """Move task to a different column"""
    task, current_column = find_task(task_id)

    if not task:
        console.print(f"[red]Error: Task {task_id} not found[/red]")
        return

    if current_column == column:
        console.print(f"[yellow]Task {task_id} is already in {column}[/yellow]")
        return

    # Update task metadata
    task['updated_at'] = datetime.now().isoformat()

    # Mark as completed if moving to done
    if column == 'done':
        task['completed_at'] = datetime.now().isoformat()
        task['validation_status'] = 'passed'

    # Remove from old location
    old_file = KANBAN_DIR / current_column / f"{task_id}.md"
    old_file.unlink()

    # Save to new location
    save_task(task, column)

    console.print(f"[green]✓[/green] Moved [cyan]{task_id}[/cyan] from [yellow]{current_column}[/yellow] to [green]{column}[/green]")

@cli.command()
@click.argument('task_id')
@click.argument('assignee', type=click.Choice(['agent', 'human', 'unassigned']))
def assign(task_id, assignee):
    """Assign task to agent or human"""
    task, column = find_task(task_id)

    if not task:
        console.print(f"[red]Error: Task {task_id} not found[/red]")
        return

    task['assignee'] = assignee
    task['updated_at'] = datetime.now().isoformat()

    save_task(task, column)

    assignee_color = "green" if assignee == 'agent' else "blue" if assignee == 'human' else "dim"
    console.print(f"[green]✓[/green] Assigned [cyan]{task_id}[/cyan] to [{assignee_color}]{assignee}[/{assignee_color}]")

@cli.command()
@click.argument('task_id')
def details(task_id):
    """Show detailed task information"""
    task, column = find_task(task_id)

    if not task:
        console.print(f"[red]Error: Task {task_id} not found[/red]")
        return

    metadata = load_metadata()
    col_name = metadata['columns'][column]['name']

    console.print()
    console.print(f"[bold cyan]{'='*70}[/bold cyan]")
    console.print(f"[bold]Task Details: {task['id']}[/bold]")
    console.print(f"[bold cyan]{'='*70}[/bold cyan]")
    console.print()

    console.print(f"[bold]Title:[/bold] {task['title']}")
    console.print(f"[bold]Description:[/bold] {task['description']}")
    console.print()

    type_color = get_color_for_type(task.get('type', 'feature'))
    priority_color = get_color_for_priority(task.get('priority', 'medium'))

    console.print(f"[bold]Type:[/bold] [{type_color}]{task.get('type', 'feature')}[/{type_color}]")
    console.print(f"[bold]Priority:[/bold] [{priority_color}]{task.get('priority', 'medium')}[/{priority_color}]")
    console.print(f"[bold]Assignee:[/bold] {task.get('assignee', 'unassigned')}")
    console.print(f"[bold]Status:[/bold] [yellow]{col_name}[/yellow]")
    console.print()

    console.print(f"[bold]Created:[/bold] {task.get('created_at', 'N/A')}")
    console.print(f"[bold]Updated:[/bold] {task.get('updated_at', 'N/A')}")
    if task.get('completed_at') and task.get('completed_at') != 'null':
        console.print(f"[bold]Completed:[/bold] [green]{task['completed_at']}[/green]")
    console.print()

    if task.get('use_case'):
        console.print(f"[bold]Use Case:[/bold] {task['use_case']}")
        console.print()

    if task.get('acceptance_criteria'):
        console.print("[bold]Acceptance Criteria:[/bold]")
        for i, criterion in enumerate(task['acceptance_criteria'], 1):
            console.print(f"  {i}. {criterion}")
        console.print()

    if task.get('tags'):
        tags = task['tags']
        if isinstance(tags, list):
            console.print(f"[bold]Tags:[/bold] {', '.join(tags)}")
        else:
            console.print(f"[bold]Tags:[/bold] {tags}")
        console.print()

    if task.get('notes'):
        console.print("[bold]Notes:[/bold]")
        for note in task['notes']:
            console.print(f"  • {note}")
        console.print()

    console.print(f"[bold]Validation Status:[/bold] {task.get('validation_status', 'pending')}")
    console.print()

@cli.command()
def stats():
    """Show board statistics"""
    tasks = get_all_tasks()
    metadata = load_metadata()

    # Overall stats table
    table = Table(title="\nKanban Board Statistics", title_style="bold cyan")
    table.add_column("Column", style="cyan", width=15)
    table.add_column("Count", justify="right", width=10)
    table.add_column("Agent", justify="right", width=10)
    table.add_column("Human", justify="right", width=10)
    table.add_column("Unassigned", justify="right", width=12)

    total_tasks = 0
    total_agent = 0
    total_human = 0
    total_unassigned = 0

    for col in COLUMNS:
        col_meta = metadata['columns'][col]
        col_tasks = tasks[col]
        count = len(col_tasks)
        total_tasks += count

        agent_count = sum(1 for t in col_tasks if t.get('assignee') == 'agent')
        human_count = sum(1 for t in col_tasks if t.get('assignee') == 'human')
        unassigned_count = sum(1 for t in col_tasks if t.get('assignee', 'unassigned') == 'unassigned')

        total_agent += agent_count
        total_human += human_count
        total_unassigned += unassigned_count

        table.add_row(
            col_meta['name'],
            str(count),
            f"[green]{agent_count}[/green]" if agent_count else "[dim]0[/dim]",
            f"[blue]{human_count}[/blue]" if human_count else "[dim]0[/dim]",
            f"[yellow]{unassigned_count}[/yellow]" if unassigned_count else "[dim]0[/dim]"
        )

    table.add_row(
        "[bold]TOTAL[/bold]",
        f"[bold]{total_tasks}[/bold]",
        f"[bold green]{total_agent}[/bold green]",
        f"[bold blue]{total_human}[/bold blue]",
        f"[bold yellow]{total_unassigned}[/bold yellow]"
    )

    console.print(table)

    # Priority breakdown
    priority_table = Table(title="\nPriority Breakdown", title_style="bold cyan")
    priority_table.add_column("Priority", style="cyan")
    priority_table.add_column("Count", justify="right")

    all_tasks = []
    for col_tasks in tasks.values():
        all_tasks.extend(col_tasks)

    for priority in ['critical', 'high', 'medium', 'low']:
        count = sum(1 for t in all_tasks if t.get('priority') == priority)
        color = get_color_for_priority(priority)
        priority_table.add_row(
            f"[{color}]{priority.capitalize()}[/{color}]",
            f"[{color}]{count}[/{color}]" if count else "[dim]0[/dim]"
        )

    console.print(priority_table)
    console.print()

@cli.command()
@click.argument('task_id')
@click.option('--title', help='Update title')
@click.option('--description', help='Update description')
@click.option('--priority', type=click.Choice(['low', 'medium', 'high', 'critical']), help='Update priority')
@click.option('--type', type=click.Choice(['feature', 'bug', 'test', 'docs', 'refactor']), help='Update type')
@click.option('--add-note', help='Add a note')
@click.option('--add-tag', help='Add a tag')
def update(task_id, title, description, priority, type, add_note, add_tag):
    """Update task properties"""
    task, column = find_task(task_id)

    if not task:
        console.print(f"[red]Error: Task {task_id} not found[/red]")
        return

    updated = False

    if title:
        task['title'] = title
        updated = True
        console.print(f"[green]✓[/green] Updated title")

    if description:
        task['description'] = description
        updated = True
        console.print(f"[green]✓[/green] Updated description")

    if priority:
        task['priority'] = priority
        updated = True
        console.print(f"[green]✓[/green] Updated priority to {priority}")

    if type:
        task['type'] = type
        updated = True
        console.print(f"[green]✓[/green] Updated type to {type}")

    if add_note:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
        note_with_time = f"[{timestamp}] {add_note}"
        if 'notes' not in task:
            task['notes'] = []
        task['notes'].append(note_with_time)
        updated = True
        console.print(f"[green]✓[/green] Added note")

    if add_tag:
        tags = task.get('tags', [])
        if isinstance(tags, str):
            tags = [t.strip() for t in tags.split(',') if t.strip()]
        if add_tag not in tags:
            tags.append(add_tag)
            task['tags'] = tags
            updated = True
            console.print(f"[green]✓[/green] Added tag: {add_tag}")
        else:
            console.print(f"[yellow]Tag '{add_tag}' already exists[/yellow]")

    if updated:
        task['updated_at'] = datetime.now().isoformat()
        save_task(task, column)
        console.print(f"[green]✓[/green] Task [cyan]{task_id}[/cyan] updated")
    else:
        console.print("[yellow]No updates specified[/yellow]")

@cli.command()
@click.argument('task_id')
@click.confirmation_option(prompt='Are you sure you want to delete this task?')
def delete(task_id):
    """Delete task permanently"""
    task, column = find_task(task_id)

    if not task:
        console.print(f"[red]Error: Task {task_id} not found[/red]")
        return

    task_file = KANBAN_DIR / column / f"{task_id}.md"
    task_file.unlink()

    console.print(f"[green]✓[/green] Deleted task [cyan]{task_id}[/cyan]")

@cli.command()
def list_files():
    """List all task files (debugging)"""
    console.print("\n[bold]Task Files by Column:[/bold]\n")

    for column in COLUMNS:
        column_path = KANBAN_DIR / column
        if column_path.exists():
            task_files = list(column_path.glob('TASK-*.md'))
            console.print(f"[cyan]{column}[/cyan]: {len(task_files)} files")
            for task_file in sorted(task_files):
                console.print(f"  • {task_file.name}")
        else:
            console.print(f"[dim]{column}: directory not found[/dim]")

    console.print()

if __name__ == '__main__':
    cli()
