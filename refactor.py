import os
import re

def extract_from_file(source_path, dest_path, classes_to_remove, methods_to_remove, new_file_imports, rename_map, new_file_code_extra="", add_import=""):
    with open(source_path, 'r') as f:
        content = f.read()

    def get_balanced_brace_content(start_idx):
        idx = start_idx
        brace_count = 0
        in_string = False
        string_char = ''
        found_first_brace = False
        
        while idx < len(content):
            char = content[idx]
            
            if in_string:
                if char == string_char and content[idx-1] != '\\':
                    in_string = False
            else:
                if char in ("'", '"'):
                    in_string = True
                    string_char = char
                elif char == '{':
                    brace_count += 1
                    found_first_brace = True
                elif char == '}':
                    brace_count -= 1
            
            idx += 1
            if found_first_brace and brace_count == 0:
                return content[start_idx:idx]
                
        return None

    extracted_parts = []

    # Extract classes
    for cls in classes_to_remove:
        pattern = re.compile(rf'^(class {cls}\b.*)$', re.MULTILINE)
        match = pattern.search(content)
        if match:
            start_idx = match.start()
            class_content = get_balanced_brace_content(start_idx)
            if class_content:
                extracted_parts.append(class_content)
                content = content.replace(class_content, '')

    # Extract methods
    for method in methods_to_remove:
        # e.g., "Widget _buildForm("
        pattern = re.compile(rf'^([ \t]*Widget {method}\(.*)$', re.MULTILINE)
        match = pattern.search(content)
        if match:
            start_idx = match.start()
            if '=>' in content[start_idx:content.find(';', start_idx)]:
                method_content = content[start_idx:content.find(';', start_idx)+1]
            else:
                method_content = get_balanced_brace_content(start_idx)
            if method_content:
                extracted_parts.append(method_content)
                content = content.replace(method_content, '')

    # Apply renames
    for old, new in rename_map.items():
        content = content.replace(old, new)
        extracted_parts = [part.replace(old, new) for part in extracted_parts]
        new_file_code_extra = new_file_code_extra.replace(old, new)

    # Create destination file
    if extracted_parts or new_file_code_extra:
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        final_dest_content = new_file_imports + "\n\n" + "\n\n".join(extracted_parts) + "\n\n" + new_file_code_extra
        with open(dest_path, 'w') as f:
            f.write(final_dest_content)
            
    # Add import to source file
    if add_import:
        import_end_match = list(re.finditer(r'^import .*;$', content, re.MULTILINE))
        if import_end_match:
            last_import_idx = import_end_match[-1].end()
        else:
            last_import_idx = 0
            
        content = content[:last_import_idx] + "\n" + add_import + content[last_import_idx:]
        
    # Write back
    with open(source_path, 'w') as f:
        f.write(content)
    
    print(f"Processed {source_path}")

tasks = [
    {
        'source_path': 'lib/features/people/screens/payroll_dashboard_screen.dart',
        'dest_path': 'lib/features/people/widgets/manual_payslip_form.dart',
        'classes_to_remove': ['_ManualPayslipForm', '_ManualPayslipFormState'],
        'methods_to_remove': [],
        'rename_map': {'_ManualPayslipForm': 'ManualPayslipForm', '_ManualPayslipFormState': 'ManualPayslipFormState'},
        'new_file_imports': "import 'package:flutter/material.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../../core/providers/app_providers.dart';\nimport '../../../core/utils/ui_utils.dart';\nimport '../models/hr_models.dart';\nimport '../providers/employee_providers.dart';\nimport 'employee_selector.dart';",
        'add_import': "import '../widgets/manual_payslip_form.dart';"
    },
    {
        'source_path': 'lib/features/people/screens/public_careers_portal.dart',
        'dest_path': 'lib/features/people/widgets/application_form_widget.dart',
        'classes_to_remove': ['_ApplicationFormWidget', '_ApplicationFormWidgetState'],
        'methods_to_remove': [],
        'rename_map': {'_ApplicationFormWidget': 'ApplicationFormWidget', '_ApplicationFormWidgetState': 'ApplicationFormWidgetState'},
        'new_file_imports': "import 'package:flutter/material.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../../../core/providers/app_providers.dart';\nimport '../models/hr_models.dart';",
        'add_import': "import '../widgets/application_form_widget.dart';"
    },
    {
        'source_path': 'lib/features/public/screens/public_careers_screen.dart',
        'dest_path': 'lib/features/public/widgets/job_application_form.dart',
        'classes_to_remove': ['JobApplicationForm', '_JobApplicationFormState'],
        'methods_to_remove': [],
        'rename_map': {},
        'new_file_imports': "import 'package:flutter/material.dart';\nimport 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../../core/utils/ui_utils.dart';",
        'add_import': "import '../widgets/job_application_form.dart';"
    },
    {
        'source_path': 'lib/features/people/screens/leave_management_screen.dart',
        'dest_path': 'lib/features/people/widgets/leave_application_form.dart',
        'classes_to_remove': ['LeaveApplicationForm', '_LeaveApplicationFormState'],
        'methods_to_remove': [],
        'rename_map': {},
        'new_file_imports': "import 'package:flutter/material.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../../../core/utils/ui_utils.dart';\nimport '../../../core/providers/app_providers.dart';\nimport '../models/hr_models.dart';\nimport 'employee_selector.dart';",
        'add_import': "import '../widgets/leave_application_form.dart';"
    },
    {
        'source_path': 'lib/features/training/screens/manager_training_dashboard.dart',
        'dest_path': 'lib/features/training/widgets/allocate_course_form.dart',
        'classes_to_remove': ['_AllocateCourseForm', '_AllocateCourseFormState'],
        'methods_to_remove': [],
        'rename_map': {'_AllocateCourseForm': 'AllocateCourseForm', '_AllocateCourseFormState': 'AllocateCourseFormState'},
        'new_file_imports': "import 'package:flutter/material.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:intl/intl.dart';\nimport '../../../core/providers/app_providers.dart';\nimport '../../../core/utils/ui_utils.dart';\nimport '../../people/widgets/employee_selector.dart';",
        'add_import': "import '../widgets/allocate_course_form.dart';"
    },
    {
        'source_path': 'lib/features/people/screens/employee_360_profile_screen.dart',
        'dest_path': 'lib/features/people/widgets/detail_row.dart',
        'classes_to_remove': ['_DetailRow'],
        'methods_to_remove': [],
        'rename_map': {'_DetailRow': 'DetailRow'},
        'new_file_imports': "import 'package:flutter/material.dart';\nimport '../../../config/theme.dart';",
        'add_import': "import '../widgets/detail_row.dart';"
    }
]

for t in tasks:
    extract_from_file(**t)
