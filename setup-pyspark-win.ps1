param(
    [string]$EnvPath = "C:\conda-envs\pyspark-3.5.1",
    [string]$SparkConfRelPath = "spark-conf",
    [string]$HadoopRelPath = "hadoop"
)

Write-Host "Configuring PySpark environment for Windows..." -ForegroundColor Cyan

# ------------------------------------------------------------
# 0. Locate repository root
# ------------------------------------------------------------

function Find-RepoRoot {
    param([string]$StartDir)

    $dir = Resolve-Path $StartDir

    while ($null -ne $dir) {
        if (Test-Path (Join-Path $dir ".git")) {
            return $dir.Path
        }

        $parent = Split-Path $dir -Parent

        if ($parent -eq $dir) {
            break
        }

        $dir = $parent
    }

    # Fallback: use the directory where this script lives.
    return (Resolve-Path $StartDir).Path
}

$ScriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    (Get-Location).Path
}

$RepoRoot = Find-RepoRoot $ScriptDir

# ------------------------------------------------------------
# 1. Resolve paths
# ------------------------------------------------------------

if (-not (Test-Path $EnvPath)) {
    Write-Host "ERROR: Conda environment path does not exist:" -ForegroundColor Red
    Write-Host "  $EnvPath"
    exit 1
}

$EnvPath = (Resolve-Path $EnvPath).Path

$PythonExe = Join-Path $EnvPath "python.exe"
$JavaHome = Join-Path $EnvPath "Library"
$JavaExe = Join-Path $JavaHome "bin\java.exe"

$SparkHome = Join-Path $EnvPath "Lib\site-packages\pyspark"
$SparkSubmit = Join-Path $SparkHome "bin\spark-submit.cmd"
$SparkJars = Join-Path $SparkHome "jars"

$SparkConfDir = Join-Path $RepoRoot $SparkConfRelPath
$SparkDefaults = Join-Path $SparkConfDir "spark-defaults.conf"

$HadoopHome = Join-Path $RepoRoot $HadoopRelPath
$HadoopBin = Join-Path $HadoopHome "bin"
$WinutilsExe = Join-Path $HadoopBin "winutils.exe"

$TempDir = "C:\tmp"
$SparkTmpDir = "C:\spark-tmp"

# ------------------------------------------------------------
# 2. Validate required files/directories
# ------------------------------------------------------------

if (-not (Test-Path $PythonExe)) {
    Write-Host "ERROR: Python executable not found:" -ForegroundColor Red
    Write-Host "  $PythonExe"
    exit 1
}

if (-not (Test-Path $JavaExe)) {
    Write-Host "ERROR: Java executable not found:" -ForegroundColor Red
    Write-Host "  $JavaExe"
    exit 1
}

if (-not (Test-Path $SparkHome)) {
    Write-Host "ERROR: PySpark package directory not found:" -ForegroundColor Red
    Write-Host "  $SparkHome"
    Write-Host "Try:"
    Write-Host "  python -m pip install pyspark==3.5.1"
    exit 1
}

if (-not (Test-Path $SparkJars)) {
    Write-Host "ERROR: Spark jars directory not found:" -ForegroundColor Red
    Write-Host "  $SparkJars"
    Write-Host "Try:"
    Write-Host "  python -m pip install --force-reinstall pyspark==3.5.1"
    exit 1
}

if (-not (Test-Path $SparkSubmit)) {
    Write-Host "ERROR: spark-submit.cmd not found:" -ForegroundColor Red
    Write-Host "  $SparkSubmit"
    exit 1
}

if (-not (Test-Path $WinutilsExe)) {
    Write-Host "ERROR: winutils.exe not found:" -ForegroundColor Red
    Write-Host "Expected:"
    Write-Host "  $WinutilsExe"
    Write-Host ""
    Write-Host "Recommended repo layout:"
    Write-Host "  hadoop\bin\winutils.exe"
    exit 1
}

# ------------------------------------------------------------
# 3. Create temp and config directories
# ------------------------------------------------------------

New-Item -ItemType Directory -Force $TempDir | Out-Null
New-Item -ItemType Directory -Force $SparkTmpDir | Out-Null
New-Item -ItemType Directory -Force $SparkConfDir | Out-Null

# ------------------------------------------------------------
# 4. Generate spark-defaults.conf
# ------------------------------------------------------------

# Spark config files should use forward slashes on Windows.
# Backslashes may be interpreted as escape characters.

$PythonExeConf = $PythonExe -replace "\\", "/"
$TempDirConf = $TempDir -replace "\\", "/"
$SparkTmpDirConf = $SparkTmpDir -replace "\\", "/"
$HadoopHomeConf = $HadoopHome -replace "\\", "/"

@"
spark.local.dir $SparkTmpDirConf
spark.driver.extraJavaOptions -Djava.io.tmpdir=$TempDirConf -Dhadoop.home.dir=$HadoopHomeConf
spark.executor.extraJavaOptions -Djava.io.tmpdir=$TempDirConf -Dhadoop.home.dir=$HadoopHomeConf
spark.pyspark.python $PythonExeConf
spark.pyspark.driver.python $PythonExeConf
"@ | Set-Content -Path $SparkDefaults -Encoding ASCII

# ------------------------------------------------------------
# 5. Set environment variables for current PowerShell session
# ------------------------------------------------------------

$env:CONDA_PREFIX = $EnvPath

$env:JAVA_HOME = $JavaHome
$env:SPARK_HOME = $SparkHome
$env:SPARK_CONF_DIR = $SparkConfDir
$env:HADOOP_HOME = $HadoopHome

$env:PYSPARK_PYTHON = $PythonExe
$env:PYSPARK_DRIVER_PYTHON = $PythonExe

$env:TEMP = $TempDir
$env:TMP = $TempDir
$env:SPARK_LOCAL_DIRS = $SparkTmpDir

$env:Path = "$SparkHome\bin;$JavaHome\bin;$HadoopBin;$EnvPath;$EnvPath\Scripts;$env:Path"

# ------------------------------------------------------------
# 6. Print summary
# ------------------------------------------------------------

Write-Host ""
Write-Host "PySpark environment configured successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Repository root:      $RepoRoot"
Write-Host "Python:               $PythonExe"
Write-Host "JAVA_HOME:            $env:JAVA_HOME"
Write-Host "SPARK_HOME:           $env:SPARK_HOME"
Write-Host "SPARK_CONF_DIR:       $env:SPARK_CONF_DIR"
Write-Host "HADOOP_HOME:          $env:HADOOP_HOME"
Write-Host "winutils.exe:         $WinutilsExe"
Write-Host "TEMP:                 $env:TEMP"
Write-Host "TMP:                  $env:TMP"
Write-Host "SPARK_LOCAL_DIRS:     $env:SPARK_LOCAL_DIRS"
Write-Host ""

Write-Host "Checks:" -ForegroundColor Cyan
Write-Host "  Spark jars exist:        " (Test-Path $SparkJars)
Write-Host "  spark-submit exists:     " (Test-Path $SparkSubmit)
Write-Host "  spark-defaults.conf:     " (Test-Path $SparkDefaults)
Write-Host "  winutils.exe exists:     " (Test-Path $WinutilsExe)
Write-Host ""

Write-Host "Generated spark-defaults.conf:" -ForegroundColor Cyan
Get-Content $SparkDefaults
Write-Host ""

Write-Host "Environment is ready." -ForegroundColor Green
Write-Host ""
Write-Host "Now run one of the following manually:"
Write-Host "  python verify_spark.py"
Write-Host "  spark-submit --master `"local[*]`" verify_spark.py"