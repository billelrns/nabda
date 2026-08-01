import json
import os

def restore():
    transcript_path = r"C:\Users\sur\.gemini\antigravity-ide\brain\d80fa7a9-4cd9-4a9d-87e7-db74c6a8c107\.system_generated\logs\transcript_full.jsonl"
    if not os.path.exists(transcript_path):
        transcript_path = r"C:\Users\sur\.gemini\antigravity-ide\brain\d80fa7a9-4cd9-4a9d-87e7-db74c6a8c107\.system_generated\logs\transcript.jsonl"
        
    print(f"Reading logs from: {transcript_path}")
    
    # We want to find the latest write_to_file or replace_file_content tool call targeting doctors_list_screen.dart
    target_content = None
    
    with open(transcript_path, "r", encoding="utf-8") as f:
        for line in f:
            try:
                step = json.loads(line)
                # Check tool calls
                tool_calls = step.get("tool_calls", [])
                for call in tool_calls:
                    name = call.get("name")
                    args = call.get("args", {})
                    # If it's write_to_file and targets doctors_list_screen.dart
                    if name == "write_to_file" and "doctors_list_screen.dart" in args.get("TargetFile", ""):
                        content = args.get("CodeContent")
                        if content:
                            target_content = content
                            print(f"Found code content in step {step.get('step_index')} (write_to_file)")
                            
                    # If it's replace_file_content and has a replacement chunk that contains the whole file or most of it
                    elif name == "replace_file_content" and "doctors_list_screen.dart" in args.get("TargetFile", ""):
                        # Sometimes the model replaced a big chunk
                        print(f"Found replace_file_content in step {step.get('step_index')}")
                        
            except Exception as e:
                pass
                
    if target_content:
        dest_path = r"lib\screens\doctors\doctors_list_screen.dart"
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        with open(dest_path, "w", encoding="utf-8") as out:
            out.write(target_content)
        print(f"Successfully restored doctors_list_screen.dart to {dest_path}!")
    else:
        print("Could not find code content in logs.")

if __name__ == "__main__":
    restore()
