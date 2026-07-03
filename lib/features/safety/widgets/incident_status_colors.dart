import 'package:flutter/material.dart';
import '../../../config/theme.dart';

Color getStatusColor(String status) {
  switch (status) {
    case 'Open':
      return XMTheme.statusOpen;
    case 'Investigating':
      return XMTheme.statusInProgress;
    case 'Resolved':
      return XMTheme.statusResolved;
    case 'Closed':
      return XMTheme.statusClosed;
    default:
      return XMTheme.statusDraft;
  }
}

Color getSevColor(String severity) {
  switch (severity) {
    case 'Critical':
      return XMTheme.severityCritical;
    case 'Major':
      return XMTheme.severityMajor;
    case 'Moderate':
      return XMTheme.severityModerate;
    case 'Minor':
      return XMTheme.severityMinor;
    default:
      return XMTheme.severityNegligible;
  }
}
