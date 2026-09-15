FROM quay.io/jupyter/base-notebook:2026-07-28

ENV DOCKER_IMAGE_NAME='gnasello/slicer-env-jupyter' \
    DOCKER_IMAGE_DESCRIPTION='Slicer environment with Jupyter Notebook and JupyterLab' \
    DOCKER_IMAGE_URL='https://github.com/gnasello/slicer-env-jupyter'
ENV VERSION='2026-09-15'

USER root

RUN apt-get -y -qq update \
 && apt-get -y -qq install \
        dbus-x11 \
        # xclip is added as jupyter-remote-desktop-proxy's tests requires it
        xclip \
        xfce4 \
        xfce4-panel \
        xfce4-session \
        xfce4-settings \
        xorg \
        xubuntu-icon-theme \
        fonts-dejavu \
        # QT dependency (for 3D Slicer)
        libxcb-cursor0 \ 
        libxcb-icccm4 \
        libxcb-keysyms1 \
        libxcb-xinerama0 \
        libxcb-xkb1 \
        libxkbcommon-x11-0 \
        libpcre2-16-0 \
        # extra useful packages for the user
        unzip \ 
        git \
        vim \
        xvfb \
        epiphany-browser \
    # Disable the automatic screenlock since the account password is unknown
 && apt-get -y -qq remove xfce4-screensaver \
    # chown $HOME to workaround that the xorg installation creates a
    # /home/jovyan/.cache directory owned by root
    # Create /opt/install to ensure it's writable by pip
 && mkdir -p /opt/install \
 && chown -R $NB_UID:$NB_GID $HOME /opt/install \
 && rm -rf /var/lib/apt/lists/*

# Install a VNC server, either TigerVNC (default) or TurboVNC
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        echo "Installing TigerVNC"; \
        apt-get -y -qq update; \
        apt-get -y -qq install \
            tigervnc-standalone-server \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    fi
ENV PATH=/opt/TurboVNC/bin:$PATH
RUN if [ "${vncserver}" = "turbovnc" ]; then \
        echo "Installing TurboVNC"; \
        # Install instructions from https://turbovnc.org/Downloads/YUM
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | \
        gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg; \
        wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list; \
        apt-get -y -qq update; \
        apt-get -y -qq install \
            turbovnc \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    fi

USER $NB_USER

# Install the environment first, and then install the package separately for faster rebuilds
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp
RUN . /opt/conda/bin/activate && \
    mamba env update --quiet  --yes --file /tmp/environment.yml

COPY --chown=$NB_UID:$NB_GID . /opt/install
RUN . /opt/conda/bin/activate && \
    mamba install -y -q "nodejs>=24" && \
    pip install /opt/install

# Install 3D Slicer 5.12.4
RUN SLICER_URL="https://download.slicer.org/bitstream/6aa1beb7ce9de556d3010204" && \
  wget -O Slicer.tar.gz $SLICER_URL && \
  tar xfz Slicer.tar.gz && \
  rm Slicer.tar.gz && \
  mv /home/jovyan/Slicer* /home/jovyan/slicer

COPY --chown=jovyan:users install_SlicerExtensions.py /home/jovyan/slicer/

# add requests as helper package
RUN tini -g -- xvfb-run --auto-servernum /home/jovyan/slicer/Slicer --no-splash --no-main-window --python-script /home/jovyan/slicer/install_SlicerExtensions.py

COPY --chown=jovyan:users requirements.txt /home/jovyan/slicer/
RUN /home/jovyan/slicer/bin/PythonSlicer -m pip install --upgrade pip && \
    /home/jovyan/slicer/bin/PythonSlicer -m pip install -r /home/jovyan/slicer/requirements.txt


RUN tini -g -- xvfb-run --auto-servernum /home/jovyan/slicer/Slicer --no-splash --no-main-window -c 'slicer.modules.jupyterkernel.installInternalJupyterServer()'

# Install pyslicer
RUN git clone https://github.com/gabnasello/pyslicer.git
RUN /home/jovyan/slicer/bin/PythonSlicer -m pip install -e pyslicer/

COPY --chown=jovyan:users kernel.json /home/jovyan/.local/share/jupyter/kernels/slicer-5.12/kernel.json
#COPY --chown=jovyan:users kernel.json /home/jovyan/

# Add README file
# ADD README.ipynb /home/jovyan/
COPY --chown=jovyan:users README.ipynb /home/jovyan/

# Remove work directory
RUN rm -r /home/jovyan/work

# Required to run epiphany-browser from xcfe desktop
ENV WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1