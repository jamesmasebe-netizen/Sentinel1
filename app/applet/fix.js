const fs = require('fs');
const files = [
  'src/pages/BehavioralSafety.tsx',
  'src/pages/EnterpriseRiskESG.tsx',
  'src/pages/ExecutiveBentoDashboard.tsx',
  'src/pages/PermitToWork.tsx',
  'src/components/Layout.tsx'
];

files.forEach(file => {
  if (!fs.existsSync(file)) return;
  let content = fs.readFileSync(file, 'utf8');

  // Fix duplicate sx from previous blind replace
  content = content.replace(/sx=\{\{\s*(.*?)\s*\}\}\s*sx=\{\{\s*(.*?)\s*\}\}/g, 'sx={{ $1, $2 }}');
  
  // Fix fontWeight={123} 
  content = content.replace(/<Typography([^>]*?)\sfontWeight=\{([0-9]+)\}([^>]*?)>/g, (match, p1, p2, p3) => {
    // if p1 or p3 contains sx={{}}, we can merge them
    return `<Typography${p1}${p3} sx={{ fontWeight: ${p2} }}>`;
  });
  content = content.replace(/<Typography([^>]*?)\sfontWeight=\"([0-9]+)\"([^>]*?)>/g, (match, p1, p2, p3) => {
    return `<Typography${p1}${p3} sx={{ fontWeight: ${p2} }}>`;
  });

  // Second pass for newly created duplicate sx
  content = content.replace(/sx=\{\{\s*(.*?)\s*\}\}\s*sx=\{\{\s*(.*?)\s*\}\}/g, 'sx={{ $1, $2 }}');

  // Fix Grid item component="div"
  content = content.replace(/<Grid([^>]*?)\scomponent=\"div\"([^>]*?)>/g, '<Grid$1$2>');
  content = content.replace(/<Grid([^>]*?)\scomponent=\'div\'([^>]*?)>/g, '<Grid$1$2>');

  // Layout.tsx
  if (file.includes('Layout.tsx')) {
    content = content.replace(/<ListItemText([^>]*?)primaryTypographyProps=\{\{([^>]*?)\}\}(.*?)>/g, (match, p1, p2, p3) => {
      // Note: this is a bit dangerous with regex, let's just do an exact replace
      return match;
    });
    // better to fix Layout.tsx manually
  }

  // PermitToWork.tsx has <Box fontWeight={800}>
  content = content.replace(/<Box([^>]*?)\sfontWeight=\{([0-9]+)\}([^>]*?)>/g, (match, p1, p2, p3) => {
    return `<Box${p1}${p3} sx={{ fontWeight: ${p2} }}>`;
  });

  fs.writeFileSync(file, content);
});
console.log('Fixed syntax issues');
