import json

found = []
with open("/Users/jamesmasebe/.gemini/antigravity/brain/677bf103-9e2e-4532-a24f-a4bb77f1a614/.system_generated/logs/transcript_full.jsonl", "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        if "implementation_plan.md" in line:
            try:
                data = json.loads(line)
                for tc in data.get("tool_calls", []):
                    if tc.get("name") == "write_to_file":
                        args = tc.get("args", {})
                        if "implementation_plan.md" in args.get("TargetFile", ""):
                            content = args.get("CodeContent", "")
                            found.append(content)
            except:
                pass

if found:
    with open("found_plan2.md", "w", encoding="utf-8") as out:
        out.write(found[-2] if len(found) > 1 else found[0]) # Get the second to last one, since the last one was Phase 2.8 specifically
