/**
 * Infrastructure Automation Framework - Universal Setup Program
 * 
 * This C program detects the operating system and launches
 * the appropriate setup script. It can be compiled on any platform
 * to create a universal setup executable.
 * 
 * Compile with:
 * - Windows: gcc -o setup.exe setup.c
 * - Linux/macOS: gcc -o setup setup.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifdef _WIN32
    #include <windows.h>
    #define IS_WINDOWS 1
    #define IS_MACOS 0
    #define IS_LINUX 0
    #define PATH_SEPARATOR "\\"
#elif __APPLE__
    #include <unistd.h>
    #define IS_WINDOWS 0
    #define IS_MACOS 1
    #define IS_LINUX 0
    #define PATH_SEPARATOR "/"
#else
    #include <unistd.h>
    #define IS_WINDOWS 0
    #define IS_MACOS 0
    #define IS_LINUX 1
    #define PATH_SEPARATOR "/"
#endif

#define MAX_CMD_LEN 4096
#define MAX_PATH_LEN 1024
#define MAX_ARGS 32

// Function prototypes
void print_banner();
void log_message(const char* level, const char* message);
char* get_current_directory();
int run_command(const char* command);
int file_exists(const char* filename);
void build_command_with_args(char* cmd, int argc, char* argv[]);

int main(int argc, char* argv[]) {
    char command[MAX_CMD_LEN] = {0};
    char script_path[MAX_PATH_LEN] = {0};
    char current_dir[MAX_PATH_LEN] = {0};
    
    // Print banner
    print_banner();
    
    // Get current directory
    char* dir = get_current_directory();
    if (dir == NULL) {
        log_message("ERROR", "Failed to get current directory");
        return 1;
    }
    
    strncpy(current_dir, dir, MAX_PATH_LEN - 1);
    free(dir);
    
    log_message("INFO", "Starting universal setup program");
    
    if (IS_WINDOWS) {
        log_message("INFO", "Detected Windows operating system");
        
        // Construct the PowerShell script path
        snprintf(script_path, MAX_PATH_LEN, "%s%ssetup.ps1", current_dir, PATH_SEPARATOR);
        
        if (!file_exists(script_path)) {
            log_message("ERROR", "Windows setup script (setup.ps1) not found");
            return 1;
        }
        
        // Construct the PowerShell command with arguments
        snprintf(command, MAX_CMD_LEN, "powershell -ExecutionPolicy Bypass -File \"%s\"", script_path);
        build_command_with_args(command, argc, argv);
        
        log_message("INFO", "Running Windows setup script...");
    } else {
        // Unix-like system (Linux/macOS)
        if (IS_MACOS) {
            log_message("INFO", "Detected macOS operating system");
        } else {
            log_message("INFO", "Detected Linux operating system");
        }
        
        // Construct the shell script path
        snprintf(script_path, MAX_PATH_LEN, "%s%ssetup.sh", current_dir, PATH_SEPARATOR);
        
        if (!file_exists(script_path)) {
            log_message("ERROR", "Unix setup script (setup.sh) not found");
            return 1;
        }
        
        // Make sure the script is executable
        char chmod_cmd[MAX_CMD_LEN];
        snprintf(chmod_cmd, MAX_CMD_LEN, "chmod +x \"%s\"", script_path);
        run_command(chmod_cmd);
        
        // Construct the shell command with arguments
        snprintf(command, MAX_CMD_LEN, "\"%s\"", script_path);
        build_command_with_args(command, argc, argv);
        
        log_message("INFO", "Running Unix setup script...");
    }
    
    // Run the command
    int result = run_command(command);
    
    if (result == 0) {
        log_message("INFO", "Setup completed successfully");
        printf("\nSetup completed successfully!\n");
        printf("You can now start using the Infrastructure Automation Framework.\n");
        printf("Refer to the README.md for next steps.\n");
        return 0;
    } else {
        log_message("ERROR", "Setup failed");
        printf("\nSetup failed with exit code %d\n", result);
        printf("Check the logs directory for more information.\n");
        return 1;
    }
}

/**
 * Print the setup banner
 */
void print_banner() {
    printf("\n-----------------------------------------\n");
    printf("Infrastructure Automation Framework Setup\n");
    printf("-----------------------------------------\n\n");
}

/**
 * Log a message with timestamp to both console and log file
 */
void log_message(const char* level, const char* message) {
    time_t now;
    struct tm* timeinfo;
    char timestamp[20];
    
    time(&now);
    timeinfo = localtime(&now);
    
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", timeinfo);
    
    // Log to console
    printf("[%s] %s\n", level, message);
    
    // Create logs directory if it doesn't exist
    #ifdef _WIN32
        CreateDirectory("logs", NULL);
    #else
        mkdir("logs", 0755);
    #endif
    
    // Log to file
    char log_filename[MAX_PATH_LEN];
    
    #ifdef _WIN32
        snprintf(log_filename, MAX_PATH_LEN, "logs\\setup_%d%02d%02d.log", 
                timeinfo->tm_year + 1900, timeinfo->tm_mon + 1, timeinfo->tm_mday);
    #else
        snprintf(log_filename, MAX_PATH_LEN, "logs/setup_%d%02d%02d.log", 
                timeinfo->tm_year + 1900, timeinfo->tm_mon + 1, timeinfo->tm_mday);
    #endif
    
    FILE* log_file = fopen(log_filename, "a");
    if (log_file) {
        fprintf(log_file, "[%s] [%s] %s\n", timestamp, level, message);
        fclose(log_file);
    }
}

/**
 * Get the current directory
 */
char* get_current_directory() {
    char* buffer = NULL;
    
    #ifdef _WIN32
        DWORD size = GetCurrentDirectory(0, NULL);
        buffer = (char*)malloc(size * sizeof(char));
        if (buffer) {
            GetCurrentDirectory(size, buffer);
        }
    #else
        buffer = (char*)malloc(MAX_PATH_LEN * sizeof(char));
        if (buffer && getcwd(buffer, MAX_PATH_LEN) == NULL) {
            free(buffer);
            buffer = NULL;
        }
    #endif
    
    return buffer;
}

/**
 * Run a command and return the exit code
 */
int run_command(const char* command) {
    int result;
    
    log_message("INFO", command);
    
    #ifdef _WIN32
        result = system(command);
    #else
        result = system(command);
        if (WIFEXITED(result)) {
            result = WEXITSTATUS(result);
        }
    #endif
    
    return result;
}

/**
 * Check if a file exists
 */
int file_exists(const char* filename) {
    FILE* file = fopen(filename, "r");
    if (file) {
        fclose(file);
        return 1;
    }
    return 0;
}

/**
 * Build a command string with arguments
 */
void build_command_with_args(char* cmd, int argc, char* argv[]) {
    // Skip the program name (argv[0])
    for (int i = 1; i < argc && i < MAX_ARGS; i++) {
        // Add a space before each argument
        strcat(cmd, " ");
        
        // Check if the argument contains spaces and needs quotes
        if (strchr(argv[i], ' ') != NULL && argv[i][0] != '\"') {
            strcat(cmd, "\"");
            strcat(cmd, argv[i]);
            strcat(cmd, "\"");
        } else {
            strcat(cmd, argv[i]);
        }
    }
} 