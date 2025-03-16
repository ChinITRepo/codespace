#!/usr/bin/env node
/**
 * Infrastructure Automation Framework - Universal Setup Script
 * 
 * This script works on Windows, Linux, and macOS using Node.js.
 * It detects the operating system and runs the appropriate commands.
 */

const os = require('os');
const fs = require('fs');
const path = require('path');
const { execSync, spawn } = require('child_process');

// Detect operating system
const platform = os.platform();
const isWindows = platform === 'win32';
const isMac = platform === 'darwin';
const isLinux = platform === 'linux';

// Get script directory
const scriptDir = __dirname;

// Parse command line arguments
const args = process.argv.slice(2);
let options = {
  mode: 'dev',
  cloud: 'all',
  force: false,
  skipDeps: false,
  envFile: '.env',
  setupSSH: false,
  installPwsh: false
};

// Process command line arguments
for (let i = 0; i < args.length; i++) {
  const arg = args[i].toLowerCase();
  
  if (arg === '--mode' && i + 1 < args.length) {
    const mode = args[++i].toLowerCase();
    if (mode === 'dev' || mode === 'prod') {
      options.mode = mode;
    } else {
      console.error('Error: Mode must be "dev" or "prod"');
      process.exit(1);
    }
  } else if (arg === '--cloud' && i + 1 < args.length) {
    const cloud = args[++i].toLowerCase();
    if (['aws', 'azure', 'gcp', 'all', 'none'].includes(cloud)) {
      options.cloud = cloud;
    } else {
      console.error('Error: Cloud must be "aws", "azure", "gcp", "all", or "none"');
      process.exit(1);
    }
  } else if (arg === '--force') {
    options.force = true;
  } else if (arg === '--skip-deps') {
    options.skipDeps = true;
  } else if (arg === '--env-file' && i + 1 < args.length) {
    options.envFile = args[++i];
  } else if (arg === '--setup-ssh') {
    options.setupSSH = true;
  } else if (arg === '--install-pwsh') {
    options.installPwsh = true;
  } else if (arg === '--help') {
    printHelp();
    process.exit(0);
  } else {
    console.error(`Unknown option: ${arg}`);
    printHelp();
    process.exit(1);
  }
}

// Print startup banner
console.log('\n-----------------------------------------');
console.log('Infrastructure Automation Framework Setup');
console.log('-----------------------------------------\n');

// Main execution
main().catch(error => {
  console.error(`Error: ${error.message}`);
  process.exit(1);
});

// Print help message
function printHelp() {
  console.log('Infrastructure Automation Framework - Universal Setup Script');
  console.log('');
  console.log('Usage: node setup.js [options]');
  console.log('');
  console.log('Options:');
  console.log('  --mode <dev|prod>          Setup mode (default: dev)');
  console.log('  --cloud <aws|azure|gcp|all|none>  Cloud providers to configure (default: all)');
  console.log('  --force                    Force reinstallation of components');
  console.log('  --skip-deps                Skip dependency installation');
  console.log('  --env-file <file>          Environment file path (default: .env)');
  console.log('  --setup-ssh                Configure SSH keys and settings');
  console.log('  --install-pwsh             Install PowerShell Core (pwsh)');
  console.log('  --help                     Show this help message');
}

// Check if a command is available
function isCommandAvailable(command) {
  try {
    if (isWindows) {
      execSync(`where ${command}`, { stdio: 'ignore' });
    } else {
      execSync(`which ${command}`, { stdio: 'ignore' });
    }
    return true;
  } catch (error) {
    return false;
  }
}

// Execute the appropriate platform-specific setup script
async function main() {
  console.log(`Detected ${getPlatformName()} operating system`);
  
  // Check if Node.js is the only requirement and we can execute setup directly
  if (isCommandAvailable('python3') || isCommandAvailable('python')) {
    console.log('Python detected, proceeding with setup...');
    
    // Convert options to command line arguments for the native scripts
    const setupArgs = [];
    
    if (options.mode) setupArgs.push(isWindows ? `-Mode ${options.mode}` : `--mode ${options.mode}`);
    if (options.cloud) setupArgs.push(isWindows ? `-Cloud ${options.cloud}` : `--cloud ${options.cloud}`);
    if (options.force) setupArgs.push(isWindows ? '-Force' : '--force');
    if (options.skipDeps) setupArgs.push(isWindows ? '-SkipDeps' : '--skip-deps');
    if (options.envFile) setupArgs.push(isWindows ? `-EnvFile ${options.envFile}` : `--env-file ${options.envFile}`);
    if (options.setupSSH) setupArgs.push(isWindows ? '-SetupSSH' : '--setup-ssh');
    if (options.installPwsh) setupArgs.push(isWindows ? '-InstallPwsh' : '--install-pwsh');
    
    if (isWindows) {
      console.log('Running Windows setup script...');
      runCommand('powershell', ['-ExecutionPolicy', 'Bypass', '-File', path.join(scriptDir, 'setup.ps1'), ...setupArgs]);
    } else {
      console.log('Running Unix setup script...');
      // Make sure the script is executable
      try {
        fs.chmodSync(path.join(scriptDir, 'setup.sh'), '755');
      } catch (error) {
        console.warn(`Warning: Could not make setup.sh executable: ${error.message}`);
      }
      runCommand(path.join(scriptDir, 'setup.sh'), setupArgs);
    }
  } else {
    console.log('Python not detected. Installing required dependencies...');
    
    // Here we could implement platform-specific code to install Python
    if (isWindows) {
      console.log('Please install Python 3.8 or higher from https://www.python.org/downloads/');
    } else if (isMac) {
      console.log('Installing Python using Homebrew...');
      if (!isCommandAvailable('brew')) {
        console.log('Homebrew not found. Installing...');
        runCommand('/bin/bash', ['-c', '$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)']);
      }
      runCommand('brew', ['install', 'python3']);
    } else if (isLinux) {
      console.log('Installing Python...');
      if (isCommandAvailable('apt-get')) {
        runCommand('sudo', ['apt-get', 'update']);
        runCommand('sudo', ['apt-get', 'install', '-y', 'python3', 'python3-pip']);
      } else if (isCommandAvailable('yum')) {
        runCommand('sudo', ['yum', 'install', '-y', 'python3', 'python3-pip']);
      } else {
        console.error('Unsupported Linux distribution. Please install Python 3.8 or higher manually.');
        process.exit(1);
      }
    }
    
    // After installing Python, rerun the script
    console.log('Dependencies installed. Please run the setup script again.');
  }
}

// Get user-friendly platform name
function getPlatformName() {
  if (isWindows) return 'Windows';
  if (isMac) return 'macOS';
  if (isLinux) return 'Linux';
  return 'Unknown';
}

// Run a command and handle the output
function runCommand(command, args = []) {
  console.log(`Running: ${command} ${args.join(' ')}`);
  
  const childProcess = spawn(command, args, {
    stdio: 'inherit',
    shell: isWindows
  });
  
  return new Promise((resolve, reject) => {
    childProcess.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Command failed with exit code ${code}`));
      }
    });
    
    childProcess.on('error', (error) => {
      reject(new Error(`Failed to start command: ${error.message}`));
    });
  });
} 