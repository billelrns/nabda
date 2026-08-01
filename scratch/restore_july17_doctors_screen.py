import json
import os

def restore_latest_version():
    transcript_path = r"C:\Users\sur\.gemini\antigravity-ide\brain\d80fa7a9-4cd9-4a9d-87e7-db74c6a8c107\.system_generated\logs\transcript_full.jsonl"
    if not os.path.exists(transcript_path):
        print("Transcript log not found!")
        return

    print("Analyzing logs to reconstruct the latest state of doctors_list_screen.dart...")
    
    # We will reconstruct the file state by starting with the base file written in step 310,
    # and then applying all successful replace_file_content changes to it sequentially!
    file_content = None
    
    # Step 310 was the last full write of doctors_list_screen.dart before the July 17 edits
    with open(transcript_path, "r", encoding="utf-8") as f:
        for line in f:
            try:
                step = json.loads(line)
                step_idx = step.get("step_index")
                
                # We only want to reconstruct using actions up to step 870 (end of July 17th work)
                if step_idx > 870:
                    continue
                    
                tool_calls = step.get("tool_calls", [])
                for call in tool_calls:
                    name = call.get("name")
                    args = call.get("args", {})
                    
                    if "doctors_list_screen.dart" not in args.get("TargetFile", ""):
                        continue
                        
                    if name == "write_to_file":
                        content = args.get("CodeContent")
                        if content:
                            file_content = content
                            print(f"[{step_idx}] Reset base file content")
                            
                    elif name == "replace_file_content" and file_content is not None:
                        target = args.get("TargetContent")
                        replacement = args.get("ReplacementContent")
                        
                        if target in file_content:
                            # Apply replacement
                            file_content = file_content.replace(target, replacement, 1)
                            print(f"[{step_idx}] Applied replace_file_content successfully")
                        else:
                            print(f"[{step_idx}] WARNING: Target content not found in file content!")
                            
            except Exception as e:
                print(f"Error parsing line: {e}")
                
    if file_content:
        dest_path = r"lib\screens\doctors\doctors_list_screen.dart"
        with open(dest_path, "w", encoding="utf-8") as out:
            out.write(file_content)
        print(f"Successfully reconstructed and wrote doctors_list_screen.dart!")
    else:
        print("Failed to reconstruct file.")

if __name__ == "__main__":
    restore_latest_version()
