import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Skip files that should not be refactored
    ignored_files = [
        'tenant_firestore_extension.dart',
        'firestore_service.dart',
        'offline_sync_service.dart',
        'app_providers.dart',
        'user_profile.dart'
    ]
    if os.path.basename(filepath) in ignored_files:
        return

    # Replace .collection(...) with .tenantCollection(tenantId, ...)
    # The tenantId is retrieved inline using ref.watch
    new_content = re.sub(
        r'\.collection\(([^)]+)\)',
        r'.tenantCollection(ref.watch(currentTenantIdProvider) ?? "", \1)',
        content
    )

    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated: {filepath}")

def main():
    # Set the lib directory path relative to this script
    lib_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lib')
    
    print(f"Scanning {lib_dir} for .collection() calls...")
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))
                
    print("Refactoring complete.")

if __name__ == '__main__':
    main()
