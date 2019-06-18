#!/usr/bin/env bash
#
# See https://docs.rstudio.com/connect/admin/python.html for details.
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install requirements
echo "Installing Requirements..."
sudo yum-builddep python python-libs
sudo yum install libffi-devel zlib zlib-devel

BASE_INSTALL_DIR="/opt/Python"
VERSIONS="3.7.3,3.6.8,3.5.7,2.7.16"

for VERSION in ${VERSIONS//,/ }
do
  MAJOR="${VERSION:0:1}"
  INSTALL_DIR="${BASE_INSTALL_DIR}/${VERSION}"

  if [ -d "${INSTALL_DIR}" ]
  then
    echo "Version: ${VERSION} already installed. Skipping."
  else
    echo "Installing Python: ${VERSION}"

    wget https://www.python.org/ftp/python/${VERSION}/Python-${VERSION}.tgz
    tar -xzvf Python-${VERSION}.tgz
    cd Python-${VERSION}

    ./configure \
      --prefix=${INSTALL_DIR} \
      --enable-shared \
      --enable-ipv6 \
      LDFLAGS=-Wl,-rpath=${INSTALL_DIR}/lib,--disable-new-dtags
    make

    # Install Python
    sudo make install

    ${INSTALL_DIR}/bin/python${MAJOR} --version
    if [ $? != 0 ]
    then
      echo "INSTALL FAILED: Python ${VERSION}"
    fi

    # Install pip
    wget https://bootstrap.pypa.io/get-pip.py
    sudo ${INSTALL_DIR}/bin/python${MAJOR} get-pip.py
    if [ $? != 0 ]
    then
      echo "INSTALL FAILED: pip"
    fi

    # Install virtualenv
    sudo ${INSTALL_DIR}/bin/pip install virtualenv
    if [ $? != 0 ]
    then
      echo "INSTALL FAILED: virtualenv"
    fi

    # Install setuptools
    sudo ${INSTALL_DIR}/bin/pip install setuptools
    if [ $? != 0 ]
    then
      echo "INSTALL FAILED: setuptools"
    fi

  fi

  cd "${SCRIPT_DIR}"
done

echo ""
echo "Installed Python Versions:"
ls ${BASE_INSTALL_DIR}

echo ""
echo "Add the following to RStudio Connect Server Configuration (/etc/rstudio-connect/rstudio-connect.gcfg)"
echo ""
echo "[Python]"
echo "Enabled = true"
for VERSION in `ls "${BASE_INSTALL_DIR}"`
do
  MAJOR="${VERSION:0:1}"
  echo "Executable = ${BASE_INSTALL_DIR}/${VERSION}/bin/python${MAJOR}"
done
echo ""
