#!/usr/bin/env bash

# Configure PySpark environment for macOS.
#
# Usage:
#   conda activate pyspark-3.5.1
#   source setup-pyspark-mac.sh
#
# Optional:
#   source setup-pyspark-mac.sh /path/to/conda/env

set -u

ENV_PATH="${1:-${CONDA_PREFIX:-}}"
SPARK_CONF_REL_PATH="spark-conf"

echo "Configuring PySpark environment for macOS..."

# ------------------------------------------------------------
# 0. Validate Conda environment
# ------------------------------------------------------------

if [ -z "$ENV_PATH" ]; then
    echo "ERROR: No Conda environment detected."
    echo "Activate the environment first:"
    echo "  conda activate pyspark-3.5.1"
    echo ""
    echo "Or pass the environment path explicitly:"
    echo "  source setup-pyspark-mac.sh /path/to/conda/env"
    return 1 2>/dev/null || exit 1
fi

ENV_PATH="$(cd "$ENV_PATH" && pwd)"

PYTHON_EXE="$ENV_PATH/bin/python"
JAVA_EXE="$ENV_PATH/bin/java"

if [ ! -x "$PYTHON_EXE" ]; then
    echo "ERROR: Python executable not found:"
    echo "  $PYTHON_EXE"
    return 1 2>/dev/null || exit 1
fi

if [ ! -x "$JAVA_EXE" ]; then
    echo "ERROR: Java executable not found:"
    echo "  $JAVA_EXE"
    echo ""
    echo "Make sure openjdk is installed in the Conda environment."
    return 1 2>/dev/null || exit 1
fi

# ------------------------------------------------------------
# 1. Locate repository root
# ------------------------------------------------------------

find_repo_root() {
    local dir="$1"

    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done

    # Fallback: current directory
    pwd
}

# When sourced, $0 may be the shell name, so use current working directory.
# Recommendation: run this from somewhere inside the repo.
REPO_ROOT="$(find_repo_root "$(pwd)")"

SPARK_CONF_DIR="$REPO_ROOT/$SPARK_CONF_REL_PATH"
SPARK_DEFAULTS="$SPARK_CONF_DIR/spark-defaults.conf"

# ------------------------------------------------------------
# 2. Locate pip-installed PySpark
# ------------------------------------------------------------

SPARK_HOME="$("$PYTHON_EXE" - <<'PY'
import pathlib
import pyspark
print(pathlib.Path(pyspark.__file__).resolve().parent)
PY
)"

if [ -z "$SPARK_HOME" ] || [ ! -d "$SPARK_HOME" ]; then
    echo "ERROR: Could not locate PySpark package directory."
    echo "Try:"
    echo "  python -m pip install pyspark==3.5.1"
    return 1 2>/dev/null || exit 1
fi

SPARK_JARS="$SPARK_HOME/jars"
SPARK_SUBMIT="$SPARK_HOME/bin/spark-submit"

if [ ! -d "$SPARK_JARS" ]; then
    echo "ERROR: Spark jars directory not found:"
    echo "  $SPARK_JARS"
    echo ""
    echo "Try:"
    echo "  python -m pip install --force-reinstall pyspark==3.5.1"
    return 1 2>/dev/null || exit 1
fi

if [ ! -x "$SPARK_SUBMIT" ]; then
    echo "ERROR: spark-submit not found:"
    echo "  $SPARK_SUBMIT"
    return 1 2>/dev/null || exit 1
fi

# ------------------------------------------------------------
# 3. Create temp and Spark config directories
# ------------------------------------------------------------

SPARK_TMP_DIR="/tmp/spark-tmp-${USER:-user}"

mkdir -p "$SPARK_TMP_DIR"
mkdir -p "$SPARK_CONF_DIR"

# ------------------------------------------------------------
# 4. Generate spark-defaults.conf
# ------------------------------------------------------------

cat > "$SPARK_DEFAULTS" <<EOF
spark.local.dir $SPARK_TMP_DIR
spark.driver.extraJavaOptions -Djava.io.tmpdir=/tmp
spark.executor.extraJavaOptions -Djava.io.tmpdir=/tmp
spark.pyspark.python $PYTHON_EXE
spark.pyspark.driver.python $PYTHON_EXE
EOF

# ------------------------------------------------------------
# 5. Export environment variables for current shell session
# ------------------------------------------------------------

# Conda OpenJDK on macOS provides:
#   $CONDA_PREFIX/bin/java
# so JAVA_HOME can point to the Conda environment root.
export JAVA_HOME="$ENV_PATH"
export SPARK_HOME="$SPARK_HOME"
export SPARK_CONF_DIR="$SPARK_CONF_DIR"

export PYSPARK_PYTHON="$PYTHON_EXE"
export PYSPARK_DRIVER_PYTHON="$PYTHON_EXE"

export TMPDIR="/tmp"
export SPARK_LOCAL_DIRS="$SPARK_TMP_DIR"

export PATH="$SPARK_HOME/bin:$JAVA_HOME/bin:$ENV_PATH/bin:$PATH"

# ------------------------------------------------------------
# 6. Print summary
# ------------------------------------------------------------

echo ""
echo "PySpark environment configured successfully."
echo ""
echo "Repository root:      $REPO_ROOT"
echo "Python:               $PYTHON_EXE"
echo "JAVA_HOME:            $JAVA_HOME"
echo "SPARK_HOME:           $SPARK_HOME"
echo "SPARK_CONF_DIR:       $SPARK_CONF_DIR"
echo "TMPDIR:               $TMPDIR"
echo "SPARK_LOCAL_DIRS:     $SPARK_LOCAL_DIRS"
echo ""

echo "Checks:"
echo "  Spark jars exist:        $([ -d "$SPARK_JARS" ] && echo true || echo false)"
echo "  spark-submit exists:     $([ -x "$SPARK_SUBMIT" ] && echo true || echo false)"
echo "  spark-defaults.conf:     $([ -f "$SPARK_DEFAULTS" ] && echo true || echo false)"
echo ""

echo "Generated spark-defaults.conf:"
cat "$SPARK_DEFAULTS"
echo ""

echo "Environment is ready."
echo ""
echo "Now run one of the following manually:"
echo "  python verify_spark.py"
echo "  spark-submit --master \"local[*]\" verify_spark.py"