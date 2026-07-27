import json

with open("/Users/jamesmasebe/.gemini/antigravity/brain/677bf103-9e2e-4532-a24f-a4bb77f1a614/.system_generated/logs/transcript.jsonl", "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        if '"type":"PLANNER_RESPONSE"' in line and '"name":"multi_replace_file_content"' in line and '"implementation_plan.md"' in line:
            try:
                data = json.loads(line)
                for tc in data.get("tool_calls", []):
                    if tc.get("name") in ["multi_replace_file_content", "replace_file_content", "write_to_file"]:
                        args = tc.get("args", {})
                        if "implementation_plan" in args.get("TargetFile", ""):
                            print(args)
            except:
                pass

