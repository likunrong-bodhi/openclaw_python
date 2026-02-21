@echo off
:: BEGIN config
REM set MAIN_COMPOSE_FILE to the name of your main docker compose file. 
REM This is used to check if the Docker image already exists and to bring down any existing containers before starting new ones.
set "MAIN_COMPOSE_FILE=docker-compose_all-in-one.yml"
REM the following environment variables are used by the docker compose file to set up volume mounts and port mappings. You can change them if needed, but make sure they match the values in your docker compose file.
set "OPENCLAW_DATA_DIR=%cd%\_openclaw\data"
set "OPENCLAW_WORKSPACE_DIR=%cd%\_openclaw\workspace"
set "OPENCLAW_PRIMARY_PORT=18789"
set "OPENCLAW_SECONDARY_PORT=18790"
:: END config

:: BEGIN command line argument parsing
if "%~1"=="" (
    set "OPENCLAW_MODE=rebuild"
    echo No mode specified. Defaulting to "rebuild" mode.
) else if "%~1"=="build" (
    :: build is an alias of rebuild
    set "OPENCLAW_MODE=rebuild"
) else if "%~1"=="restart" (
    :: restart is an alias of reset
    set "OPENCLAW_MODE=reset"
) else if "%~1"=="openclaw" (
    :: claw is an alias of cli
    set "OPENCLAW_MODE=cli"
) else (
    set "OPENCLAW_MODE=%~1"
)
if "%~2"=="" (
    set "CLI_COMMAND=onboard"
) else (
    set "CLI_COMMAND=%~2"
)
:: END command line argument parsing

if "%OPENCLAW_MODE%"=="help" (
    echo Usage^: %~nx0 ^[mode^] ^[cli_command^]
    echo.
    echo Modes^:
    echo   rebuild|build ^(default^)^: Build the Docker image and start the container. If the container already exists, it will be removed and recreated.
    echo   reset|restart^: Start the container without rebuilding the image. If the container already exists, it will be removed and recreated.
    echo   cli^: Run a command in the OpenClaw CLI container. The command is specified by the second parameter ^(default^: "onboard"^).
    echo   shell^: Open a bash shell in the OpenClaw gateway container.
    echo   config^: Output the Docker compose configuration after processing all environment variables and compose files.
    exit /b 0
)

:: if MAIN_COMPOSE_FILE is not empty, set DOCKER_COMPOSE_FILE to include it
if not "%MAIN_COMPOSE_FILE%"=="" (
    set "DOCKER_COMPOSE_FILE=-f %MAIN_COMPOSE_FILE%"
) else (
    set "DOCKER_COMPOSE_FILE="
)
REM If you need multiple compose files, you can set DOCKER_COMPOSE_FILE to include all of them, e.g.:
::set "DOCKER_COMPOSE_FILE=%DOCKER_COMPOSE_FILE% -f openclaw-python:latest"

:: ensure _openclaw/data and _openclaw/workspace directories exist
if not exist "%OPENCLAW_DATA_DIR%" (
    mkdir "%OPENCLAW_DATA_DIR%"
)
if not exist "%OPENCLAW_WORKSPACE_DIR%" (
    mkdir "%OPENCLAW_WORKSPACE_DIR%"
)

:: check if Docker is running by executing a simple Docker command
docker ps >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo !!!!!
    echo You need to start Docker Desktop before running this script.
    echo !!!!!
    exit /b 1
)

:: check if the Docker image for OpenClaw Python already exists
docker compose ls | findstr %MAIN_COMPOSE_FILE% >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Building the Docker image for OpenClaw Python...
    docker compose %DOCKER_COMPOSE_FILE% build --no-cache
    docker compose %DOCKER_COMPOSE_FILE% up -d

    echo Every things is set up. It may take a few seconds for the OpenClaw CLI to be ready. Please wait...
    :: output some usage instructions
    echo RUN "%~nx0 cli onboard"
    echo to start the OpenClaw CLI and onboard the gateway.

    echo RUN "%~nx0 shell"
    echo to open a bash shell in the OpenClaw container.
    exit /b 0
) else (
    if "%OPENCLAW_MODE%"=="rebuild" (
        echo Rebuilding the Docker image for OpenClaw Python...
        docker compose %DOCKER_COMPOSE_FILE% down
        docker compose %DOCKER_COMPOSE_FILE% build --no-cache
        docker compose %DOCKER_COMPOSE_FILE% up -d

        echo Every things is set up. It may take a few seconds for the OpenClaw CLI to be ready. Please wait...
        exit /b 0
    ) else if "%OPENCLAW_MODE%"=="reset" (
        echo Resetting the Docker image for OpenClaw Python...
        docker compose %DOCKER_COMPOSE_FILE% down
        docker compose %DOCKER_COMPOSE_FILE% up -d

        echo Every things is set up. It may take a few seconds for the OpenClaw CLI to be ready. Please wait...
        exit /b 0
    ) else if "%OPENCLAW_MODE%"=="cli" (
        echo RUN openclaw %CLI_COMMAND% %~3 %~4 %~5 %~6 %~7 %~8 %~9
        docker compose %DOCKER_COMPOSE_FILE% exec openclaw-gateway node /app/dist/index.js %CLI_COMMAND% %~3 %~4 %~5 %~6 %~7 %~8 %~9
        exit /b 0
    ) else if "%OPENCLAW_MODE%"=="shell" (
        echo Opening a bash shell in the OpenClaw container...
        docker compose %DOCKER_COMPOSE_FILE% exec openclaw-gateway /bin/bash
        exit /b 0
    ) else if "%OPENCLAW_MODE%"=="config" (
        echo Outputting the Docker compose configuration...
        docker compose %DOCKER_COMPOSE_FILE% config
        exit /b 0
    ) else (
        echo Invalid mode^: %OPENCLAW_MODE%
        echo Valid modes are^: rebuild, reset, cli, shell, config
        exit /b 1
    )
)
