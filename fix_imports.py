import os
import glob

# Project tabs fixes
project_files = glob.glob('/Users/jamesmasebe/Desktop/Sentinel1/lib/features/projects/widgets/project_tabs/*.dart')
project_files.append('/Users/jamesmasebe/Desktop/Sentinel1/lib/features/projects/widgets/dashboard_prince2_overview.dart')

for f in project_files:
    with open(f, 'r') as file:
        content = file.read()
    content = content.replace("import '../../../models/", "import '../../models/")
    content = content.replace("import '../../../providers/", "import '../../providers/")
    content = content.replace("import '../models/", "import '../../models/")
    with open(f, 'w') as file:
        file.write(content)

# Equipment fix
eq_file = '/Users/jamesmasebe/Desktop/Sentinel1/lib/features/equipment/widgets/equipment_asset_tab.dart'
with open(eq_file, 'r') as file:
    content = file.read()
content = content.replace("import '../../../people/widgets/employee_selector.dart';", "import '../../people/widgets/employee_selector.dart';")
with open(eq_file, 'w') as file:
    file.write(content)

# Property fix
prop_file = '/Users/jamesmasebe/Desktop/Sentinel1/lib/features/property/widgets/property_assets_tab.dart'
with open(prop_file, 'r') as file:
    content = file.read()
content = content.replace("import '../../../core/models/property.dart';", "import '../../../core/models/property_models.dart';")
with open(prop_file, 'w') as file:
    file.write(content)

