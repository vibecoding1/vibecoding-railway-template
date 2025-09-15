#!/usr/bin/env python3
"""
Claude Context Manager for VibeCoding
Handles MCP communication and GitHub-based context management
"""

import json
import os
import subprocess
import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse
import threading
import time

class ClaudeContextManager:
    def __init__(self, project_path="/app/project"):
        self.project_path = project_path
        self.claude_folder = os.path.join(project_path, ".claude")
        
    def load_project_context(self):
        """Load comprehensive project context from .claude folder"""
        context = {
            "project_understanding": {},
            "instructions": "",
            "architecture": "",
            "todos": "",
            "recent_updates": []
        }
        
        try:
            # Load main context
            context_file = os.path.join(self.claude_folder, "context.md")
            if os.path.exists(context_file):
                with open(context_file, 'r') as f:
                    context["project_understanding"] = f.read()
            
            # Load instructions
            instructions_file = os.path.join(self.claude_folder, "instructions.md")
            if os.path.exists(instructions_file):
                with open(instructions_file, 'r') as f:
                    context["instructions"] = f.read()
            
            # Load architecture
            arch_file = os.path.join(self.claude_folder, "architecture.md")
            if os.path.exists(arch_file):
                with open(arch_file, 'r') as f:
                    context["architecture"] = f.read()
            
            # Load todos
            todos_file = os.path.join(self.claude_folder, "todos.md")
            if os.path.exists(todos_file):
                with open(todos_file, 'r') as f:
                    context["todos"] = f.read()
            
            # Load recent daily updates
            daily_updates_dir = os.path.join(self.claude_folder, "daily-updates")
            if os.path.exists(daily_updates_dir):
                updates = []
                for file in sorted(os.listdir(daily_updates_dir), reverse=True)[:3]:
                    if file.endswith('.md'):
                        with open(os.path.join(daily_updates_dir, file), 'r') as f:
                            updates.append({"date": file[:-3], "content": f.read()})
                context["recent_updates"] = updates
                        
        except Exception as e:
            print(f"⚠️  Error loading context: {e}")
            
        return context
    
    def update_project_context(self, changes_made, files_modified):
        """Update project context after successful development session"""
        today = datetime.date.today().isoformat()
        
        try:
            # Update daily log
            daily_updates_dir = os.path.join(self.claude_folder, "daily-updates")
            os.makedirs(daily_updates_dir, exist_ok=True)
            
            daily_log = f"""# Development Session - {today}

## Changes Made
{chr(10).join(f"- {change}" for change in changes_made)}

## Files Modified
{", ".join(files_modified)}

## Session Summary
Successful development session completed at {datetime.datetime.now().isoformat()}

## Next Session Goals
- Continue based on user feedback
- Implement any requested improvements
- Maintain code quality and best practices
"""
            
            daily_file = os.path.join(daily_updates_dir, f"{today}.md")
            with open(daily_file, 'w') as f:
                f.write(daily_log)
            
            # Update latest.md symlink
            latest_file = os.path.join(daily_updates_dir, "latest.md")
            if os.path.exists(latest_file):
                os.remove(latest_file)
            os.symlink(f"{today}.md", latest_file)
            
            # Update main context.md with timestamp
            context_file = os.path.join(self.claude_folder, "context.md")
            if os.path.exists(context_file):
                with open(context_file, 'r') as f:
                    content = f.read()
                
                # Update the "Last Updated" line
                lines = content.split('\n')
                for i, line in enumerate(lines):
                    if line.startswith('**Last Updated**:'):
                        lines[i] = f"**Last Updated**: {datetime.datetime.now().isoformat()}"
                        break
                
                with open(context_file, 'w') as f:
                    f.write('\n'.join(lines))
            
            # Commit changes to git
            self.commit_context_changes(f"Claude: Updated project context - {today}")
            
            print(f"✅ Updated project context for {today}")
            
        except Exception as e:
            print(f"⚠️  Error updating context: {e}")
    
    def commit_context_changes(self, commit_message):
        """Commit context changes to git"""
        try:
            os.chdir(self.project_path)
            subprocess.run(["git", "add", ".claude/"], check=True)
            subprocess.run(["git", "commit", "-m", commit_message], check=True)
            print(f"✅ Committed: {commit_message}")
        except subprocess.CalledProcessError as e:
            print(f"⚠️  Git commit failed: {e}")
    
    def execute_command(self, command, cwd=None):
        """Execute shell command and return result"""
        try:
            if cwd is None:
                cwd = self.project_path
            
            result = subprocess.run(
                command,
                shell=True,
                cwd=cwd,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
            
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "return_code": result.returncode
            }
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "stdout": "",
                "stderr": "Command timed out after 5 minutes",
                "return_code": -1
            }
        except Exception as e:
            return {
                "success": False,
                "stdout": "",
                "stderr": str(e),
                "return_code": -1
            }

class MCPRequestHandler(BaseHTTPRequestHandler):
    def __init__(self, context_manager, *args, **kwargs):
        self.context_manager = context_manager
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """Handle GET requests - health check and context loading"""
        if self.path == "/health":
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "healthy", "service": "claude-context-manager"}).encode())
        
        elif self.path == "/context":
            context = self.context_manager.load_project_context()
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(context).encode())
        
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        """Handle POST requests - command execution and context updates"""
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data.decode('utf-8'))
            
            if self.path == "/execute":
                # Execute command
                command = data.get("command", "")
                result = self.context_manager.execute_command(command)
                
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(result).encode())
            
            elif self.path == "/update-context":
                # Update project context
                changes = data.get("changes_made", [])
                files = data.get("files_modified", [])
                self.context_manager.update_project_context(changes, files)
                
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"success": True}).encode())
            
            else:
                self.send_response(404)
                self.end_headers()
                
        except json.JSONDecodeError:
            self.send_response(400)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": "Invalid JSON"}).encode())
        
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())

def create_handler(context_manager):
    def handler(*args, **kwargs):
        return MCPRequestHandler(context_manager, *args, **kwargs)
    return handler

def main():
    print("🤖 Starting Claude Context Manager...")
    
    # Initialize context manager
    context_manager = ClaudeContextManager()
    
    # Create HTTP server
    server = HTTPServer(('0.0.0.0', 8080), create_handler(context_manager))
    
    print("✅ Claude Context Manager ready on port 8080")
    print("📡 Endpoints:")
    print("   GET  /health - Health check")
    print("   GET  /context - Load project context")
    print("   POST /execute - Execute commands")
    print("   POST /update-context - Update project context")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Shutting down Claude Context Manager...")
        server.shutdown()

if __name__ == "__main__":
    main() 