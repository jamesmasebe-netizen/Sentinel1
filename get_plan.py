import json

found = ""
with open("/Users/jamesmasebe/.gemini/antigravity/brain/677bf103-9e2e-4532-a24f-a4bb77f1a614/.system_generated/logs/transcript_full.jsonl", "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        if "Comprehensive Enterprise Platform Roadmap" in line and "write_to_file" in line:
            try:
                data = json.loads(line)
                for tc in data.get("tool_calls", []):
                    if tc.get("name") in ["write_to_file", "replace_file_content", "multi_replace_file_content"]:
                        args = tc.get("args", {})
                        if "implementation_plan.md" in args.get("TargetFile", ""):
                            content = args.get("CodeContent", "")
                            if not content:
                                content = args.get("ReplacementContent", "")
                            if "Comprehensive Enterprise Platform Roadmap" in content:
                                found = content
            except:
                pass

with open("found_plan.md", "w", encoding="utf-8") as out:
    out.write(found)

