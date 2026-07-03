import os
import re

file_path = "lib/config/router.dart"

with open(file_path, "r") as f:
    content = f.read()

# Replace ` deferred as ` with ` as `
content = re.sub(r' deferred as ', ' as ', content)

# Remove `loadLibrary` arguments from `DeferredRouteExtension.deferred` calls
content = re.sub(r'\s*loadLibrary:\s*\w+\.loadLibrary,', '', content)

# Remove `loadLibrary` arguments from `DeferredLoader` calls
content = re.sub(r'\s*loadLibrary:\s*\w+\.loadLibrary,', '', content)

# Fix the signature of DeferredRouteExtension.deferred
content = re.sub(
    r'required Future<dynamic> Function\(\) loadLibrary,\s*required Widget Function\(\) builder',
    'required Widget Function() builder',
    content
)

# Fix DeferredRouteExtension.deferred implementation
content = re.sub(
    r'child: DeferredLoader\([^)]*builder: builder,\s*\)',
    'child: builder()',
    content,
    flags=re.DOTALL
)

# Fix GoRoute pageBuilders that use DeferredLoader
content = re.sub(
    r'child: DeferredLoader\([^)]*builder: \(\) => ([\w.]+\([^)]*\)),\s*\)',
    r'child: \1',
    content,
    flags=re.DOTALL
)


with open(file_path, "w") as f:
    f.write(content)

print("Deferred loading removed")
