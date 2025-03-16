/**
 * Infrastructure Automation Framework - Log Analyzer
 * 
 * This Lambda function analyzes log files in S3 for patterns of interest
 * and sends notifications for security events, errors, and anomalies.
 */

const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const sns = new AWS.SNS();

// Patterns to look for in logs
const CRITICAL_PATTERNS = [
  /ERROR|CRITICAL|FATAL|EXCEPTION/i,
  /DENIED|UNAUTHORIZED|FORBIDDEN/i,
  /ATTACK|VULNERABILITY|EXPLOIT/i,
  /MALICIOUS|MALWARE|VIRUS/i,
  /BRUTE\s*FORCE/i
];

// Anomaly detection thresholds
const thresholds = {
  errorRateThreshold: 0.05,      // 5% of lines contain errors
  authFailureThreshold: 10,      // 10 auth failures in one log file
  apiRateLimitThreshold: 5,      // 5 rate limit exceeded messages
  unusual404Threshold: 20,       // 20 unusual 404s to different paths
  sqlInjectionThreshold: 1,      // Any SQL injection attempt
  xssThreshold: 1                // Any XSS attempt
};

exports.handler = async (event) => {
  try {
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    // Get the S3 bucket and key from the event
    const bucket = event.Records[0].s3.bucket.name;
    const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
    
    console.log(`Processing log file: s3://${bucket}/${key}`);
    
    // Skip non-log files
    if (!key.endsWith('.log') && !key.includes('/logs/')) {
      console.log('Not a log file, skipping');
      return;
    }
    
    // Get the log file content
    const response = await s3.getObject({ Bucket: bucket, Key: key }).promise();
    const logContent = response.Body.toString('utf-8');
    const logLines = logContent.split('\n').filter(line => line.trim() !== '');
    
    // Initialize counters
    let criticalIssues = [];
    let errorCount = 0;
    let authFailures = 0;
    let rateLimitExceeded = 0;
    let unusual404s = new Set();
    let sqlInjectionAttempts = 0;
    let xssAttempts = 0;
    
    // Collect IP addresses for frequency analysis
    let ipFrequency = {};
    const ipRegex = /\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b/;
    
    // Analyze each line
    logLines.forEach((line, index) => {
      // Look for critical patterns
      CRITICAL_PATTERNS.forEach(pattern => {
        if (pattern.test(line)) {
          criticalIssues.push({
            lineNumber: index + 1,
            pattern: pattern.toString(),
            line: line.substring(0, 200) // Limit line length
          });
        }
      });
      
      // Count errors
      if (/error|exception|fail/i.test(line)) {
        errorCount++;
      }
      
      // Count authentication failures
      if (/authentication fail|login fail|auth fail|incorrect password/i.test(line)) {
        authFailures++;
      }
      
      // Count rate limit issues
      if (/rate limit|too many requests|throttl/i.test(line)) {
        rateLimitExceeded++;
      }
      
      // Track 404s to detect scanning
      const notFoundMatch = line.match(/GET\s+([^\s]+)\s+.*\s+404\s/);
      if (notFoundMatch && notFoundMatch[1]) {
        unusual404s.add(notFoundMatch[1]);
      }
      
      // Detect SQL injection attempts
      if (/SELECT.+FROM|UNION\s+SELECT|INSERT\s+INTO|UPDATE.+SET|DELETE\s+FROM/i.test(line)) {
        sqlInjectionAttempts++;
      }
      
      // Detect XSS attempts
      if (/<script>|javascript:|onerror=|onload=|onclick=/i.test(line)) {
        xssAttempts++;
      }
      
      // Collect IP addresses
      const ipMatch = line.match(ipRegex);
      if (ipMatch) {
        const ip = ipMatch[0];
        ipFrequency[ip] = (ipFrequency[ip] || 0) + 1;
      }
    });
    
    // Calculate error rate
    const errorRate = errorCount / logLines.length;
    
    // Check if any thresholds were exceeded
    let alerts = [];
    
    if (criticalIssues.length > 0) {
      alerts.push(`Found ${criticalIssues.length} critical issues in log file`);
    }
    
    if (errorRate > thresholds.errorRateThreshold) {
      alerts.push(`High error rate: ${(errorRate * 100).toFixed(2)}% (${errorCount}/${logLines.length})`);
    }
    
    if (authFailures > thresholds.authFailureThreshold) {
      alerts.push(`Excessive authentication failures: ${authFailures}`);
    }
    
    if (rateLimitExceeded > thresholds.apiRateLimitThreshold) {
      alerts.push(`API rate limits exceeded: ${rateLimitExceeded} times`);
    }
    
    if (unusual404s.size > thresholds.unusual404Threshold) {
      alerts.push(`Possible scanning activity: ${unusual404s.size} different 404 paths requested`);
    }
    
    if (sqlInjectionAttempts > thresholds.sqlInjectionThreshold) {
      alerts.push(`Possible SQL injection attempts: ${sqlInjectionAttempts}`);
    }
    
    if (xssAttempts > thresholds.xssThreshold) {
      alerts.push(`Possible XSS attempts: ${xssAttempts}`);
    }
    
    // Identify top IPs by frequency
    const topIPs = Object.entries(ipFrequency)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([ip, count]) => `${ip}: ${count} requests`);
    
    // Send notification if there are alerts
    if (alerts.length > 0) {
      const snsTopicArn = process.env.NOTIFICATION_SNS;
      const environment = process.env.ENVIRONMENT || 'unknown';
      
      const message = {
        subject: `[${environment.toUpperCase()}] Log Analysis Alert for ${key}`,
        message: `
Log File: s3://${bucket}/${key}
Timestamp: ${new Date().toISOString()}
Environment: ${environment}

ALERTS:
${alerts.map(a => `- ${a}`).join('\n')}

CRITICAL ISSUES:
${criticalIssues.slice(0, 10).map(i => `- Line ${i.lineNumber}: ${i.line}`).join('\n')}
${criticalIssues.length > 10 ? `... and ${criticalIssues.length - 10} more` : ''}

STATISTICS:
- Total log lines: ${logLines.length}
- Error rate: ${(errorRate * 100).toFixed(2)}%
- Auth failures: ${authFailures}
- Rate limit exceeded: ${rateLimitExceeded}
- Unique 404 paths: ${unusual404s.size}
- SQL injection attempts: ${sqlInjectionAttempts}
- XSS attempts: ${xssAttempts}

TOP IP ADDRESSES:
${topIPs.join('\n')}

This is an automated alert from the AWS Infrastructure Automation Framework.
        `.trim()
      };
      
      // Only send if SNS topic is configured
      if (snsTopicArn) {
        await sns.publish({
          TopicArn: snsTopicArn,
          Subject: message.subject,
          Message: message.message
        }).promise();
        
        console.log(`Alert sent to SNS topic: ${snsTopicArn}`);
      } else {
        console.log('No SNS topic configured, skipping notification');
        console.log('Alert details:', message);
      }
    } else {
      console.log('No alerts triggered for this log file');
    }
    
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Log file analysis completed',
        alerts: alerts.length,
        file: `s3://${bucket}/${key}`
      })
    };
  } catch (error) {
    console.error('Error analyzing log file:', error);
    throw error;
  }
}; 